# Country, State, City English/Arabic Data

Source package: `country_state_city 0.1.6`

## Counts

- Countries: 250
- States: 4871
- Cities: 147783
- Total rows: 152904

## Files

- `country_state_city_en_ar.csv`: flat list for review/search/import.
- `country_state_city_en_ar.json`: structured list for app integration.

## Arabic Generation

Countries use the runtime Arabic region names from `Intl.DisplayNames` where available. States and cities have Arabic values generated for every record using a deterministic Arabic transliteration pass, with a small set of manual overrides for common Camion markets.

This gives complete A-Z coverage, but generated state/city Arabic should be reviewed for important markets before treating it as verified geographic localization.
