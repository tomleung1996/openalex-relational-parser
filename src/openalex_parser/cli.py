"""Command-line interface for OpenAlex relational CSV conversion."""
from __future__ import annotations

import argparse
import csv
import gzip
import sys
from pathlib import Path
from typing import Callable, Dict, Iterable, List, Mapping, Optional

from .csv_writer import CsvWriterManager
from .emitter import TableEmitter
from .identifiers import StableIdGenerator
from .json_iter import ProgressReporter, SnapshotReader
from .reference import EnumerationConfig, EnumerationRegistry
from .schema import load_schema
from .utils import canonical_openalex_id
from .transformers import (
    AuthorTransformer,
    ConceptTransformer,
    DomainTransformer,
    FieldTransformer,
    FunderTransformer,
    InstitutionTransformer,
    PublisherTransformer,
    SourceTransformer,
    SubfieldTransformer,
    TopicTransformer,
    WorkTransformer,
)

DEFAULT_SCHEMA = Path("data/reference/openalex_cwts_schema.sql")
DEFAULT_REFERENCE_DIR = Path("data/reference/openalex_cwts_sample_export")
DEFAULT_SNAPSHOT = Path("data/openalex-snapshot-20250930/data")
DEFAULT_OUTPUT_DIR = Path("output")

ENTITY_DATASETS: Mapping[str, str] = {
    "works": "works",
    "authors": "authors",
    "institutions": "institutions",
    "concepts": "concepts",
    "domains": "domains",
    "fields": "fields",
    "subfields": "subfields",
    "topics": "topics",
    "funders": "funders",
    "publishers": "publishers",
    "sources": "sources",
}

TRANSFORMER_FACTORIES: Mapping[str, Callable[[TableEmitter, EnumerationRegistry, StableIdGenerator], object]] = {
    "works": lambda emitter, enums, ids: WorkTransformer(emitter, enums, ids),
    "authors": lambda emitter, enums, ids: AuthorTransformer(emitter, enums, ids),
    "institutions": lambda emitter, enums, ids: InstitutionTransformer(emitter, enums, ids),
    "concepts": lambda emitter, enums, ids: ConceptTransformer(emitter, enums, ids),
    "domains": lambda emitter, enums, ids: DomainTransformer(emitter),
    "fields": lambda emitter, enums, ids: FieldTransformer(emitter),
    "subfields": lambda emitter, enums, ids: SubfieldTransformer(emitter),
    "topics": lambda emitter, enums, ids: TopicTransformer(emitter),
    "funders": lambda emitter, enums, ids: FunderTransformer(emitter, enums, ids),
    "publishers": lambda emitter, enums, ids: PublisherTransformer(emitter, enums, ids),
    "sources": lambda emitter, enums, ids: SourceTransformer(emitter, enums, ids),
}

DEDUPE_KEYS: Mapping[str, tuple[str, ...]] = {
    "country": ("country_iso_alpha2_code",),
    "city": ("geonames_city_id",),
    "keyword": ("keyword_id",),
    "mesh_descriptor": ("mesh_descriptor_ui",),
    "mesh_qualifier": ("mesh_qualifier_ui",),
    "sustainable_development_goal": ("sustainable_development_goal_id",),
    "raw_author_name": ("raw_author_name_id",),
    "raw_affiliation_string": ("raw_affiliation_string_id",),
}


def _parse_delimiter(value: str) -> str:
    if not value:
        raise argparse.ArgumentTypeError("CSV delimiter cannot be empty.")
    try:
        normalized = value.encode("utf-8").decode("unicode_escape")
    except UnicodeDecodeError as exc:
        raise argparse.ArgumentTypeError(f"Invalid delimiter escape: {value}") from exc
    if len(normalized) != 1:
        raise argparse.ArgumentTypeError("CSV delimiter must be a single character.")
    return normalized


def parse_args(argv: Optional[Iterable[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert OpenAlex snapshot JSON into CWTS-compatible CSV files."
    )
    parser.add_argument(
        "--schema",
        type=Path,
        default=DEFAULT_SCHEMA,
        help="Path to the CWTS schema SQL file (default: %(default)s)",
    )
    parser.add_argument(
        "--reference-dir",
        type=Path,
        default=DEFAULT_REFERENCE_DIR,
        help="Directory containing reference CSV enumerations (default: %(default)s)",
    )
    parser.add_argument(
        "--snapshot",
        type=Path,
        default=DEFAULT_SNAPSHOT,
        help="Root directory of the OpenAlex snapshot data (default: %(default)s)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="Directory where CSV outputs will be written (default: %(default)s)",
    )
    parser.add_argument(
        "--entity",
        action="append",
        choices=sorted(ENTITY_DATASETS.keys()) + ["all"],
        required=True,
        help="Entity to process; specify multiple times or use 'all'",
    )
    parser.add_argument(
        "--updated-date",
        dest="updated_dates",
        action="append",
        help="Restrict processing to specific updated_date partitions (repeatable)",
    )
    parser.add_argument(
        "--max-records",
        type=int,
        default=None,
        help="Optional record cap per entity (omit for full run, use for smoke tests)",
    )
    parser.add_argument(
        "--max-files",
        type=int,
        default=None,
        help="Maximum gzip part files per entity (default: unlimited)",
    )
    parser.add_argument(
        "--encoding",
        choices=("utf-8", "utf-16le"),
        default="utf-8",
        help="Encoding for generated CSV files (default: %(default)s)",
    )
    parser.add_argument(
        "--delimiter",
        type=_parse_delimiter,
        default=",",
        help="Single-character delimiter for generated CSV files (default: ',')",
    )
    parser.add_argument(
        "--progress-interval",
        type=int,
        default=1000,
        help="Records between progress messages (default: %(default)s)",
    )
    return parser.parse_args(argv)




def load_merged_ids(snapshot_root: Path) -> Dict[str, set[str]]:
    merged_by_entity: Dict[str, set[str]] = {name: set() for name in ENTITY_DATASETS}
    candidates = [snapshot_root / "merged_ids", snapshot_root.parent / "merged_ids"]
    merged_root = None
    for candidate in candidates:
        if candidate.exists():
            merged_root = candidate
            break
    if merged_root is None:
        print("No merged_ids directory found; skipping merged ID checks.")
        return merged_by_entity
    print(f"Scanning merged_ids under {merged_root}...")
    for entity, dataset in ENTITY_DATASETS.items():
        entity_dir = merged_root / dataset
        if not entity_dir.exists():
            continue
        count_before = len(merged_by_entity[entity])
        for path in sorted(entity_dir.iterdir()):
            if path.suffix == ".gz":
                handle = gzip.open(path, "rt", encoding="utf-8")
            else:
                handle = path.open("r", encoding="utf-8")
            with handle as fh:
                reader = csv.DictReader(fh)
                for row in reader:
                    old_id = canonical_openalex_id(row.get("id"))
                    if old_id:
                        merged_by_entity[entity].add(old_id)
        added = len(merged_by_entity[entity]) - count_before
        if added:
            print(f"  {entity}: {added} ids marked as merged")
    return merged_by_entity


def register_enumerations(enums: EnumerationRegistry) -> None:
    configs = [
        EnumerationConfig("work_type", "work_type_id", "work_type", bits=15, reference_filename="work_type.csv"),
        EnumerationConfig(
            "doi_registration_agency",
            "doi_registration_agency_id",
            "doi_registration_agency",
            bits=8,
            reference_filename="doi_registration_agency.csv",
        ),
        EnumerationConfig("oa_status", "oa_status_id", "oa_status", bits=6, reference_filename="oa_status.csv"),
        EnumerationConfig(
            "apc_provenance",
            "apc_provenance_id",
            "apc_provenance",
            bits=6,
            reference_filename="apc_provenance.csv",
        ),
        EnumerationConfig(
            "fulltext_origin",
            "fulltext_origin_id",
            "fulltext_origin",
            bits=6,
            reference_filename="fulltext_origin.csv",
        ),
        EnumerationConfig("data_source", "data_source_id", "data_source", bits=6, reference_filename="data_source.csv"),
        EnumerationConfig("version", "version_id", "version", bits=6, reference_filename="version.csv"),
        EnumerationConfig("license", "license_id", "license", bits=12, reference_filename="license.csv"),
        EnumerationConfig(
            "author_position",
            "author_position_id",
            "author_position",
            bits=4,
            reference_filename="author_position.csv",
        ),
        EnumerationConfig(
            "sustainable_development_goal",
            "sustainable_development_goal_id",
            "sustainable_development_goal",
            bits=8,
            reference_filename="sustainable_development_goal.csv",
        ),
        EnumerationConfig(
            "institution_type",
            "institution_type_id",
            "institution_type",
            bits=6,
            reference_filename="institution_type.csv",
        ),
        EnumerationConfig(
            "institution_relationship_type",
            "institution_relationship_type_id",
            "institution_relationship_type",
            bits=4,
            reference_filename="institution_relationship_type.csv",
        ),
        EnumerationConfig("region", "region_id", "region", bits=20, reference_filename="region.csv"),
        EnumerationConfig(
            "source_type",
            "source_type_id",
            "source_type",
            bits=6,
            reference_filename="source_type.csv",
        ),
    ]
    for config in configs:
        enums.register(config)


def expand_entities(requested: List[str]) -> List[str]:
    if "all" in requested:
        return list(ENTITY_DATASETS.keys())
    # Preserve input order while removing duplicates
    seen = set()
    ordered: List[str] = []
    for name in requested:
        if name not in seen:
            seen.add(name)
            ordered.append(name)
    return ordered


def build_transformer(name: str, emitter: TableEmitter, enums: EnumerationRegistry, ids: StableIdGenerator):
    factory = TRANSFORMER_FACTORIES[name]
    return factory(emitter, enums, ids)


def main(argv: Optional[Iterable[str]] = None) -> int:
    args = parse_args(argv)

    entities = expand_entities(args.entity)

    schema = load_schema(args.schema)
    args.output_dir.mkdir(parents=True, exist_ok=True)

    writers = CsvWriterManager(
        schema,
        args.output_dir,
        encoding=args.encoding,
        delimiter=args.delimiter,
    )
    emitter = TableEmitter(writers, dedupe_keys=DEDUPE_KEYS)
    enums = EnumerationRegistry(emitter, args.reference_dir)
    register_enumerations(enums)

    merged_ids = load_merged_ids(args.snapshot)
    print()

    reader = SnapshotReader(args.snapshot)
    id_generator = StableIdGenerator()

    max_records = None if not args.max_records or args.max_records <= 0 else args.max_records
    max_files = args.max_files if args.max_files not in (None, 0) else None
    updated_dates = args.updated_dates

    overall_counts: Dict[str, int] = {}

    try:
        for entity in entities:
            dataset = ENTITY_DATASETS[entity]
            transformer = build_transformer(entity, emitter, enums, id_generator)
            reporter = ProgressReporter(entity, interval=max(args.progress_interval, 1))
            processed = 0
            skipped_merged = 0
            skip_ids = merged_ids.get(entity, set())
            try:
                for record in reader.iter_entity(
                    dataset,
                    updated_dates=updated_dates,
                    max_files=max_files,
                    max_records=max_records,
                    progress=reporter,
                ):
                    record_id = canonical_openalex_id(record.get("id")) if isinstance(record, dict) else None
                    if record_id and record_id in skip_ids:
                        skipped_merged += 1
                        continue
                    transformer.transform(record)
                    processed += 1
            except FileNotFoundError as exc:
                print(f"Skipping {entity}: {exc}")
                overall_counts[entity] = 0
                continue
            summary = reporter.summary()
            if skipped_merged:
                summary = f"{summary} (skipped {skipped_merged} merged ids)"
            print(summary)
            overall_counts[entity] = processed
    finally:
        writers.close()

    print("\nProcessing complete:")
    for entity in entities:
        count = overall_counts.get(entity, 0)
        print(f"  {entity}: {count} records processed")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
