"""Transformer for work entities."""
from __future__ import annotations

from collections import defaultdict
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

from ..emitter import TableEmitter
from ..identifiers import StableIdGenerator
from ..reference import EnumerationRegistry
from ..utils import (
    bool_from_flag,
    canonical_openalex_id,
    extract_numeric_id,
    normalise_language_code,
    numeric_openalex_id,
    parse_iso_date,
    parse_iso_datetime,
    safe_int,
)


def _normalise_doi(value: Optional[str]) -> Optional[str]:
    if not value:
        return None
    value = value.strip()
    if value.lower().startswith("https://doi.org/"):
        return value.split("/", 3)[-1]
    return value


def _abstract_from_inverted_index(index: Optional[Dict[str, Sequence[int]]]) -> Optional[str]:
    if not index:
        return None
    reverse: Dict[int, str] = {}
    for token, positions in index.items():
        for position in positions:
            reverse[position] = token
    if not reverse:
        return None
    text = " ".join(word for _, word in sorted(reverse.items()))
    return _normalise_text(text)


def _sdg_id_from_url(url: Optional[str]) -> Optional[int]:
    if not url:
        return None
    segment = url.rstrip("/").split("/")[-1]
    return safe_int(segment)


def _normalise_text(value: Optional[str]) -> Optional[str]:
    if not value:
        return None
    normalised = " ".join(value.replace("\r", " ").replace("\n", " ").replace("\t", " "))
    return normalised or None


class WorkTransformer:
    """Map OpenAlex work JSON documents to relational rows."""

    def __init__(
        self,
        emitter: TableEmitter,
        enums: EnumerationRegistry,
        id_generator: StableIdGenerator,
    ) -> None:
        self._emitter = emitter
        self._enums = enums
        self._ids = id_generator

    def transform(self, record: Dict[str, object]) -> None:
        work_id = numeric_openalex_id(record.get("id"))
        if work_id is None:
            return
        self._emit_work(work_id, record)
        self._emit_work_title(work_id, record)
        self._emit_work_abstract(work_id, record)
        self._emit_work_concepts(work_id, record)
        self._emit_work_topics(work_id, record)
        self._emit_work_sustainable_development_goals(work_id, record)
        self._emit_work_keywords(work_id, record)
        self._emit_work_mesh(work_id, record)
        self._emit_work_locations(work_id, record)
        affiliation_map = self._emit_work_affiliations(work_id, record)
        self._emit_work_authors(work_id, record, affiliation_map)
        self._emit_work_data_sources(work_id, record)
        self._emit_work_grants(work_id, record)
        self._emit_work_references(work_id, record)
        self._emit_work_related(work_id, record)
        # Work detail rows are populated downstream; skip emission during parsing.
        # self._emit_work_detail(work_id, record)

    def _emit_work(self, work_id: int, record: Dict[str, object]) -> None:
        type_name = (record.get("type") or "other").replace("_", "-")
        work_type_id = self._enums.id_for("work_type", type_name)
        crossref_type_name = record.get("type_crossref") or type_name
        crossref_work_type_id = self._enums.id_for("work_type", crossref_type_name)

        primary_location = record.get("primary_location") or {}
        source_id = self._extract_source_id(primary_location.get("source"))

        doi_registration_agency = record.get("doi_registration_agency")
        doi_registration_agency_id = (
            self._enums.id_for("doi_registration_agency", doi_registration_agency)
            if doi_registration_agency
            else None
        )

        ids = record.get("ids") or {}
        doi = _normalise_doi(ids.get("doi") or record.get("doi"))
        mag_id = safe_int(ids.get("mag"))
        pmid = extract_numeric_id(ids.get("pmid"))
        pmcid = extract_numeric_id(ids.get("pmcid"))
        arxiv_id = canonical_openalex_id(ids.get("arxiv"))

        language = normalise_language_code(record.get("language"))
        is_paratext = bool_from_flag(record.get("is_paratext"))
        is_retracted = bool_from_flag(record.get("is_retracted"))

        open_access = record.get("open_access") or {}
        is_oa = bool_from_flag(open_access.get("is_oa"))
        any_repo = bool_from_flag(open_access.get("any_repository_has_fulltext"))
        oa_status_id = self._enums.id_for("oa_status", open_access.get("oa_status"))
        oa_url = open_access.get("oa_url")

        apc_list = record.get("apc_list") or {}
        apc_paid = record.get("apc_paid") or {}

        apc_list_provenance_id = self._enums.id_for("apc_provenance", apc_list.get("provenance"))
        apc_paid_provenance_id = self._enums.id_for("apc_provenance", apc_paid.get("provenance"))

        fulltext_origin_id = self._enums.id_for("fulltext_origin", record.get("fulltext_origin"))

        biblio = record.get("biblio") or {}
        work_row = {
            "work_id": work_id,
            "work_type_id": work_type_id,
            "crossref_work_type_id": crossref_work_type_id,
            "source_id": source_id,
            "pub_date": parse_iso_date(record.get("publication_date")),
            "pub_year": record.get("publication_year"),
            "volume": biblio.get("volume"),
            "issue": biblio.get("issue"),
            "page_first": biblio.get("first_page"),
            "page_last": biblio.get("last_page"),
            "doi_registration_agency_id": doi_registration_agency_id,
            "doi": doi,
            "openalex_id": canonical_openalex_id(record.get("id")),
            "mag_id": mag_id,
            "pmid": pmid,
            "pmcid": pmcid,
            "arxiv_id": arxiv_id,
            "language_iso2_code": language,
            "is_paratext": is_paratext,
            "is_retracted": is_retracted,
            "is_oa": is_oa,
            "any_repository_has_fulltext": any_repo,
            "oa_status_id": oa_status_id,
            "oa_url": oa_url,
            "apc_list_currency": apc_list.get("currency"),
            "apc_list_price": apc_list.get("value"),
            "apc_list_price_usd": apc_list.get("value_usd"),
            "apc_list_apc_provenance_id": apc_list_provenance_id,
            "apc_paid_currency": apc_paid.get("currency"),
            "apc_paid_price": apc_paid.get("value"),
            "apc_paid_price_usd": apc_paid.get("value_usd"),
            "apc_paid_apc_provenance_id": apc_paid_provenance_id,
            "fulltext_origin_id": fulltext_origin_id,
            "n_refs": record.get("referenced_works_count"),
            "n_cits": record.get("cited_by_count"),
            "updated_date": parse_iso_datetime(record.get("updated_date")),
            "created_date": parse_iso_date(record.get("created_date")),
        }
        self._emitter.emit("work", work_row)

    def _emit_work_title(self, work_id: int, record: Dict[str, object]) -> None:
        title = record.get("title") or record.get("display_name")
        title = _normalise_text(title)
        if title:
            self._emitter.emit("work_title", {"work_id": work_id, "title": title})

    def _emit_work_abstract(self, work_id: int, record: Dict[str, object]) -> None:
        abstract_text = _abstract_from_inverted_index(record.get("abstract_inverted_index"))
        if abstract_text:
            self._emitter.emit("work_abstract", {"work_id": work_id, "abstract": abstract_text})

    def _emit_work_concepts(self, work_id: int, record: Dict[str, object]) -> None:
        concepts = record.get("concepts") or []
        for idx, concept in enumerate(concepts, start=1):
            concept_id = numeric_openalex_id(concept.get("id"))
            if concept_id is None:
                continue
            self._emitter.emit(
                "work_concept",
                {
                    "work_id": work_id,
                    "concept_seq": idx,
                    "concept_id": concept_id,
                    "score": concept.get("score"),
                },
            )

    def _emit_work_topics(self, work_id: int, record: Dict[str, object]) -> None:
        topics = record.get("topics") or []
        for idx, topic in enumerate(topics, start=1):
            topic_id = numeric_openalex_id(topic.get("id"))
            if topic_id is None:
                continue
            self._emitter.emit(
                "work_topic",
                {
                    "work_id": work_id,
                    "topic_seq": idx,
                    "topic_id": topic_id,
                    "score": topic.get("score"),
                },
            )

    def _emit_work_sustainable_development_goals(self, work_id: int, record: Dict[str, object]) -> None:
        goals = record.get("sustainable_development_goals") or []
        for idx, goal in enumerate(goals, start=1):
            taxonomy_url = goal.get("id")
            goal_id = _sdg_id_from_url(taxonomy_url)
            self._emitter.emit(
                "work_sustainable_development_goal",
                {
                    "work_id": work_id,
                    "sustainable_development_goal_seq": idx,
                    "sustainable_development_goal_id": goal_id,
                    "score": goal.get("score"),
                },
            )
            if goal_id is not None:
                self._emitter.emit(
                    "sustainable_development_goal",
                    {
                        "sustainable_development_goal_id": goal_id,
                        "sustainable_development_goal": goal.get("display_name"),
                        "taxonomy_url": taxonomy_url,
                    },
                )

    def _emit_work_keywords(self, work_id: int, record: Dict[str, object]) -> None:
        keywords = record.get("keywords") or []
        for idx, keyword in enumerate(keywords, start=1):
            key = keyword.get("keyword") or keyword.get("display_name")
            if not key:
                continue
            stable_id = self._ids.generate("keyword", key, bits=30)
            self._emitter.emit("keyword", {"keyword_id": stable_id, "keyword": key})
            self._emitter.emit(
                "work_keyword",
                {
                    "work_id": work_id,
                    "keyword_seq": idx,
                    "keyword_id": stable_id,
                    "score": keyword.get("score"),
                },
            )

    def _emit_work_mesh(self, work_id: int, record: Dict[str, object]) -> None:
        mesh_entries = record.get("mesh") or []
        for idx, entry in enumerate(mesh_entries, start=1):
            descriptor_ui = entry.get("descriptor_ui")
            descriptor_name = entry.get("descriptor_name")
            if descriptor_ui and descriptor_name:
                self._emitter.emit(
                    "mesh_descriptor",
                    {"mesh_descriptor_ui": descriptor_ui, "mesh_descriptor": descriptor_name},
                )
            qualifier_ui = entry.get("qualifier_ui")
            qualifier_name = entry.get("qualifier_name")
            if qualifier_ui and qualifier_name:
                self._emitter.emit(
                    "mesh_qualifier",
                    {"mesh_qualifier_ui": qualifier_ui, "mesh_qualifier": qualifier_name},
                )
            self._emitter.emit(
                "work_mesh",
                {
                    "work_id": work_id,
                    "mesh_seq": idx,
                    "mesh_descriptor_ui": descriptor_ui,
                    "mesh_qualifier_ui": qualifier_ui,
                    "is_major_topic": bool_from_flag(entry.get("is_major_topic")),
                },
            )

    def _emit_work_locations(self, work_id: int, record: Dict[str, object]) -> None:
        locations = record.get("locations") or []
        primary = record.get("primary_location") or {}
        best_oa = record.get("best_oa_location") or {}

        for idx, location in enumerate(locations, start=1):
            source_id = self._extract_source_id(location.get("source"))
            version_value = location.get("version")
            version_id = self._enums.id_for("version", version_value)
            license_id = self._enums.id_for("license", location.get("license"))
            version_lower = (version_value or "").lower()
            self._emitter.emit(
                "work_location",
                {
                    "work_id": work_id,
                    "location_seq": idx,
                    "is_primary_location": int(location == primary),
                    "is_best_oa_location": int(location == best_oa),
                    "source_id": source_id,
                    "landing_page_url": location.get("landing_page_url"),
                    "pdf_url": location.get("pdf_url"),
                    "version_id": version_id,
                    "license_id": license_id,
                    "is_oa": bool_from_flag(location.get("is_oa")),
                    "is_accepted": int(version_lower == "acceptedversion"),
                    "is_published": int(version_lower == "publishedversion"),
                },
            )

    def _emit_work_affiliations(self, work_id: int, record: Dict[str, object]) -> Dict[str, int]:
        affiliation_seq: Dict[str, int] = {}
        authorships = record.get("authorships") or []
        for authorship in authorships:
            raw_list = self._extract_affiliation_strings(authorship)
            for raw in raw_list:
                if raw not in affiliation_seq:
                    raw_id = self._ids.generate("raw_affiliation_string", raw, bits=40)
                    seq = len(affiliation_seq) + 1
                    affiliation_seq[raw] = seq
                    self._emitter.emit(
                        "raw_affiliation_string",
                        {"raw_affiliation_string_id": raw_id, "raw_affiliation_string": raw},
                    )
                    self._emitter.emit(
                        "work_affiliation",
                        {"work_id": work_id, "affiliation_seq": seq, "raw_affiliation_string_id": raw_id},
                    )
        return affiliation_seq

    def _emit_work_authors(
        self,
        work_id: int,
        record: Dict[str, object],
        affiliation_seq: Dict[str, int],
    ) -> None:
        authorships = record.get("authorships") or []
        inst_seen: Dict[int, List[int]] = defaultdict(list)
        for idx, authorship in enumerate(authorships, start=1):
            author = authorship.get("author") or {}
            author_id = numeric_openalex_id(author.get("id"))
            raw_name_value = authorship.get("raw_author_name") or author.get("display_name")
            normalised_raw_name = _normalise_text(raw_name_value)
            raw_id = None
            if normalised_raw_name:
                raw_id = self._ids.generate("raw_author_name", normalised_raw_name, bits=48)
                self._emitter.emit(
                    "raw_author_name",
                    {"raw_author_name_id": raw_id, "raw_author_name": normalised_raw_name},
                )

            author_position_id = self._enums.id_for("author_position", authorship.get("author_position"))
            self._emitter.emit(
                "work_author",
                {
                    "work_id": work_id,
                    "author_seq": idx,
                    "author_id": author_id,
                    "author_position_id": author_position_id,
                    "is_corresponding_author": bool_from_flag(authorship.get("is_corresponding")),
                    "raw_author_name_id": raw_id,
                },
            )

            raw_strings = self._extract_affiliation_strings(authorship)
            for raw in raw_strings:
                seq = affiliation_seq.get(raw)
                if seq is None:
                    continue
                self._emitter.emit(
                    "work_author_affiliation",
                    {"work_id": work_id, "author_seq": idx, "affiliation_seq": seq},
                )

            self._emit_work_affiliation_institution_links(
                work_id, authorship, affiliation_seq, inst_seen
            )

            countries = authorship.get("countries") or []
            for c_idx, country_code in enumerate(countries, start=1):
                if country_code:
                    self._emitter.emit(
                        "work_author_country",
                        {
                            "work_id": work_id,
                            "author_seq": idx,
                            "country_seq": c_idx,
                            "country_iso_alpha2_code": country_code,
                        },
                    )

    def _emit_work_affiliation_institution_links(
        self,
        work_id: int,
        authorship: Dict[str, object],
        affiliation_seq: Dict[str, int],
        inst_seen: Dict[int, List[int]],
    ) -> None:
        institutions = authorship.get("institutions") or []
        if not institutions:
            return
        raw_strings = self._extract_affiliation_strings(authorship)
        pairs: List[Tuple[str, Dict[str, object]]] = []
        if raw_strings and len(raw_strings) == len(institutions):
            pairs = list(zip(raw_strings, institutions))
        elif raw_strings and len(raw_strings) == 1:
            pairs = [(raw_strings[0], inst) for inst in institutions]
        elif raw_strings:
            for idx, inst in enumerate(institutions):
                pairs.append((raw_strings[min(idx, len(raw_strings) - 1)], inst))
        else:
            for inst in institutions:
                label = inst.get("display_name")
                if label:
                    pairs.append((label, inst))

        grouped: Dict[int, List[Dict[str, object]]] = defaultdict(list)
        for raw, inst in pairs:
            seq = affiliation_seq.get(raw)
            if seq is None:
                continue
            grouped[seq].append(inst)

        for seq, inst_list in grouped.items():
            seen_for_seq = inst_seen[seq]
            for inst in inst_list:
                inst_id = numeric_openalex_id(inst.get("id"))
                if inst_id is None or inst_id in seen_for_seq:
                    continue
                seen_for_seq.append(inst_id)
                self._emitter.emit(
                    "work_affiliation_institution",
                    {
                        "work_id": work_id,
                        "affiliation_seq": seq,
                        "institution_seq": len(seen_for_seq),
                        "institution_id": inst_id,
                    },
                )

    def _emit_work_data_sources(self, work_id: int, record: Dict[str, object]) -> None:
        data_sources = []
        ids = record.get("ids") or {}
        doi_agency = (record.get("doi_registration_agency") or "").lower()
        if ids.get("arxiv"):
            data_sources.append("arxiv")
        if ids.get("pmid") or ids.get("pmcid"):
            data_sources.append("pubmed")
        if doi_agency == "datacite":
            data_sources.append("datacite")
        elif doi_agency:
            data_sources.append("crossref")
        best_source = (record.get("best_oa_location") or {}).get("source") or {}
        primary_source = (record.get("primary_location") or {}).get("source") or {}
        if best_source.get("is_in_doaj") or primary_source.get("is_in_doaj"):
            data_sources.append("doaj")

        seen = set()
        for idx, source_name in enumerate(data_sources, start=1):
            if source_name in seen:
                continue
            seen.add(source_name)
            data_source_id = self._enums.id_for("data_source", source_name)
            self._emitter.emit(
                "work_data_source",
                {
                    "work_id": work_id,
                    "data_source_seq": idx,
                    "data_source_id": data_source_id,
                },
            )

    def _emit_work_grants(self, work_id: int, record: Dict[str, object]) -> None:
        grants = record.get("grants") or []
        for idx, grant in enumerate(grants, start=1):
            funder_id = numeric_openalex_id(grant.get("funder"))
            self._emitter.emit(
                "work_grant",
                {
                    "work_id": work_id,
                    "grant_seq": idx,
                    "award_id": grant.get("award_id"),
                    "funder_id": funder_id,
                },
            )

    def _emit_work_references(self, work_id: int, record: Dict[str, object]) -> None:
        references = record.get("referenced_works") or []
        for idx, reference in enumerate(references, start=1):
            cited_id = numeric_openalex_id(reference)
            self._emitter.emit(
                "work_reference",
                {"work_id": work_id, "reference_seq": idx, "cited_work_id": cited_id},
            )
            # Citations are generated post-load, so skip emitting them during parsing.
            # self._emitter.emit(
            #     "citation",
            #     {
            #         "citing_work_id": work_id,
            #         "reference_seq": idx,
            #         "cited_work_id": cited_id,
            #         "pub_year": None,
            #         "cit_window": None,
            #         "is_self_cit": None,
            #     },
            # )

    def _emit_work_related(self, work_id: int, record: Dict[str, object]) -> None:
        related = record.get("related_works") or []
        for idx, related_id in enumerate(related, start=1):
            self._emitter.emit(
                "work_related",
                {
                    "work_id": work_id,
                    "related_work_seq": idx,
                    "related_work_id": numeric_openalex_id(related_id),
                },
            )

    def _emit_work_detail(self, work_id: int, record: Dict[str, object]) -> None:
        authorships = record.get("authorships") or []
        first_author = authorships[0] if authorships else None
        other_authors = authorships[1:] if len(authorships) > 1 else []

        author_first = None
        if first_author:
            author_first = (
                first_author.get("raw_author_name")
                or (first_author.get("author") or {}).get("display_name")
            )
        other_names = [
            auth.get("raw_author_name") or (auth.get("author") or {}).get("display_name")
            for auth in other_authors
            if auth.get("raw_author_name") or (auth.get("author") or {}).get("display_name")
        ]
        if len(other_names) > 4:
            other_names = other_names[:3] + ["..."] + [other_names[-1]]
        author_et_al = "; ".join(other_names)

        first_institution = None
        institution_et_al = ""
        if first_author:
            institutions = first_author.get("institutions") or []
            if institutions:
                first_institution = institutions[0].get("display_name")
                if len(institutions) > 1:
                    institution_et_al = "; ".join(
                        filter(None, [inst.get("display_name") for inst in institutions[1:]])
                    )

        biblio = record.get("biblio") or {}
        pages = None
        if biblio.get("first_page") and biblio.get("last_page"):
            pages = f"{biblio['first_page']}-{biblio['last_page']}"
        elif biblio.get("first_page"):
            pages = biblio.get("first_page")

        ids = record.get("ids") or {}
        title_value = _normalise_text(record.get("title") or record.get("display_name"))
        # Work detail rows are generated downstream, so skip emitting them during parsing.
        # self._emitter.emit(
        #     "work_detail",
        #     {
        #         "work_id": work_id,
        #         "author_first": author_first,
        #         "author_et_al": author_et_al,
        #         "institution_first": first_institution,
        #         "institution_et_al": institution_et_al,
        #         "title": title_value,
        #         "source": ((record.get("primary_location") or {}).get("source") or {}).get("display_name"),
        #         "pub_year": record.get("publication_year"),
        #         "volume": biblio.get("volume"),
        #         "issue": biblio.get("issue"),
        #         "pages": pages,
        #         "doi": _normalise_doi(ids.get("doi") or record.get("doi")),
        #         "pmid": extract_numeric_id(ids.get("pmid")),
        #         "work_type": record.get("type"),
        #         "n_cits": record.get("cited_by_count"),
        #         "n_self_cits": None,
        #     },
        # )

    @staticmethod
    def _extract_source_id(source: Optional[Dict[str, object]]) -> Optional[int]:
        if not source:
            return None
        return numeric_openalex_id(source.get("id"))

    @staticmethod
    def _extract_affiliation_strings(authorship: Dict[str, object]) -> List[str]:
        raw_strings = authorship.get("raw_affiliation_strings") or []
        cleaned = []
        for value in raw_strings:
            normalised = _normalise_text(value)
            if normalised:
                cleaned.append(normalised)
        if cleaned:
            return cleaned
        raw = authorship.get("raw_affiliation_string")
        if raw:
            parts = []
            for part in raw.replace("\r", " ").replace("\n", " ").split(";"):
                normalised = _normalise_text(part)
                if normalised:
                    parts.append(normalised)
            if parts:
                return parts
        return []


__all__ = ["WorkTransformer"]
