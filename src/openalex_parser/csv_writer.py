"""CSV writing helpers aligned with the CWTS schema column ordering."""
from __future__ import annotations

import csv
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path
from typing import Any, Dict, Iterable, Mapping

from .schema import TableDefinition


def _format_cell(value: Any) -> Any:
    """Coerce Python values into CSV-friendly representations."""

    if value is None:
        return ""
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    if isinstance(value, Decimal):
        return format(value, "f")
    return value


class CsvTableWriter:
    """Writer responsible for a single table."""

    def __init__(self, table: TableDefinition, path: Path) -> None:
        self.table = table
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._handle = self.path.open("w", newline="\n", encoding="utf-8")
        self._handle.write("\ufeff")
        self._writer = csv.writer(self._handle, lineterminator="\n")
        self._writer.writerow(self.table.column_names)

    def write_row(self, row: Mapping[str, Any]) -> None:
        """Write a single row adhering to the table's column order."""

        ordered_values = [_format_cell(row.get(column)) for column in self.table.column_names]
        self._writer.writerow(ordered_values)

    def write_rows(self, rows: Iterable[Mapping[str, Any]]) -> None:
        for row in rows:
            self.write_row(row)

    def close(self) -> None:
        self._handle.close()

    def __enter__(self) -> "CsvTableWriter":
        return self

    def __exit__(self, *_exc_info: object) -> None:
        self.close()


class CsvWriterManager:
    """Manage multiple CSV writers keyed by table name."""

    def __init__(self, table_definitions: Mapping[str, TableDefinition], output_dir: Path) -> None:
        self._table_definitions = dict(table_definitions)
        self._output_dir = output_dir
        self._writers: Dict[str, CsvTableWriter] = {}

    def writer_for(self, table_name: str) -> CsvTableWriter:
        try:
            return self._writers[table_name]
        except KeyError:
            table = self._table_definitions[table_name]
            path = self._output_dir / f"{table.name}.csv"
            writer = CsvTableWriter(table=table, path=path)
            self._writers[table_name] = writer
            return writer

    def write_row(self, table_name: str, row: Mapping[str, Any]) -> None:
        self.writer_for(table_name).write_row(row)

    def write_rows(self, table_name: str, rows: Iterable[Mapping[str, Any]]) -> None:
        self.writer_for(table_name).write_rows(rows)

    def close(self) -> None:
        for writer in self._writers.values():
            writer.close()
        self._writers.clear()

    def __enter__(self) -> "CsvWriterManager":
        return self

    def __exit__(self, *_exc_info: object) -> None:
        self.close()


__all__ = ["CsvTableWriter", "CsvWriterManager"]
