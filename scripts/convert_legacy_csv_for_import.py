#!/usr/bin/env python3
"""
Convert cleaned legacy CSV exports into import-ready JSONL bundles for the new app.

The output intentionally keeps legacy user IDs so target user resolution can be
configured at import time (dev/prod may map legacy IDs differently).
"""

from __future__ import annotations

import argparse
import csv
import json
from collections import defaultdict
from dataclasses import dataclass
from datetime import UTC, datetime
from html import escape
from pathlib import Path
from typing import Any


VALID_TRIP_STATUSES = {"0_draft", "1_planned", "2_finished"}
TRANSFER_MODE_MAP = {
    "flight": "flight",
    "train": "train",
    "bus": "bus",
    "car": "car",
    "boat": "boat",
    "personal_car": "car",
    "taxi": "taxi",
}
GEONAMES_ID_REMAP = {
    # Legacy geonames for Ponta Delgada is absent in new geo seed.
    # Map to the existing Ponta Delgada geonames id in the new app DB.
    "3372783": "6941014",
}


@dataclass(frozen=True)
class WarningItem:
    code: str
    trip_id: str | None
    entity: str
    entity_id: str | None
    message: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert cleaned legacy CSVs to import-ready JSONL for the new Hamster Travel app."
    )
    parser.add_argument(
        "--input-dir",
        default="prod_backup/legacy_csv_clean",
        help="Directory with cleaned CSV files (default: prod_backup/legacy_csv_clean)",
    )
    parser.add_argument(
        "--output-dir",
        default="prod_backup/import_ready",
        help="Directory for converted output (default: prod_backup/import_ready)",
    )
    return parser.parse_args()


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def parse_int(value: str | None, default: int | None = None) -> int | None:
    if value is None:
        return default
    value = value.strip()
    if not value:
        return default
    try:
        return int(value)
    except ValueError:
        return default


def parse_bool(value: str | None, default: bool = False) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"t", "true", "1", "yes", "y"}


def clean_text(value: str | None) -> str:
    if value is None:
        return ""
    return value.strip()


def normalize_geonames_id(value: str | None) -> str:
    geonames_id = clean_text(value)
    if not geonames_id:
        return ""
    return GEONAMES_ID_REMAP.get(geonames_id, geonames_id)


def rich_text_from_plain(value: str | None) -> str | None:
    text = clean_text(value)
    if not text:
        return None

    # Rich editor stores HTML. Preserve paragraph breaks from legacy plain text.
    paragraphs = [p for p in text.replace("\r\n", "\n").split("\n\n") if p.strip()]
    if not paragraphs:
        return None

    html_paragraphs: list[str] = []
    for paragraph in paragraphs:
        safe = escape(paragraph.strip())
        safe = safe.replace("\n", "<br>")
        html_paragraphs.append(f"<p>{safe}</p>")

    return "".join(html_paragraphs)


def rich_text_link(url: str, label: str | None = None) -> str:
    safe_url = escape(url, quote=True)
    safe_label = escape(label or url)
    return f"<p><a href=\"{safe_url}\" target=\"_blank\" rel=\"noopener noreferrer\">{safe_label}</a></p>"


def build_food_note_html(trip_caterings: list[dict[str, str]]) -> str | None:
    entries: list[str] = []
    for row in sorted(trip_caterings, key=lambda c: parse_int(c.get("id"), 0)):
        name = clean_text(row.get("name"))
        description = clean_text(row.get("description"))
        if not description:
            # Skip legacy food rows that only provide a label without actual note content.
            continue

        block_lines: list[str] = []
        if name:
            block_lines.append(name)
        block_lines.append(description)
        if block_lines:
            entries.append("\n".join(block_lines))

    if not entries:
        return None

    return rich_text_from_plain("\n\n".join(entries))


def parse_timestamp_to_iso_utc(value: str | None) -> str | None:
    value = clean_text(value)
    if not value:
        return None
    try:
        dt = datetime.strptime(value, "%Y-%m-%d %H:%M:%S")
    except ValueError:
        return None
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def write_json(path: Path, payload: Any) -> None:
    with path.open("w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
        f.write("\n")


def write_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    with path.open("w", encoding="utf-8") as f:
        for row in rows:
            f.write(json.dumps(row, ensure_ascii=False))
            f.write("\n")


def build_day_index_map(
    days_rows: list[dict[str, str]],
) -> tuple[dict[str, int], dict[str, list[dict[str, str]]]]:
    by_trip: dict[str, list[dict[str, str]]] = defaultdict(list)
    for day in days_rows:
        by_trip[day["trip_id"]].append(day)

    day_index_by_day_id: dict[str, int] = {}
    ordered_days_by_trip: dict[str, list[dict[str, str]]] = {}

    for trip_id, trip_days in by_trip.items():
        sorted_days = sorted(
            trip_days,
            key=lambda d: (
                parse_int(d.get("index"), 10**9),
                d.get("date_when") or "9999-12-31",
                parse_int(d.get("id"), 10**9),
            ),
        )
        ordered_days_by_trip[trip_id] = sorted_days
        for idx, day in enumerate(sorted_days):
            day_index_by_day_id[day["id"]] = idx

    return day_index_by_day_id, ordered_days_by_trip


def main() -> None:
    args = parse_args()
    input_dir = Path(args.input_dir)
    output_dir = Path(args.output_dir)

    required = [
        "users.csv",
        "trips.csv",
        "users_trips.csv",
        "days.csv",
        "places.csv",
        "cities.csv",
        "activities.csv",
        "hotels.csv",
        "transfers.csv",
        "expenses.csv",
        "external_links.csv",
        "caterings.csv",
        "trip_invites.csv",
        "documents.csv",
    ]
    missing = [name for name in required if not (input_dir / name).exists()]
    if missing:
        raise FileNotFoundError(f"Missing required CSVs in {input_dir}: {', '.join(missing)}")

    users = read_csv(input_dir / "users.csv")
    trips = read_csv(input_dir / "trips.csv")
    users_trips = read_csv(input_dir / "users_trips.csv")
    days = read_csv(input_dir / "days.csv")
    places = read_csv(input_dir / "places.csv")
    cities = read_csv(input_dir / "cities.csv")
    activities = read_csv(input_dir / "activities.csv")
    hotels = read_csv(input_dir / "hotels.csv")
    transfers = read_csv(input_dir / "transfers.csv")
    expenses = read_csv(input_dir / "expenses.csv")
    external_links = read_csv(input_dir / "external_links.csv")
    caterings = read_csv(input_dir / "caterings.csv")
    trip_invites = read_csv(input_dir / "trip_invites.csv")
    documents = read_csv(input_dir / "documents.csv")

    ensure_dir(output_dir)

    warnings: list[WarningItem] = []

    city_geonames_by_legacy_id = {row["id"]: normalize_geonames_id(row.get("geonames_code")) for row in cities}
    user_ids = sorted({parse_int(u["id"]) for u in users if parse_int(u["id"]) is not None})
    user_currency = {row["id"]: clean_text(row.get("currency")) for row in users}

    day_index_by_day_id, ordered_days_by_trip = build_day_index_map(days)
    day_to_trip = {d["id"]: d["trip_id"] for d in days}

    users_trips_by_trip: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in users_trips:
        users_trips_by_trip[row["trip_id"]].append(row)

    places_by_day: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in places:
        places_by_day[row["day_id"]].append(row)

    activities_by_day: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in activities:
        activities_by_day[row["day_id"]].append(row)

    hotels_by_day: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in hotels:
        hotels_by_day[row["day_id"]].append(row)

    transfers_by_day: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in transfers:
        transfers_by_day[row["day_id"]].append(row)

    day_expenses_by_day: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in expenses:
        if clean_text(row.get("expendable_type")) == "Travels::Day":
            day_expenses_by_day[row["expendable_id"]].append(row)

    external_links_by_type_id: dict[tuple[str, str], list[dict[str, str]]] = defaultdict(list)
    for row in external_links:
        key = (clean_text(row.get("linkable_type")), clean_text(row.get("linkable_id")))
        external_links_by_type_id[key].append(row)

    caterings_by_trip: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in caterings:
        caterings_by_trip[row["trip_id"]].append(row)

    documents_by_trip: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in documents:
        documents_by_trip[row["trip_id"]].append(row)

    trip_invites_by_trip: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in trip_invites:
        trip_invites_by_trip[row["trip_id"]].append(row)

    trip_rows_out: list[dict[str, Any]] = []
    day_index_map_rows: list[dict[str, Any]] = []

    for trip in sorted(trips, key=lambda r: parse_int(r["id"], 0)):
        legacy_trip_id = trip["id"]
        trip_ref = f"legacy_trip_{legacy_trip_id}"
        author_legacy_user_id = parse_int(trip.get("author_user_id"))

        status = clean_text(trip.get("status_code")) or "1_planned"
        if status not in VALID_TRIP_STATUSES:
            warnings.append(
                WarningItem(
                    code="trip_invalid_status",
                    trip_id=legacy_trip_id,
                    entity="trip",
                    entity_id=legacy_trip_id,
                    message=f"Unknown status '{status}', fallback to 1_planned.",
                )
            )
            status = "1_planned"

        currency = clean_text(trip.get("currency"))
        if not currency and trip.get("author_user_id"):
            currency = clean_text(user_currency.get(trip["author_user_id"]))
        if not currency:
            currency = "EUR"
            warnings.append(
                WarningItem(
                    code="trip_missing_currency",
                    trip_id=legacy_trip_id,
                    entity="trip",
                    entity_id=legacy_trip_id,
                    message="Missing currency, fallback to EUR.",
                )
            )

        people_count = parse_int(trip.get("budget_for"), 1) or 1
        dates_unknown = parse_bool(trip.get("dates_unknown"), False)

        ordered_days = ordered_days_by_trip.get(legacy_trip_id, [])
        day_count = len(ordered_days)
        start_date = clean_text(trip.get("start_date")) or None
        end_date = clean_text(trip.get("end_date")) or None

        if not dates_unknown:
            if not start_date and ordered_days:
                start_date = clean_text(ordered_days[0].get("date_when")) or None
            if not end_date and ordered_days:
                end_date = clean_text(ordered_days[-1].get("date_when")) or None

        if dates_unknown:
            duration = parse_int(trip.get("planned_days_count"), day_count or 1) or 1
            start_date = None
            end_date = None
        else:
            duration = day_count if day_count > 0 else parse_int(trip.get("planned_days_count"), 1) or 1

        participant_ids = sorted(
            {
                parse_int(row.get("user_id"))
                for row in users_trips_by_trip.get(legacy_trip_id, [])
                if parse_int(row.get("user_id")) is not None
            }
        )

        # Destination conversion: preserve multiple cities per day.
        day_cities_geonames: dict[int, list[str]] = {}
        for day in ordered_days:
            day_id = day["id"]
            day_index = day_index_by_day_id[day_id]
            day_places = [p for p in places_by_day.get(day_id, []) if clean_text(p.get("city_id"))]
            if not day_places:
                continue
            day_places_sorted = sorted(day_places, key=lambda p: parse_int(p.get("id"), 10**9))
            geonames_for_day: list[str] = []
            seen_geonames: set[str] = set()

            for place in day_places_sorted:
                city_id = clean_text(place.get("city_id"))
                geonames_id = clean_text(city_geonames_by_legacy_id.get(city_id))
                if not geonames_id:
                    warnings.append(
                        WarningItem(
                            code="city_missing_geonames",
                            trip_id=legacy_trip_id,
                            entity="place",
                            entity_id=city_id,
                            message="Missing geonames_code for city_id in places.",
                        )
                    )
                    continue

                if geonames_id not in seen_geonames:
                    seen_geonames.add(geonames_id)
                    geonames_for_day.append(geonames_id)

            if geonames_for_day:
                day_cities_geonames[day_index] = geonames_for_day

        # Build destination ranges per city while allowing overlaps across cities on the same day.
        destinations: list[dict[str, Any]] = []
        open_ranges: dict[str, dict[str, Any]] = {}

        for day_index in range(day_count):
            current_geonames = set(day_cities_geonames.get(day_index, []))

            for geonames_id in list(open_ranges.keys()):
                if geonames_id in current_geonames:
                    open_ranges[geonames_id]["end_day"] = day_index
                else:
                    destinations.append(open_ranges.pop(geonames_id))

            for geonames_id in current_geonames:
                if geonames_id not in open_ranges:
                    open_ranges[geonames_id] = {
                        "city_geonames_id": geonames_id,
                        "start_day": day_index,
                        "end_day": day_index,
                    }

        destinations.extend(open_ranges.values())
        destinations.sort(key=lambda d: (d["start_day"], d["end_day"], d["city_geonames_id"]))

        # Activities
        activity_records: list[dict[str, Any]] = []
        for day in ordered_days:
            day_id = day["id"]
            day_index = day_index_by_day_id[day_id]
            for row in sorted(activities_by_day.get(day_id, []), key=lambda a: parse_int(a.get("id"), 0)):
                priority = parse_int(row.get("rating"), 2) or 2
                if priority < 1:
                    priority = 1
                if priority > 3:
                    priority = 3

                amount_cents = parse_int(row.get("amount_cents"), 0) or 0
                amount_currency = clean_text(row.get("amount_currency")) or currency
                expense = None
                if amount_cents > 0:
                    expense = {
                        "name": clean_text(row.get("name")) or "Activity expense",
                        "amount_cents": amount_cents,
                        "currency": amount_currency,
                    }

                activity_records.append(
                    {
                        "legacy_activity_id": parse_int(row.get("id")),
                        "day_index": day_index,
                        "name": clean_text(row.get("name")),
                        "priority": priority,
                        "link": clean_text(row.get("link_url")) or None,
                        "address": clean_text(row.get("address")) or None,
                        "description": rich_text_from_plain(row.get("comment")),
                        "rank_hint": parse_int(row.get("order_index"), 0) or 0,
                        "expense": expense,
                    }
                )

        # Accommodations (one per legacy hotel day row).
        accommodation_records: list[dict[str, Any]] = []
        for day in ordered_days:
            day_id = day["id"]
            day_index = day_index_by_day_id[day_id]
            for row in sorted(hotels_by_day.get(day_id, []), key=lambda h: parse_int(h.get("id"), 0)):
                hotel_id = clean_text(row.get("id"))
                links = external_links_by_type_id.get(("Travels::Hotel", hotel_id), [])
                link_url = clean_text(links[0].get("url")) if links else ""
                name = clean_text(row.get("name")) or "Legacy accommodation"

                amount_cents = parse_int(row.get("amount_cents"), 0) or 0
                amount_currency = clean_text(row.get("amount_currency")) or currency
                expense = None
                if amount_cents > 0:
                    expense = {
                        "name": name,
                        "amount_cents": amount_cents,
                        "currency": amount_currency,
                    }

                accommodation_records.append(
                    {
                        "legacy_hotel_id": parse_int(row.get("id")),
                        "name": name,
                        "link": link_url or None,
                        "address": None,
                        "note": rich_text_from_plain(row.get("comment")),
                        "start_day": day_index,
                        "end_day": day_index,
                        "expense": expense,
                    }
                )

        # Transfers
        transfer_records: list[dict[str, Any]] = []
        for day in ordered_days:
            day_id = day["id"]
            day_index = day_index_by_day_id[day_id]
            for row in sorted(transfers_by_day.get(day_id, []), key=lambda t: parse_int(t.get("id"), 0)):
                transfer_id = clean_text(row.get("id"))

                mode_raw = clean_text(row.get("type"))
                mode = TRANSFER_MODE_MAP.get(mode_raw)
                if mode is None:
                    mode = "car"
                    warnings.append(
                        WarningItem(
                            code="transfer_unknown_mode",
                            trip_id=legacy_trip_id,
                            entity="transfer",
                            entity_id=transfer_id,
                            message=f"Unknown transfer type '{mode_raw}', fallback to car.",
                        )
                    )

                from_city_id = clean_text(row.get("city_from_id"))
                to_city_id = clean_text(row.get("city_to_id"))
                from_geonames = clean_text(city_geonames_by_legacy_id.get(from_city_id))
                to_geonames = clean_text(city_geonames_by_legacy_id.get(to_city_id))
                if not from_geonames or not to_geonames:
                    warnings.append(
                        WarningItem(
                            code="transfer_missing_city",
                            trip_id=legacy_trip_id,
                            entity="transfer",
                            entity_id=transfer_id,
                            message="Missing departure/arrival city geonames mapping. Transfer skipped.",
                        )
                    )
                    continue

                dep_time = parse_timestamp_to_iso_utc(row.get("start_time"))
                arr_time = parse_timestamp_to_iso_utc(row.get("end_time"))
                if dep_time is None:
                    dep_time = "1970-01-01T00:00:00Z"
                    warnings.append(
                        WarningItem(
                            code="transfer_missing_departure_time",
                            trip_id=legacy_trip_id,
                            entity="transfer",
                            entity_id=transfer_id,
                            message="Missing/invalid departure time, fallback to 1970-01-01T00:00:00Z.",
                        )
                    )
                if arr_time is None:
                    arr_time = dep_time
                    warnings.append(
                        WarningItem(
                            code="transfer_missing_arrival_time",
                            trip_id=legacy_trip_id,
                            entity="transfer",
                            entity_id=transfer_id,
                            message="Missing/invalid arrival time, fallback to departure time.",
                        )
                    )

                amount_cents = parse_int(row.get("amount_cents"), 0) or 0
                amount_currency = clean_text(row.get("amount_currency")) or currency
                expense = None
                if amount_cents > 0:
                    expense = {
                        "name": clean_text(row.get("code")) or f"{mode.title()} transfer",
                        "amount_cents": amount_cents,
                        "currency": amount_currency,
                    }

                links = external_links_by_type_id.get(("Travels::Transfer", transfer_id), [])
                link_url = clean_text(links[0].get("url")) if links else clean_text(row.get("link"))

                transfer_records.append(
                    {
                        "legacy_transfer_id": parse_int(row.get("id")),
                        "day_index": day_index,
                        "transport_mode": mode,
                        "departure_time": dep_time,
                        "arrival_time": arr_time,
                        "note": rich_text_from_plain(row.get("comment")),
                        "vessel_number": clean_text(row.get("code")) or None,
                        "carrier": clean_text(row.get("company")) or None,
                        "departure_station": clean_text(row.get("station_from")) or None,
                        "arrival_station": clean_text(row.get("station_to")) or None,
                        "departure_city_geonames_id": from_geonames,
                        "arrival_city_geonames_id": to_geonames,
                        "link": link_url or None,
                        "expense": expense,
                    }
                )

        # Day expenses
        day_expense_records: list[dict[str, Any]] = []
        for day in ordered_days:
            day_id = day["id"]
            day_index = day_index_by_day_id[day_id]
            for row in sorted(day_expenses_by_day.get(day_id, []), key=lambda e: parse_int(e.get("id"), 0)):
                amount_cents = parse_int(row.get("amount_cents"), 0) or 0
                amount_currency = clean_text(row.get("amount_currency")) or currency
                if amount_cents <= 0:
                    continue

                day_expense_records.append(
                    {
                        "legacy_day_expense_id": parse_int(row.get("id")),
                        "name": clean_text(row.get("name")) or "Legacy day expense",
                        "day_index": day_index,
                        "expense": {
                            "name": clean_text(row.get("name")) or "Legacy day expense",
                            "amount_cents": amount_cents,
                            "currency": amount_currency,
                        },
                    }
                )

        # Food expense (aggregate all legacy caterings for the trip into one record).
        food_expense_record: dict[str, Any] | None = None
        trip_caterings = caterings_by_trip.get(legacy_trip_id, [])
        if trip_caterings:
            food_currency = clean_text(trip_caterings[0].get("amount_currency")) or currency

            days_count_candidates = [parse_int(c.get("days_count")) for c in trip_caterings]
            days_count_candidates = [v for v in days_count_candidates if v and v > 0]
            sum_days_count = sum(days_count_candidates)
            days_count = day_count if day_count and day_count > 0 else max(sum_days_count, 1)

            people_count_candidates = [parse_int(c.get("persons_count")) for c in trip_caterings]
            people_count_candidates = [v for v in people_count_candidates if v and v > 0]
            food_people_count = max(people_count_candidates) if people_count_candidates else people_count

            # Legacy caterings.amount_cents is a per-day-per-person value.
            # Convert to total cents first, then derive a single averaged daily value
            # for the new app's one-record food expense model.
            total_amount_cents = 0
            for c in trip_caterings:
                rate_cents = parse_int(c.get("amount_cents"), 0) or 0
                row_days = parse_int(c.get("days_count"), 0) or days_count
                row_people = parse_int(c.get("persons_count"), 0) or food_people_count
                total_amount_cents += rate_cents * max(row_days, 1) * max(row_people, 1)

            denominator = max(days_count * food_people_count, 1)
            price_per_day_cents = total_amount_cents // denominator

            food_expense_record = {
                "price_per_day_cents": price_per_day_cents,
                "days_count": days_count,
                "people_count": food_people_count,
                "expense": {
                    "name": "Legacy food expense",
                    "amount_cents": total_amount_cents,
                    "currency": food_currency,
                },
                "legacy_catering_ids": [parse_int(c.get("id")) for c in trip_caterings if parse_int(c.get("id"))],
            }

        # Notes
        note_records: list[dict[str, Any]] = []

        trip_comment = clean_text(trip.get("comment"))
        if trip_comment:
            note_records.append(
                {
                    "title": "Отчет о путешествии",
                    "text": rich_text_from_plain(trip_comment),
                    "day_index": None,
                }
            )

        food_note_html = build_food_note_html(trip_caterings)
        if food_note_html:
            note_records.append(
                {
                    "title": "Еда",
                    "text": food_note_html,
                    "day_index": None,
                }
            )

        for day in ordered_days:
            day_id = day["id"]
            day_index = day_index_by_day_id[day_id]
            day_comment = clean_text(day.get("comment"))
            if day_comment:
                note_records.append(
                    {
                        "title": f"Legacy day {day_index + 1} comment",
                        "text": rich_text_from_plain(day_comment),
                        "day_index": day_index,
                    }
                )

            for link_row in sorted(
                external_links_by_type_id.get(("Travels::Day", day_id), []),
                key=lambda r: parse_int(r.get("id"), 0),
            ):
                title = clean_text(link_row.get("description")) or "Legacy day link"
                url = clean_text(link_row.get("url"))
                if not url:
                    continue
                note_records.append(
                    {
                        "title": title,
                        "text": rich_text_link(url),
                        "day_index": day_index,
                    }
                )

        for doc in sorted(documents_by_trip.get(legacy_trip_id, []), key=lambda r: parse_int(r.get("id"), 0)):
            title_tail = clean_text(doc.get("name")) or f"Document #{doc.get('id')}"
            file_uid = clean_text(doc.get("file_uid"))
            mime_type = clean_text(doc.get("mime_type"))
            if not file_uid:
                continue
            note_records.append(
                {
                    "title": f"Legacy document: {title_tail}",
                    "text": rich_text_from_plain(f"{file_uid} ({mime_type})" if mime_type else file_uid),
                    "day_index": None,
                }
            )

        if trip_invites_by_trip.get(legacy_trip_id):
            warnings.append(
                WarningItem(
                    code="trip_has_invites",
                    trip_id=legacy_trip_id,
                    entity="trip",
                    entity_id=legacy_trip_id,
                    message="Trip has invite rows; these are not represented in import bundle.",
                )
            )

        # Day index map rows for debugging and import verification.
        for day in ordered_days:
            day_index_map_rows.append(
                {
                    "trip_ref": trip_ref,
                    "legacy_trip_id": parse_int(legacy_trip_id),
                    "legacy_day_id": parse_int(day.get("id")),
                    "day_index": day_index_by_day_id[day["id"]],
                    "date_when": clean_text(day.get("date_when")) or None,
                    "legacy_index": parse_int(day.get("index")),
                }
            )

        trip_rows_out.append(
            {
                "trip_ref": trip_ref,
                "legacy_trip_id": parse_int(legacy_trip_id),
                "name": clean_text(trip.get("name")),
                "status": status,
                "dates_unknown": dates_unknown,
                "start_date": start_date,
                "end_date": end_date,
                "duration": duration,
                "currency": currency,
                "people_count": people_count,
                "private": parse_bool(trip.get("private"), False),
                "author_legacy_user_id": author_legacy_user_id,
                "participant_legacy_user_ids": participant_ids,
                "destinations": destinations,
                "activities": activity_records,
                "accommodations": accommodation_records,
                "transfers": transfer_records,
                "day_expenses": day_expense_records,
                "food_expense": food_expense_record,
                "notes": note_records,
                "source_counts": {
                    "days": len(ordered_days),
                    "activities": len(activity_records),
                    "accommodations": len(accommodation_records),
                    "transfers": len(transfer_records),
                    "day_expenses": len(day_expense_records),
                    "notes": len(note_records),
                },
            }
        )

    warnings_rows = [
        {
            "code": item.code,
            "trip_id": parse_int(item.trip_id) if item.trip_id else None,
            "entity": item.entity,
            "entity_id": item.entity_id,
            "message": item.message,
        }
        for item in warnings
    ]

    # Write outputs.
    write_jsonl(output_dir / "trips.jsonl", trip_rows_out)
    write_jsonl(output_dir / "warnings.jsonl", warnings_rows)
    write_json(output_dir / "legacy_user_mapping.template.json", {str(user_id): None for user_id in user_ids if user_id})
    write_json(
        output_dir / "summary.json",
        {
            "format_version": 1,
            "created_at_utc": datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "input_dir": str(input_dir),
            "output_dir": str(output_dir),
            "legacy_user_ids": user_ids,
            "trip_count": len(trip_rows_out),
            "warning_count": len(warnings_rows),
            "notes": [
                "Resolve legacy_user_ids to target users during import using legacy_user_mapping.template.json.",
                "Destination and transfer city references use geonames IDs (city_geonames_id fields).",
                "day_index fields are derived from legacy days ordering per trip.",
            ],
        },
    )

    # Persist day index mapping for easier debugging.
    with (output_dir / "day_index_map.csv").open("w", newline="", encoding="utf-8") as f:
        fieldnames = ["trip_ref", "legacy_trip_id", "legacy_day_id", "day_index", "date_when", "legacy_index"]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in day_index_map_rows:
            writer.writerow(row)

    print(f"Converted trips: {len(trip_rows_out)}")
    print(f"Warnings: {len(warnings_rows)}")
    print(f"Output directory: {output_dir}")


if __name__ == "__main__":
    main()
