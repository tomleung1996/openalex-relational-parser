from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

BASE_DIR = Path(__file__).resolve().parents[1]
sys.path.append(str(BASE_DIR))

from openalex_parser.schema import load_schema

SCHEMA_PATH = Path('data/reference/openalex_cwts_schema.sql')
OUTPUT_DIR = Path('sqlserver')

TYPE_MAP = {
    'int2': 'smallint',
    'int4': 'int',
    'int8': 'bigint',
    'float4': 'real',
    'float8': 'float',
    'bool': 'bit',
    'timestamp': 'datetime2',
    'date': 'date',
}


def normalise_identifier(value: str) -> str:
    value = value.strip().strip('"')
    return value


def map_type(pg_type: str) -> str:
    pg_type = pg_type.lower()
    if pg_type in TYPE_MAP:
        return TYPE_MAP[pg_type]
    if pg_type.startswith('varchar'):
        return pg_type.replace('varchar', 'nvarchar')
    if pg_type.startswith('bpchar'):
        return pg_type.replace('bpchar', 'nchar')
    if pg_type == 'text':
        return 'nvarchar(max)'
    if pg_type.startswith('numeric'):
        return pg_type  # numeric precision preserved
    if pg_type.startswith('timestamp'):
        return 'datetime2'
    raise ValueError(f"Unhandled PostgreSQL type: {pg_type}")


def parse_constraints_and_indexes() -> Tuple[Dict[str, List[Tuple[str, List[str]]]], List[Tuple[str, str, List[str]]]]:
    primary_keys: Dict[str, List[Tuple[str, List[str]]]] = {}
    indexes: List[Tuple[str, str, List[str]]] = []  # (index_name, table_name, columns)

    current_table: str | None = None
    with SCHEMA_PATH.open(encoding='utf-8') as handle:
        for raw_line in handle:
            line = raw_line.strip()
            table_match = re.match(r'CREATE TABLE public\.(["A-Za-z0-9_]+)\s*\(', line)
            if table_match:
                current_table = normalise_identifier(table_match.group(1))
                continue
            if current_table and line.startswith('CONSTRAINT') and 'PRIMARY KEY' in line:
                constr_match = re.match(r'CONSTRAINT\s+([A-Za-z0-9_]+)\s+PRIMARY KEY\s*\(([^)]+)\)', line)
                if constr_match:
                    constraint = constr_match.group(1)
                    cols = [normalise_identifier(col) for col in constr_match.group(2).split(',')]
                    primary_keys.setdefault(current_table, []).append((constraint, cols))
                continue
            if current_table and line.startswith(')'):
                current_table = None
                continue
            idx_match = re.match(r'CREATE\s+(?:UNIQUE\s+)?INDEX\s+([A-Za-z0-9_]+)\s+ON\s+public\.(["A-Za-z0-9_]+)\s+USING\s+\w+\s*\(([^)]+)\);', line)
            if idx_match:
                index_name = idx_match.group(1)
                table_name = normalise_identifier(idx_match.group(2))
                columns = [normalise_identifier(col) for col in idx_match.group(3).split(',')]
                indexes.append((index_name, table_name, columns))
    return primary_keys, indexes


def render_columns(raw_definition: str) -> Tuple[str, str, bool]:
    parts = raw_definition.split()
    column_name = normalise_identifier(parts[0])
    type_part = parts[1]
    rest = ' '.join(parts[2:]) if len(parts) > 2 else ''

    sql_type = map_type(type_part)
    nullable = 'NOT NULL' in rest.upper()
    return column_name, sql_type, nullable


def generate_create_tables() -> str:
    schema = load_schema(SCHEMA_PATH)
    lines: List[str] = []
    for table_name, table in schema.items():
        lines.append(f'DROP TABLE IF EXISTS [dbo].[{table_name}];')
        lines.append('GO')
        lines.append(f'CREATE TABLE [dbo].[{table_name}] (')
        column_lines = []
        for column in table.columns:
            col_name, col_type, not_null = render_columns(column.raw_definition)
            null_spec = 'NOT NULL' if not_null else 'NULL'
            column_lines.append(f'    [{col_name}] {col_type} {null_spec}')
        lines.append(',\n'.join(column_lines))
        lines.append(');')
        lines.append('GO')
        lines.append('')
    return '\n'.join(lines)


def generate_primary_keys(primary_keys: Dict[str, List[Tuple[str, List[str]]]]) -> str:
    lines: List[str] = []
    for table, constraints in primary_keys.items():
        for constraint, columns in constraints:
            cols = ', '.join(f'[{col}]' for col in columns)
            lines.append(f'ALTER TABLE [dbo].[{table}] ADD CONSTRAINT [{constraint}] PRIMARY KEY ({cols});')
            lines.append('GO')
            lines.append('')
    return '\n'.join(lines)


def generate_indexes(indexes: List[Tuple[str, str, List[str]]]) -> str:
    lines: List[str] = []
    for index_name, table, columns in indexes:
        cols = ', '.join(f'[{col}]' for col in columns)
        lines.append(f'CREATE INDEX [{index_name}] ON [dbo].[{table}] ({cols});')
        lines.append('GO')
        lines.append('')
    return '\n'.join(lines)


def generate_bulk_insert(tables: List[str]) -> str:
    lines: List[str] = []
    lines.append("DECLARE @BasePath nvarchar(4000) = N'/Path/To/CSV'; -- TODO: update this path")
    lines.append("DECLARE @Sql nvarchar(max);")
    lines.append("")
    for table in tables:
        csv_file = f"{table}.csv"
        lines.append(f"-- Load data for {table}")
        lines.append(f"SET @Sql = N'BULK INSERT [dbo].[{table}] FROM ''' + @BasePath + N'/{csv_file}'' WITH (FORMAT=''CSV'', DATAFILETYPE = ''widechar'', FIRSTROW = 2, DELIMITER = ''\t'', TABLOCK);'")
        lines.append("EXEC (@Sql);")
        lines.append("")
        lines.append("-- If files are compressed (.csv.gz), decompress them before running this command.")
        lines.append("")
    return '\n'.join(lines)


def generate_bcp_commands(tables: List[str]) -> str:
    lines: List[str] = []
    lines.append("@echo off")
    lines.append("setlocal enableextensions")
    lines.append("REM Update the variables below before running.")
    lines.append("set \"SERVER=localhost\"")
    lines.append("set \"DATABASE=openalex\"")
    lines.append("set \"BASE_PATH=C:\\Path\\To\\CSV\"")
    lines.append("set \"USERNAME=sql_user\"")
    lines.append("set \"PASSWORD=StrongPassword!\"")
    lines.append("set \"ERROR_DIR=%BASE_PATH%\\errors\"")
    lines.append("set \"FIELD_TERMINATOR=\\t\"")
    lines.append("set \"ROW_TERMINATOR=\\n\"")
    lines.append("set \"CODE_PAGE=65001\"")
    lines.append("set \"BATCH_SIZE=100000\"")
    lines.append("")
    lines.append("if not exist \"%BASE_PATH%\" (")
    lines.append("    echo Base path \"%BASE_PATH%\" does not exist.")
    lines.append("    exit /b 1")
    lines.append(")")
    lines.append("")
    lines.append("if /I \"%FIELD_TERMINATOR%\"==\"\\t\" set \"FIELD_TERMINATOR=0x09\"")
    lines.append("if /I \"%FIELD_TERMINATOR%\"==\"\\n\" set \"FIELD_TERMINATOR=0x0a\"")
    lines.append("if /I \"%FIELD_TERMINATOR%\"==\"\\r\" set \"FIELD_TERMINATOR=0x0d\"")
    lines.append("if /I \"%FIELD_TERMINATOR%\"==\"\\r\\n\" set \"FIELD_TERMINATOR=0x0d0a\"")
    lines.append("if /I \"%ROW_TERMINATOR%\"==\"\\t\" set \"ROW_TERMINATOR=0x09\"")
    lines.append("if /I \"%ROW_TERMINATOR%\"==\"\\n\" set \"ROW_TERMINATOR=0x0a\"")
    lines.append("if /I \"%ROW_TERMINATOR%\"==\"\\r\" set \"ROW_TERMINATOR=0x0d\"")
    lines.append("if /I \"%ROW_TERMINATOR%\"==\"\\r\\n\" set \"ROW_TERMINATOR=0x0d0a\"")
    lines.append("set \"BCP_CODE_PAGE_OPT=\"")
    lines.append("if not \"%CODE_PAGE%\"==\"\" set \"BCP_CODE_PAGE_OPT=-C %CODE_PAGE%\"")
    lines.append("")
    lines.append("if not exist \"%ERROR_DIR%\" mkdir \"%ERROR_DIR%\"")
    lines.append("")
    lines.append("REM If files are compressed (.csv.gz), decompress them before running this script.")
    lines.append("")
    for table in tables:
        csv_file = f"{table}.csv"
        lines.append(f"echo Importing {table}")
        lines.append(f"bcp \"%DATABASE%.dbo.{table}\" in \"%BASE_PATH%\\{csv_file}\" -S \"%SERVER%\" -U \"%USERNAME%\" -P \"%PASSWORD%\" -c %BCP_CODE_PAGE_OPT% -b %BATCH_SIZE% -t %FIELD_TERMINATOR% -r %ROW_TERMINATOR% -F 2 -m 1 -e \"%ERROR_DIR%\\{table}.err\"")
        lines.append("if errorlevel 1 exit /b %errorlevel%")
        lines.append("")
    lines.append("echo BCP import completed.")
    lines.append("endlocal")
    return '\n'.join(lines)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    primary_keys, indexes = parse_constraints_and_indexes()
    schema = load_schema(SCHEMA_PATH)
    table_names = list(schema.keys())

    (OUTPUT_DIR / '1.create_tables.sql').write_text(generate_create_tables(), encoding='utf-8')
    (OUTPUT_DIR / '2.bulk_load.sql').write_text(generate_bulk_insert(table_names), encoding='utf-8')
    (OUTPUT_DIR / '2.bulk_load_bcp.cmd').write_text(generate_bcp_commands(table_names), encoding='utf-8')
    print('SQL Server scripts generated under', OUTPUT_DIR)
    (OUTPUT_DIR / '3.create_indexes.sql').write_text(generate_primary_keys(primary_keys) + '\n' + generate_indexes(indexes), encoding='utf-8')


if __name__ == '__main__':
    main()




