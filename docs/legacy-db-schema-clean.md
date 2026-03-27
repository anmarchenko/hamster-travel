# Legacy Database Schema

- Source DB: `hamster_travel_legacy_prod`
- Host: `localhost:6000`
- Schema: `public`
- Generated at: `2026-03-08 17:09:21Z`

## Tables

### activities

- Rows: `2394`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('activities_id_seq'::regclass) |
| `order_index` | `int4` | YES |  |
| `name` | `varchar(255)` | YES |  |
| `comment` | `text` | YES |  |
| `link_description` | `varchar(255)` | YES |  |
| `link_url` | `text` | YES |  |
| `day_id` | `int4` | YES |  |
| `amount_cents` | `int4` | NO | 0 |
| `amount_currency` | `varchar` | NO | 'RUB'::character varying |
| `rating` | `int4` | YES | 2 |
| `address` | `varchar` | YES |  |
| `working_hours` | `varchar` | YES |  |

#### Foreign Key Details

_(none)_

### adm3_translations

- Rows: `140432`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('adm3_translations_id_seq'::regclass) |
| `adm3_id` | `int4` | NO |  |
| `locale` | `varchar` | NO |  |
| `created_at` | `timestamp` | NO |  |
| `updated_at` | `timestamp` | NO |  |
| `name` | `varchar` | YES |  |

#### Foreign Key Details

_(none)_

### adm3s

- Rows: `70216`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('adm3s_id_seq'::regclass) |
| `geonames_code` | `varchar(255)` | YES |  |
| `geonames_modification_date` | `date` | YES |  |
| `latitude` | `float8` | YES |  |
| `longitude` | `float8` | YES |  |
| `population` | `int4` | YES |  |
| `country_code` | `varchar(255)` | YES |  |
| `region_code` | `varchar(255)` | YES |  |
| `district_code` | `varchar(255)` | YES |  |
| `adm3_code` | `varchar(255)` | YES |  |
| `adm4_code` | `varchar(255)` | YES |  |
| `adm5_code` | `varchar(255)` | YES |  |
| `timezone` | `varchar(255)` | YES |  |

#### Foreign Key Details

_(none)_

### adm4_translations

- Rows: `200692`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('adm4_translations_id_seq'::regclass) |
| `adm4_id` | `int4` | NO |  |
| `locale` | `varchar` | NO |  |
| `created_at` | `timestamp` | NO |  |
| `updated_at` | `timestamp` | NO |  |
| `name` | `varchar` | YES |  |

#### Foreign Key Details

_(none)_

### adm4s

- Rows: `100346`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('adm4s_id_seq'::regclass) |
| `geonames_code` | `varchar(255)` | YES |  |
| `geonames_modification_date` | `date` | YES |  |
| `latitude` | `float8` | YES |  |
| `longitude` | `float8` | YES |  |
| `population` | `int4` | YES |  |
| `country_code` | `varchar(255)` | YES |  |
| `region_code` | `varchar(255)` | YES |  |
| `district_code` | `varchar(255)` | YES |  |
| `adm3_code` | `varchar(255)` | YES |  |
| `adm4_code` | `varchar(255)` | YES |  |
| `adm5_code` | `varchar(255)` | YES |  |
| `timezone` | `varchar(255)` | YES |  |

#### Foreign Key Details

_(none)_

### adm5_translations

- Rows: `72498`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('adm5_translations_id_seq'::regclass) |
| `adm5_id` | `int4` | NO |  |
| `locale` | `varchar` | NO |  |
| `created_at` | `timestamp` | NO |  |
| `updated_at` | `timestamp` | NO |  |
| `name` | `varchar` | YES |  |

#### Foreign Key Details

_(none)_

### adm5s

- Rows: `36249`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('adm5s_id_seq'::regclass) |
| `geonames_code` | `varchar(255)` | YES |  |
| `geonames_modification_date` | `date` | YES |  |
| `latitude` | `float8` | YES |  |
| `longitude` | `float8` | YES |  |
| `population` | `int4` | YES |  |
| `country_code` | `varchar(255)` | YES |  |
| `region_code` | `varchar(255)` | YES |  |
| `district_code` | `varchar(255)` | YES |  |
| `adm3_code` | `varchar(255)` | YES |  |
| `adm4_code` | `varchar(255)` | YES |  |
| `adm5_code` | `varchar(255)` | YES |  |
| `timezone` | `varchar(255)` | YES |  |

#### Foreign Key Details

_(none)_

### ar_internal_metadata

- Rows: `1`
- Primary key: `key`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `key` | `varchar` | NO |  |
| `value` | `varchar` | YES |  |
| `created_at` | `timestamp` | NO |  |
| `updated_at` | `timestamp` | NO |  |

#### Foreign Key Details

_(none)_

### caterings

- Rows: `119`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('caterings_id_seq'::regclass) |
| `description` | `text` | YES |  |
| `days_count` | `int4` | YES |  |
| `persons_count` | `int4` | YES |  |
| `trip_id` | `int4` | YES |  |
| `amount_cents` | `int4` | NO | 0 |
| `amount_currency` | `varchar` | NO | 'RUB'::character varying |
| `order_index` | `int4` | YES |  |
| `name` | `varchar` | YES |  |

#### Foreign Key Details

_(none)_

### cities

- Rows: `205040`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('cities_id_seq'::regclass) |
| `geonames_code` | `varchar(255)` | YES |  |
| `geonames_modification_date` | `date` | YES |  |
| `latitude` | `float8` | YES |  |
| `longitude` | `float8` | YES |  |
| `population` | `int4` | YES |  |
| `country_code` | `varchar(255)` | YES |  |
| `region_code` | `varchar(255)` | YES |  |
| `district_code` | `varchar(255)` | YES |  |
| `adm3_code` | `varchar(255)` | YES |  |
| `adm4_code` | `varchar(255)` | YES |  |
| `adm5_code` | `varchar(255)` | YES |  |
| `timezone` | `varchar(255)` | YES |  |
| `status` | `varchar(255)` | YES |  |

#### Foreign Key Details

_(none)_

### cities_users

- Rows: `56`
- Primary key: _(none)_
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `user_id` | `int4` | NO |  |
| `city_id` | `int4` | NO |  |

#### Foreign Key Details

_(none)_

### city_translations

- Rows: `410080`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('city_translations_id_seq'::regclass) |
| `city_id` | `int4` | NO |  |
| `locale` | `varchar` | NO |  |
| `created_at` | `timestamp` | NO |  |
| `updated_at` | `timestamp` | NO |  |
| `name` | `varchar` | YES |  |

#### Foreign Key Details

_(none)_

### countries

- Rows: `239`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('countries_id_seq'::regclass) |
| `geonames_code` | `varchar(255)` | YES |  |
| `geonames_modification_date` | `date` | YES |  |
| `latitude` | `float8` | YES |  |
| `longitude` | `float8` | YES |  |
| `population` | `int4` | YES |  |
| `country_code` | `varchar(255)` | YES |  |
| `region_code` | `varchar(255)` | YES |  |
| `district_code` | `varchar(255)` | YES |  |
| `adm3_code` | `varchar(255)` | YES |  |
| `adm4_code` | `varchar(255)` | YES |  |
| `adm5_code` | `varchar(255)` | YES |  |
| `timezone` | `varchar(255)` | YES |  |
| `iso_code` | `varchar(255)` | YES |  |
| `iso3_code` | `varchar(255)` | YES |  |
| `iso_numeric_code` | `varchar(255)` | YES |  |
| `area` | `int4` | YES |  |
| `currency_code` | `varchar(255)` | YES |  |
| `currency_text` | `varchar(255)` | YES |  |
| `languages` | `_text` | YES | '{}'::text[] |
| `continent` | `varchar(255)` | YES |  |

#### Foreign Key Details

_(none)_

### country_translations

- Rows: `478`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('country_translations_id_seq'::regclass) |
| `country_id` | `int4` | NO |  |
| `locale` | `varchar` | NO |  |
| `created_at` | `timestamp` | NO |  |
| `updated_at` | `timestamp` | NO |  |
| `name` | `varchar` | YES |  |

#### Foreign Key Details

_(none)_

### days

- Rows: `879`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('days_id_seq'::regclass) |
| `date_when` | `date` | YES |  |
| `comment` | `text` | YES |  |
| `trip_id` | `int4` | YES |  |
| `index` | `int4` | YES |  |

#### Foreign Key Details

_(none)_

### district_translations

- Rows: `72900`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('district_translations_id_seq'::regclass) |
| `district_id` | `int4` | NO |  |
| `locale` | `varchar` | NO |  |
| `created_at` | `timestamp` | NO |  |
| `updated_at` | `timestamp` | NO |  |
| `name` | `varchar` | YES |  |

#### Foreign Key Details

_(none)_

### districts

- Rows: `36450`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('districts_id_seq'::regclass) |
| `geonames_code` | `varchar(255)` | YES |  |
| `geonames_modification_date` | `date` | YES |  |
| `latitude` | `float8` | YES |  |
| `longitude` | `float8` | YES |  |
| `population` | `int4` | YES |  |
| `country_code` | `varchar(255)` | YES |  |
| `region_code` | `varchar(255)` | YES |  |
| `district_code` | `varchar(255)` | YES |  |
| `adm3_code` | `varchar(255)` | YES |  |
| `adm4_code` | `varchar(255)` | YES |  |
| `adm5_code` | `varchar(255)` | YES |  |
| `timezone` | `varchar(255)` | YES |  |

#### Foreign Key Details

_(none)_

### documents

- Rows: `83`
- Primary key: `id`
- Foreign keys: `1`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('documents_id_seq'::regclass) |
| `file_uid` | `varchar` | YES |  |
| `mime_type` | `varchar` | YES |  |
| `trip_id` | `int4` | YES |  |
| `name` | `varchar` | YES |  |

#### Foreign Key Details

| Constraint | Column | References |
|---|---|---|
| `fk_rails_7b2248268a` | `trip_id` | `trips.id` |

### exchange_rates

- Rows: `1`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('exchange_rates_id_seq'::regclass) |
| `eu_file` | `text` | YES |  |
| `created_at` | `timestamp` | NO |  |
| `updated_at` | `timestamp` | NO |  |
| `rates_date` | `date` | YES |  |

#### Foreign Key Details

_(none)_

### expenses

- Rows: `1082`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('expenses_id_seq'::regclass) |
| `name` | `varchar(255)` | YES |  |
| `expendable_id` | `int4` | YES |  |
| `expendable_type` | `varchar(255)` | YES |  |
| `amount_cents` | `int4` | NO | 0 |
| `amount_currency` | `varchar` | NO | 'RUB'::character varying |

#### Foreign Key Details

_(none)_

### external_links

- Rows: `1759`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('external_links_id_seq'::regclass) |
| `description` | `varchar(255)` | YES |  |
| `url` | `text` | YES |  |
| `linkable_id` | `int4` | YES |  |
| `linkable_type` | `varchar(255)` | YES |  |

#### Foreign Key Details

_(none)_

### hotels

- Rows: `879`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('hotels_id_seq'::regclass) |
| `name` | `varchar(255)` | YES |  |
| `comment` | `text` | YES |  |
| `day_id` | `int4` | YES |  |
| `amount_cents` | `int4` | NO | 0 |
| `amount_currency` | `varchar` | NO | 'RUB'::character varying |

#### Foreign Key Details

_(none)_

### places

- Rows: `976`
- Primary key: `id`
- Foreign keys: `1`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('places_id_seq'::regclass) |
| `day_id` | `int4` | YES |  |
| `city_id` | `int4` | YES |  |

#### Foreign Key Details

| Constraint | Column | References |
|---|---|---|
| `fk_rails_93de4496b8` | `city_id` | `cities.id` |

### region_translations

- Rows: `7800`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('region_translations_id_seq'::regclass) |
| `region_id` | `int4` | NO |  |
| `locale` | `varchar` | NO |  |
| `created_at` | `timestamp` | NO |  |
| `updated_at` | `timestamp` | NO |  |
| `name` | `varchar` | YES |  |

#### Foreign Key Details

_(none)_

### regions

- Rows: `3900`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('regions_id_seq'::regclass) |
| `geonames_code` | `varchar(255)` | YES |  |
| `geonames_modification_date` | `date` | YES |  |
| `latitude` | `float8` | YES |  |
| `longitude` | `float8` | YES |  |
| `population` | `int4` | YES |  |
| `country_code` | `varchar(255)` | YES |  |
| `region_code` | `varchar(255)` | YES |  |
| `district_code` | `varchar(255)` | YES |  |
| `adm3_code` | `varchar(255)` | YES |  |
| `adm4_code` | `varchar(255)` | YES |  |
| `adm5_code` | `varchar(255)` | YES |  |
| `timezone` | `varchar(255)` | YES |  |

#### Foreign Key Details

_(none)_

### schema_migrations

- Rows: `52`
- Primary key: _(none)_
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `version` | `varchar(255)` | NO |  |

#### Foreign Key Details

_(none)_

### transfers

- Rows: `515`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('transfers_id_seq'::regclass) |
| `order_index` | `int4` | YES |  |
| `type` | `varchar(255)` | YES |  |
| `code` | `varchar(255)` | YES |  |
| `company` | `varchar(255)` | YES |  |
| `link` | `varchar(255)` | YES |  |
| `station_from` | `varchar(255)` | YES |  |
| `station_to` | `varchar(255)` | YES |  |
| `start_time` | `timestamp` | YES |  |
| `end_time` | `timestamp` | YES |  |
| `comment` | `text` | YES |  |
| `day_id` | `int4` | YES |  |
| `amount_cents` | `int4` | NO | 0 |
| `amount_currency` | `varchar` | NO | 'RUB'::character varying |
| `city_to_id` | `int4` | YES |  |
| `city_from_id` | `int4` | YES |  |

#### Foreign Key Details

_(none)_

### trip_invites

- Rows: `0`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('trip_invites_id_seq'::regclass) |
| `inviting_user_id` | `int4` | YES |  |
| `invited_user_id` | `int4` | YES |  |
| `trip_id` | `int4` | YES |  |

#### Foreign Key Details

_(none)_

### trips

- Rows: `144`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('trips_id_seq'::regclass) |
| `name` | `varchar(255)` | YES |  |
| `short_description` | `text` | YES |  |
| `start_date` | `date` | YES |  |
| `end_date` | `date` | YES |  |
| `archived` | `bool` | YES | false |
| `comment` | `text` | YES |  |
| `budget_for` | `int4` | YES | 1 |
| `private` | `bool` | YES | false |
| `image_uid` | `varchar(255)` | YES |  |
| `status_code` | `varchar(255)` | YES | '0_draft'::character varying |
| `author_user_id` | `int4` | YES |  |
| `updated_at` | `timestamp` | YES |  |
| `created_at` | `timestamp` | YES |  |
| `currency` | `varchar` | YES |  |
| `dates_unknown` | `bool` | YES | false |
| `planned_days_count` | `int4` | YES |  |
| `countries_search_index` | `varchar` | YES |  |

#### Foreign Key Details

_(none)_

### users

- Rows: `2`
- Primary key: `id`
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `id` | `int4` | NO | nextval('users_id_seq'::regclass) |
| `email` | `varchar(255)` | YES |  |
| `encrypted_password` | `varchar(255)` | YES |  |
| `reset_password_token` | `varchar(255)` | YES |  |
| `reset_password_sent_at` | `timestamp` | YES |  |
| `remember_created_at` | `timestamp` | YES |  |
| `sign_in_count` | `int4` | YES |  |
| `current_sign_in_at` | `timestamp` | YES |  |
| `last_sign_in_at` | `timestamp` | YES |  |
| `current_sign_in_ip` | `varchar(255)` | YES |  |
| `last_sign_in_ip` | `varchar(255)` | YES |  |
| `first_name` | `varchar(255)` | YES |  |
| `last_name` | `varchar(255)` | YES |  |
| `locale` | `varchar(255)` | YES |  |
| `image_uid` | `varchar(255)` | YES |  |
| `created_at` | `timestamp` | YES |  |
| `updated_at` | `timestamp` | YES |  |
| `currency` | `varchar` | YES |  |
| `home_town_id` | `int4` | YES |  |
| `google_oauth_token` | `varchar` | YES |  |
| `google_oauth_uid` | `varchar` | YES |  |
| `google_oauth_expires_at` | `timestamp` | YES |  |
| `google_oauth_refresh_token` | `varchar` | YES |  |

#### Foreign Key Details

_(none)_

### users_trips

- Rows: `242`
- Primary key: _(none)_
- Foreign keys: `0`

| Column | Type | Nullable | Default |
|---|---|---|---|
| `trip_id` | `int4` | YES |  |
| `user_id` | `int4` | YES |  |

#### Foreign Key Details

_(none)_

