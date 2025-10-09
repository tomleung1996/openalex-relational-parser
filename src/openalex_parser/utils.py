"""General utility helpers for OpenAlex parsing."""
from __future__ import annotations

import re
from datetime import datetime
from typing import Any, Mapping, Optional

ISO_DATE_FORMATS = ["%Y-%m-%dT%H:%M:%S.%f", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%d"]


def canonical_openalex_id(identifier: Optional[str]) -> Optional[str]:
    """Normalise OpenAlex identifiers (either URL or short form)."""

    if not identifier:
        return None
    identifier = identifier.strip()
    if identifier.startswith("https://openalex.org/"):
        identifier = identifier.split("/", maxsplit=3)[-1]
    return identifier or None


def numeric_openalex_id(identifier: Optional[str]) -> Optional[int]:
    """Extract the numeric component from an OpenAlex identifier."""

    short_id = canonical_openalex_id(identifier)
    if not short_id:
        return None
    for index, char in enumerate(short_id):
        if char.isdigit():
            return int(short_id[index:])
    return None


def lookup_id(ids: Mapping[str, Any], key: str) -> Optional[str]:
    """Look up a value from an OpenAlex ids mapping in a safe way."""

    value = ids.get(key)
    if value is None:
        return None
    if isinstance(value, str):
        return value.strip() or None
    return str(value)


def parse_iso_datetime(value: Optional[str]) -> Optional[str]:
    """Coerce timestamps to ISO8601 date/time strings."""

    if not value:
        return None
    for fmt in ISO_DATE_FORMATS:
        try:
            dt = datetime.strptime(value, fmt)
            return dt.date().isoformat()
            # if fmt == "%Y-%m-%d":
            #     return dt.date().isoformat()
            # return dt.isoformat()
        except ValueError:
            continue
    return value


def parse_iso_date(value: Optional[str]) -> Optional[str]:
    """Return YYYY-MM-DD if possible."""

    parsed = parse_iso_datetime(value)
    if parsed and len(parsed) >= 10:
        return parsed[:10]
    return parsed


def safe_int(value: Any) -> Optional[int]:
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def extract_numeric_id(value: Any) -> Optional[int]:
    """Extract the dominant numeric identifier from a string or URL."""

    if value is None:
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, float) and value.is_integer():
        return int(value)

    value_str = str(value).strip()
    if not value_str:
        return None

    # Try direct coercion (covers integer-like strings).
    try:
        return int(value_str)
    except ValueError:
        pass

    numbers = re.findall(r"\d+", value_str)
    if not numbers:
        return None

    significant = [num for num in numbers if len(num) >= 3] or numbers

    best = significant[0]
    best_len = len(best)
    for num in significant[1:]:
        num_len = len(num)
        if num_len > best_len or (num_len == best_len):
            best = num
            best_len = num_len

    try:
        return int(best)
    except ValueError:
        return None


def normalise_language_code(value: Optional[str]) -> Optional[str]:
    """Return the first two lowercase characters of a language string."""

    if value is None:
        return None
    value_str = value[:2].lower()
    return value_str or None


def safe_float(value: Any) -> Optional[float]:
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def bool_from_flag(value: Any) -> Optional[bool]:
    if value is None:
        return None
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return bool(value)
    value_str = str(value).strip().lower()
    if value_str in {"true", "t", "1", "yes", "y"}:
        return True
    if value_str in {"false", "f", "0", "no", "n"}:
        return False
    return None


__all__ = [
    "canonical_openalex_id",
    "numeric_openalex_id",
    "lookup_id",
    "parse_iso_date",
    "parse_iso_datetime",
    "safe_int",
    "safe_float",
    "bool_from_flag",
    "extract_numeric_id",
    "normalise_language_code",
]



def canonical_wikidata_id(value: Optional[str]) -> Optional[str]:
    """Return the terminal Wikidata identifier (e.g. Q123) from a URL."""

    if not value:
        return None
    value = value.strip()
    if not value:
        return None
    if '/' in value:
        value = value.rstrip('/')
        value = value.split('/')[-1]
    return value or None


def canonical_orcid(value: Optional[str]) -> Optional[str]:
    """Return bare ORCID (0000-0000-0000-0000) when provided as URL."""

    if not value:
        return None
    value = value.strip()
    if not value:
        return None
    if value.lower().startswith('https://orcid.org/'):
        value = value.split('/', 3)[-1]
    return value or None


def extract_scopus_author_id(value: Optional[str]) -> Optional[int]:
    """Extract the numerical Scopus author id from assorted identifier formats."""

    if not value:
        return None
    value = value.strip()
    if not value:
        return None
    import re

    match = re.search(r'(?:authorID=)?(\d{5,})', value)
    if match:
        try:
            return int(match.group(1))
        except ValueError:
            return None
    try:
        return int(value)
    except ValueError:
        return None


__all__.extend([
    'canonical_wikidata_id',
    'canonical_orcid',
    'extract_scopus_author_id',
])
