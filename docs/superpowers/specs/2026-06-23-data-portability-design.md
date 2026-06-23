# Data Portability (Export & Import) Design

**Date:** 2026-06-23  
**Status:** Approved

## Goal

Replace the inaccessible "Save to Documents" export with an OS share sheet, add CSV export with historical trigger data as expanded columns, and add JSON and CSV import with replace-all or merge conflict resolution.

## New Packages

| Package | Purpose |
|---------|---------|
| `share_plus` | OS share sheet (Android, iOS, web download fallback) |
| `file_picker` | File picker for import |
| `archive` | Pure-Dart ZIP creation and extraction |

## Export

### UI Changes

- "Export JSON Data" settings row renamed to **"Export Data"**; subtitle updated to reflect both formats and risk history inclusion
- Export dialog title: "Export Data"
- Format radio toggle added: **JSON** (default) / **CSV**
- Actions: Cancel · Copy to Clipboard (JSON only; greyed out when CSV selected) · **Share**
- "Save to Documents" action removed
- Share invokes `share_plus`, writing the file to a system temp path first

### JSON Export (`schema_version` 2)

Adds the following tables to the existing four (`attacks`, `journal_entries`, `settings`, `user_trigger_flags`):

| New table | Notes |
|-----------|-------|
| `risk_assessments` | Includes full `contributors_json` blob |
| `periods` | Menstrual cycle periods |
| `period_day_severities` | Per-day severity within a period |
| `manual_sleep_records` | Manually entered sleep data |
| `day_location_overrides` | User-set location overrides per day |

Old v1 backups remain importable — the importer handles missing tables gracefully.

`WeatherSnapshots` and `BaselinesKv` are excluded (large, fully re-derivable).

### CSV Export

Produces a ZIP file (`migraine_forecast_export_YYYY-MM-DD.zip`) containing three CSVs:

**`attacks.csv`**
```
id, started_at, ended_at, severity, notes, risk_assessment_id, in_progress
```

**`journal_entries.csv`**
```
id, at, kind, payload_json
```
`payload_json` stays as a JSON string in a single cell — each journal kind has a different payload shape.

**`risk_assessments.csv`**
```
target_date, horizon, score, band, computed_at, config_version, backfilled,
pressure_drop_contribution, pressure_drop_explanation,
humidity_contribution, humidity_explanation,
temp_swing_contribution, temp_swing_explanation,
air_quality_contribution, air_quality_explanation,
stress_contribution, stress_explanation,
sleep_deficit_contribution, sleep_deficit_explanation,
alcohol_contribution, alcohol_explanation,
caffeine_contribution, caffeine_explanation,
hydration_contribution, hydration_explanation,
menstrual_phase_contribution, menstrual_phase_explanation
```

Trigger columns are populated by parsing `contributors_json` from the risk assessments table. Missing modules for a given row get empty cells. `{id}_contribution` = `weight × confidence` (the `TriggerSignal.contribution` getter).

**DateTime format:** all DateTime values in CSV and JSON are serialised as UTC ISO 8601 strings (e.g. `2026-06-23T12:00:00.000Z`). The importer parses them with `DateTime.parse(...).toUtc()` before writing to Drift. This is already the case for the existing JSON export; the new CSV path must match.

## Import

### UI

- New **"Import Data"** settings row below "Export Data"
- Subtitle: "Restore from a previous JSON or CSV export"
- Tapping immediately opens the file picker (no pre-dialog)
- Picker is configured with `FileType.any` (extension filtering via MIME/UTI is unreliable on Android/iOS); after selection the extension is checked in code and an error dialog shown for unsupported types
- Accepted extensions: `.json`, `.zip`
- After file selection: format is detected by extension, then a conflict dialog is shown

### Conflict Dialog

> **How should we handle conflicts?**
> - **Replace all** — Wipe existing data for the imported tables and restore from file
> - **Merge** — Keep existing records; only import records not already present

### Atomicity

All import operations (both replace-all and merge) are wrapped in a single Drift transaction. If any step fails the entire import is rolled back and an error dialog is shown. This prevents half-wiped databases on replace-all failures.

### JSON Import

1. Parse JSON, validate `schema_version` is 1 or 2; reject anything else with an error dialog
2. Apply conflict mode (replace-all or merge) to each table present in the file
3. Merge semantics per table:

| Table | Merge key | Insert mode |
|-------|-----------|-------------|
| attacks | `id` | `INSERT OR IGNORE` — skip if id already exists |
| journal_entries | `id` | `INSERT OR IGNORE` — skip if id already exists |
| risk_assessments | `(target_date, horizon)` unique index | `INSERT OR REPLACE` — overwrite if same date+horizon exists |
| settings | `key` | `INSERT OR REPLACE` |
| user_trigger_flags | `module_id` | `INSERT OR REPLACE` |
| manual_sleep_records | `night` | `INSERT OR IGNORE` |
| periods | `id` | `INSERT OR IGNORE` |
| period_day_severities | `day` | `INSERT OR IGNORE` |
| day_location_overrides | `day` | `INSERT OR IGNORE` |

`INSERT OR IGNORE` is used for `attacks` and `journal_entries` because their IDs are autoincrement and a conflicting ID from another device would replace an unrelated local record. Existing records always win for these tables.

**v1 JSON imports:** tables absent from the file are left untouched regardless of conflict mode (replace-all only clears tables that are present in the file).

4. Show success snackbar: "Imported N records" (N = total rows inserted or upserted across all tables)

### CSV ZIP Import

1. Extract ZIP; process the three known filenames; ignore unknown files
2. Apply same replace-all / merge logic as JSON, limited to the three tables present in CSV
3. Show success snackbar: "Imported N records" (N = total rows inserted or upserted across all tables)

### Error Handling

The following each show an `AlertDialog` with a plain-English message — no silent failures:

- Malformed JSON
- Unrecognised `schema_version`
- Missing required CSV columns
- ZIP extraction failure
- File picker cancelled (no dialog, just no-op)

## What Is Not Changing

- "Rebuild risk history" and "Clear all data" settings rows are untouched
- `WeatherSnapshots` and `BaselinesKv` excluded from all export/import formats
- Web export: `share_plus` web implementation triggers a browser download
- `ExportRepo.buildJson()` (v1, existing method) is kept for existing tests; new method is `buildJsonFull()`

## Out of Scope

- Automatic cloud backup / sync
- Selective import (choosing which tables to restore)
- CSV import of `periods`, `period_day_severities`, `manual_sleep_records`, `day_location_overrides` (JSON only for those tables)
