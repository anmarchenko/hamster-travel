#!/usr/bin/env python3
"""
Build a supplemental legacy trips bundle for trips omitted by old cleanup logic.

Selection rule:
- trip exists in full converted bundle
- trip is absent from baseline converted bundle
- trip author is in keep-user-ids
- trip participants include at least one user outside keep-user-ids

For selected trips, participant list is rewritten to include only keep-user-ids.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build supplemental bundle for trips omitted due to external participants."
    )
    parser.add_argument(
        "--full-bundle-dir",
        default="prod_backup/import_ready_full",
        help="Directory with full converted trips.jsonl (default: prod_backup/import_ready_full)",
    )
    parser.add_argument(
        "--baseline-bundle-dir",
        default="prod_backup/import_ready",
        help="Directory with baseline converted trips.jsonl (default: prod_backup/import_ready)",
    )
    parser.add_argument(
        "--output-dir",
        default="prod_backup/import_ready_external_participants",
        help="Output dir for supplemental bundle (default: prod_backup/import_ready_external_participants)",
    )
    parser.add_argument(
        "--keep-user-ids",
        default="191,192",
        help="Comma-separated legacy user IDs to keep as authors/participants (default: 191,192)",
    )
    return parser.parse_args()


def parse_keep_ids(value: str) -> set[int]:
    ids: set[int] = set()
    for raw in value.split(","):
        raw = raw.strip()
        if not raw:
            continue
        ids.add(int(raw))
    if not ids:
        raise ValueError("--keep-user-ids resolved to empty set")
    return ids


def read_jsonl(path: Path) -> list[dict]:
    rows: list[dict] = []
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            if line.strip():
                rows.append(json.loads(line))
    return rows


def write_jsonl(path: Path, rows: list[dict]) -> None:
    with path.open("w", encoding="utf-8") as f:
        for row in rows:
            f.write(json.dumps(row, ensure_ascii=False))
            f.write("\n")


def main() -> None:
    args = parse_args()
    keep_ids = parse_keep_ids(args.keep_user_ids)

    full_trips_path = Path(args.full_bundle_dir) / "trips.jsonl"
    baseline_trips_path = Path(args.baseline_bundle_dir) / "trips.jsonl"
    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    full_rows = read_jsonl(full_trips_path)
    baseline_rows = read_jsonl(baseline_trips_path)
    baseline_refs = {row["trip_ref"] for row in baseline_rows}

    selected: list[dict] = []
    list_rows: list[dict] = []

    for row in full_rows:
        trip_ref = row.get("trip_ref")
        if trip_ref in baseline_refs:
            continue

        author_legacy_id = row.get("author_legacy_user_id")
        if author_legacy_id not in keep_ids:
            continue

        participants = row.get("participant_legacy_user_ids") or []
        has_external_participant = any(user_id not in keep_ids for user_id in participants)
        if not has_external_participant:
            continue

        filtered_participants = [user_id for user_id in participants if user_id in keep_ids]
        updated = dict(row)
        updated["participant_legacy_user_ids"] = filtered_participants
        selected.append(updated)

        list_rows.append(
            {
                "legacy_trip_id": row.get("legacy_trip_id"),
                "trip_ref": trip_ref,
                "name": row.get("name"),
                "author_legacy_user_id": author_legacy_id,
                "original_participants": participants,
                "filtered_participants": filtered_participants,
            }
        )

    selected.sort(key=lambda row: row.get("legacy_trip_id") or 0)
    list_rows.sort(key=lambda row: row.get("legacy_trip_id") or 0)

    write_jsonl(out_dir / "trips.jsonl", selected)

    summary = {
        "count": len(selected),
        "keep_user_ids": sorted(keep_ids),
        "trip_refs": [row["trip_ref"] for row in selected],
    }
    with (out_dir / "summary.json").open("w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)
        f.write("\n")

    with (out_dir / "omitted_trips.md").open("w", encoding="utf-8") as f:
        f.write("# Trips omitted by old cleanup logic (external participants)\n\n")
        f.write(
            "| legacy_trip_id | trip_ref | name | author_legacy_user_id | original_participants | filtered_participants |\n"
        )
        f.write("|---:|---|---|---:|---|---|\n")
        for row in list_rows:
            name = str(row["name"] or "").replace("|", "/")
            f.write(
                f"| {row['legacy_trip_id']} | {row['trip_ref']} | {name} | {row['author_legacy_user_id']} | "
                f"{row['original_participants']} | {row['filtered_participants']} |\n"
            )

    print(f"Selected trips: {len(selected)}")
    print(f"Output: {out_dir}")


if __name__ == "__main__":
    main()
