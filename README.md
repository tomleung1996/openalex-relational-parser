# OpenAlex Relational Parser

This project converts OpenAlex snapshot JSONL files into relational CSV exports that follow the CWTS OpenAlex schema. Every table in the schema except `citation` and `work_detail` is materialised directly (those two are created downstream in SQL after loading). The current schema contains 88 tables, and the converter automatically adapts if CWTS adds or removes tables. A Chinese translation of this document is available in [README.zh.md](README.zh.md).

> The OpenAlex relational schema was designed by Dr. Nees Jan van Eck and the CWTS team at Leiden University. They deserve full credit for that work. The maintainers of this repository are solely responsible for the parsing code presented here. See the CWTS reference implementation and schema resources at https://github.com/CWTSLeiden/CWTS-OpenAlex-databases.

## Repository Layout

```
openalex-relational-parser/
|-- data/
|   |-- openalex-snapshot-YYYYMMDD/      # OpenAlex JSON snapshot (gzip files)
|   |-- reference/
|       |-- openalex_cwts_schema.sql     # CWTS schema definition (copy for convenience)
|-- output/                              # Generated CSVs plus collected IDs (created after running)
|   |-- reference_ids/                   # Enumerations + namespace assignments written by the CLI
|-- src/
    |-- openalex_parser/
        |-- cli.py                       # Command-line entry point
        |-- transformers/                # JSON -> CSV mappers for each entity
        |-- ...                          # Shared utilities, schema loader, emitters, etc.
```

## Installation

Only the Python standard library is required, so CPython 3.9+ is enough. Installing `orjson` (optional) speeds up JSON parsing; the CLI automatically falls back to the built-in `json` module if `orjson` is missing.

## How the Converter Works

1. The CLI reads the CWTS schema SQL (default `data/reference/openalex_cwts_schema.sql`, override with `--schema`).
2. A first "collect" pass scans the requested OpenAlex entities and gathers every enumeration value (work types, licenses, OA status, etc.) plus auxiliary namespaces such as keywords or raw affiliation strings. Deterministic IDs are assigned and written as tab-separated reference CSVs under `--reference-dir` (defaults to `output/reference_ids`). Keep this directory around to skip the collection pass on subsequent runs.
3. A second "parse" pass replays the entities, converts JSON to row dictionaries via the transformer classes, de-duplicates shared lookup tables, and streams rows to CSV files under `--output-dir`.
4. If `--skip-merged-ids` is enabled, the CLI inspects the snapshot's `merged_ids` directories and silently drops merged records.

All CSVs use schema column order, `\t` as the default delimiter, UTF-8 encoding, and Unix newlines. Each entity reports incremental and final counts through the `ProgressReporter`. Post-load SQL takes care of populating the CWTS `citation` and `work_detail` tables.

## Usage

Run the CLI module from the repository root:

```
set PYTHONPATH=src  # PowerShell/CMD; use 'export PYTHONPATH=src' on bash/zsh
python -m openalex_parser.cli --entity all --output-dir output
```

The command will:

1. Load the schema supplied via `--schema`.
2. Collect or reuse enumeration/namespace assignments under `--reference-dir`.
3. Iterate over every requested OpenAlex entity inside `--snapshot` (defaults to `data/openalex-snapshot-20250930/data`).
4. Emit one CSV per schema table (currently 88) into `--output-dir` (minus `citation` and `work_detail`, which are built in-database later).
5. Print per-entity progress and a summary when finished.

### CLI Arguments

- `--schema PATH` - Path to the CWTS schema SQL file.
- `--reference-dir PATH` - Directory that stores generated enumeration + namespace CSVs (defaults to `output/reference_ids`). If the directory already contains complete assignments, the collect phase is skipped.
- `--snapshot PATH` - Root of the OpenAlex snapshot (expects subfolders like `works/`, `authors/`, ...).
- `--output-dir PATH` - Where result CSVs will be written (defaults to `output`).
- `--entity NAME` - Entity (or `all`) to process; repeat the flag for multiple names.
- `--updated-date YYYY-MM-DD` - Restrict input to specific `updated_date=` partitions (repeatable).
- `--max-records N` - Cap records per entity (omit or set <=0 for full runs).
- `--max-files N` - Limit gzip part files per entity.
- `--encoding {utf-8,utf-16le}` - Target encoding for generated CSVs (default `utf-8`).
- `--delimiter CHAR` - Single-character delimiter for CSV output (default `\t`).
- `--progress-interval N` - Records between progress messages (default `1000`).
- `--skip-merged-ids` - Drop IDs listed under snapshot `merged_ids/*` directories.

#### Examples

Process a smoke-test slice of the `works` entity:

```
python -m openalex_parser.cli ^
    --entity works ^
    --updated-date 2023-05-17 ^
    --max-records 500 ^
    --max-files 2 ^
    --output-dir staging-output
```

Process authors and institutions only while skipping merged IDs:

```
python -m openalex_parser.cli --entity authors --entity institutions --skip-merged-ids
```

## Output

- One CSV per schema table (e.g. `work.csv`, `institution_relation.csv`, `raw_affiliation_string.csv`). The count automatically reflects the schema you supply, with the exception of `citation` and `work_detail`, which are populated via downstream SQL after all other tables are loaded.
- `output/reference_ids/` (or the directory passed to `--reference-dir`) contains the generated enumeration CSVs (`license.csv`, `work_type.csv`, ...) plus namespace files (`keyword_ids.csv`, `raw_author_name_ids.csv`, ...). These files are the new source-of-truth instead of the legacy `data/reference/openalex_cwts_sample_export` bundle.
- Shared lookup tables such as countries, keywords, SDGs, WHO MeSH descriptors, raw author names, and raw affiliation strings are deduplicated using deterministic keys to prevent duplicate dimension rows across entities.

## Troubleshooting

- **Missing data directories:** Ensure `data/openalex-snapshot-YYYYMMDD/data` contains entity folders (`works`, `authors`, ...). The CLI skips entities whose directories are absent.
- **Slow smoke tests:** Use `--max-records`, `--max-files`, and `--updated-date` to limit input volume.
- **Merged records:** Supply `--skip-merged-ids` to ignore IDs listed in `merged_ids/` directories that accompany the snapshot.
- **Character encoding or delimiters:** Override `--encoding` or `--delimiter` to match your loading environment (SQL Server often prefers UTF-16LE with tab delimiters).

Happy parsing!
