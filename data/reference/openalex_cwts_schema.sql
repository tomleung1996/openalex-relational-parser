-- public.apc_provenance definition

-- Drop table

-- DROP TABLE public.apc_provenance;

CREATE TABLE public.apc_provenance (
	apc_provenance_id int2 NOT NULL,
	apc_provenance varchar(20) NULL,
	CONSTRAINT apc_provenance_pkey PRIMARY KEY (apc_provenance_id)
);
CREATE INDEX idx_apc_provenance_name ON public.apc_provenance USING btree (apc_provenance);


-- public.author definition

-- Drop table

-- DROP TABLE public.author;

CREATE TABLE public.author (
	author_id int8 NOT NULL,
	author text NULL,
	orcid bpchar(19) NULL,
	openalex_id varchar(11) NULL,
	scopus_id int8 NULL,
	wikipedia_url varchar(200) NULL,
	updated_date timestamp NULL,
	created_date timestamp NULL,
	CONSTRAINT author_pkey PRIMARY KEY (author_id)
);
CREATE INDEX idx_author_name ON public.author USING btree (author);
CREATE INDEX idx_author_openalex_id ON public.author USING btree (openalex_id);
CREATE INDEX idx_author_orcid ON public.author USING btree (orcid);
CREATE INDEX idx_author_updated_date ON public.author USING btree (updated_date);


-- public.author_alternative_name definition

-- Drop table

-- DROP TABLE public.author_alternative_name;

CREATE TABLE public.author_alternative_name (
	author_id int8 NOT NULL,
	alternative_name_seq int2 NOT NULL,
	alternative_name varchar(255) NULL,
	CONSTRAINT author_alternative_name_pkey PRIMARY KEY (author_id, alternative_name_seq)
);
CREATE INDEX idx_author_alt_name ON public.author_alternative_name USING btree (alternative_name);


-- public.author_institution definition

-- Drop table

-- DROP TABLE public.author_institution;

CREATE TABLE public.author_institution (
	author_id int8 NOT NULL,
	institution_seq int2 NOT NULL,
	institution_id int8 NULL,
	CONSTRAINT author_institution_pkey PRIMARY KEY (author_id, institution_seq)
);
CREATE INDEX idx_author_institution_inst_id ON public.author_institution USING btree (institution_id);


-- public.author_institution_year definition

-- Drop table

-- DROP TABLE public.author_institution_year;

CREATE TABLE public.author_institution_year (
	author_id int8 NOT NULL,
	institution_seq int2 NOT NULL,
	year_seq int2 NOT NULL,
	"year" int2 NULL,
	CONSTRAINT author_institution_year_pkey PRIMARY KEY (author_id, institution_seq, year_seq)
);


-- public.author_last_known_institution definition

-- Drop table

-- DROP TABLE public.author_last_known_institution;

CREATE TABLE public.author_last_known_institution (
	author_id int8 NOT NULL,
	last_known_institution_seq int2 NOT NULL,
	last_known_institution_id int8 NULL,
	CONSTRAINT author_last_known_institution_pkey PRIMARY KEY (author_id, last_known_institution_seq)
);
CREATE INDEX idx_author_last_known_inst_id ON public.author_last_known_institution USING btree (last_known_institution_id);


-- public.author_position definition

-- Drop table

-- DROP TABLE public.author_position;

CREATE TABLE public.author_position (
	author_position_id int2 NOT NULL,
	author_position varchar(6) NULL,
	CONSTRAINT author_position_pkey PRIMARY KEY (author_position_id)
);
CREATE INDEX idx_author_position_name ON public.author_position USING btree (author_position);


-- public.citation definition

-- Drop table

-- DROP TABLE public.citation;

CREATE TABLE public.citation (
	citing_work_id int8 NOT NULL,
	reference_seq int4 NOT NULL,
	cited_work_id int8 NULL,
	pub_year int2 NULL,
	cit_window int2 NULL,
	is_self_cit bool NULL,
	CONSTRAINT citation_pkey PRIMARY KEY (citing_work_id, reference_seq)
);
CREATE INDEX idx_citation_cited_work_id ON public.citation USING btree (cited_work_id);
CREATE INDEX idx_citation_pub_year ON public.citation USING btree (pub_year);


-- public.city definition

-- Drop table

-- DROP TABLE public.city;

CREATE TABLE public.city (
	geonames_city_id int4 NOT NULL,
	city varchar(100) NULL,
	CONSTRAINT city_pkey PRIMARY KEY (geonames_city_id)
);
CREATE INDEX idx_city_name ON public.city USING btree (city);


-- public.concept definition

-- Drop table

-- DROP TABLE public.concept;

CREATE TABLE public.concept (
	concept_id int8 NOT NULL,
	concept varchar(120) NULL,
	description varchar(250) NULL,
	"level" int2 NULL,
	openalex_id varchar(11) NULL,
	mag_id int8 NULL,
	wikidata_id varchar(10) NULL,
	wikipedia_url varchar(200) NULL,
	image_url varchar(700) NULL,
	thumbnail_url varchar(900) NULL,
	updated_date timestamp NULL,
	created_date timestamp NULL,
	CONSTRAINT concept_pkey PRIMARY KEY (concept_id)
);
CREATE INDEX idx_concept_level ON public.concept USING btree (level);
CREATE INDEX idx_concept_name ON public.concept USING btree (concept);
CREATE INDEX idx_concept_openalex_id ON public.concept USING btree (openalex_id);
CREATE INDEX idx_concept_updated_date ON public.concept USING btree (updated_date);
CREATE INDEX idx_concept_wikidata_id ON public.concept USING btree (wikidata_id);


-- public.concept_ancestor definition

-- Drop table

-- DROP TABLE public.concept_ancestor;

CREATE TABLE public.concept_ancestor (
	concept_id int8 NOT NULL,
	ancestor_concept_seq int2 NOT NULL,
	ancestor_concept_id int8 NULL,
	CONSTRAINT concept_ancestor_pkey PRIMARY KEY (concept_id, ancestor_concept_seq)
);
CREATE INDEX idx_concept_ancestor_ancestor_id ON public.concept_ancestor USING btree (ancestor_concept_id);


-- public.concept_international_description definition

-- Drop table

-- DROP TABLE public.concept_international_description;

CREATE TABLE public.concept_international_description (
	concept_id int8 NOT NULL,
	language_code varchar(16) NOT NULL,
	concept_international_description varchar(800) NULL,
	CONSTRAINT concept_international_description_pkey PRIMARY KEY (concept_id, language_code)
);
CREATE INDEX idx_concept_intl_desc_lang ON public.concept_international_description USING btree (language_code);


-- public.concept_international_name definition

-- Drop table

-- DROP TABLE public.concept_international_name;

CREATE TABLE public.concept_international_name (
	concept_id int8 NOT NULL,
	language_code varchar(16) NOT NULL,
	concept_international_name varchar(200) NULL,
	CONSTRAINT concept_international_name_pkey PRIMARY KEY (concept_id, language_code)
);
CREATE INDEX idx_concept_intl_name_lang ON public.concept_international_name USING btree (language_code);


-- public.concept_related definition

-- Drop table

-- DROP TABLE public.concept_related;

CREATE TABLE public.concept_related (
	concept_id int8 NOT NULL,
	related_concept_seq int2 NOT NULL,
	related_concept_id int8 NULL,
	score float8 NULL,
	CONSTRAINT concept_related_pkey PRIMARY KEY (concept_id, related_concept_seq)
);
CREATE INDEX idx_concept_related_related_id ON public.concept_related USING btree (related_concept_id);
CREATE INDEX idx_concept_related_score ON public.concept_related USING btree (score);


-- public.concept_umls_aui definition

-- Drop table

-- DROP TABLE public.concept_umls_aui;

CREATE TABLE public.concept_umls_aui (
	concept_id int8 NOT NULL,
	umls_aui_seq int2 NOT NULL,
	umls_aui varchar(9) NULL,
	CONSTRAINT concept_umls_aui_pkey PRIMARY KEY (concept_id, umls_aui_seq)
);
CREATE INDEX idx_concept_umls_aui_aui ON public.concept_umls_aui USING btree (umls_aui);


-- public.concept_umls_cui definition

-- Drop table

-- DROP TABLE public.concept_umls_cui;

CREATE TABLE public.concept_umls_cui (
	concept_id int8 NOT NULL,
	umls_cui_seq int2 NOT NULL,
	umls_cui bpchar(8) NULL,
	CONSTRAINT concept_umls_cui_pkey PRIMARY KEY (concept_id, umls_cui_seq)
);
CREATE INDEX idx_concept_umls_cui_cui ON public.concept_umls_cui USING btree (umls_cui);


-- public.country definition

-- Drop table

-- DROP TABLE public.country;

CREATE TABLE public.country (
	country_iso_alpha2_code bpchar(3) NOT NULL,
	country varchar(50) NULL,
	CONSTRAINT country_pkey PRIMARY KEY (country_iso_alpha2_code)
);
CREATE INDEX idx_country_name ON public.country USING btree (country);


-- public.data_source definition

-- Drop table

-- DROP TABLE public.data_source;

CREATE TABLE public.data_source (
	data_source_id int4 NOT NULL,
	data_source varchar(20) NULL,
	CONSTRAINT data_source_pkey PRIMARY KEY (data_source_id)
);
CREATE INDEX idx_data_source_name ON public.data_source USING btree (data_source);


-- public.doi_registration_agency definition

-- Drop table

-- DROP TABLE public.doi_registration_agency;

CREATE TABLE public.doi_registration_agency (
	doi_registration_agency_id int2 NOT NULL,
	doi_registration_agency varchar(20) NULL,
	CONSTRAINT doi_registration_agency_pkey PRIMARY KEY (doi_registration_agency_id)
);
CREATE INDEX idx_doi_reg_agency_name ON public.doi_registration_agency USING btree (doi_registration_agency);


-- public."domain" definition

-- Drop table

-- DROP TABLE public."domain";

CREATE TABLE public."domain" (
	domain_id int2 NOT NULL,
	"domain" varchar(120) NULL,
	description varchar(250) NULL,
	openalex_id int2 NULL,
	wikidata_id varchar(10) NULL,
	wikipedia_url varchar(200) NULL,
	updated_date timestamp NULL,
	created_date timestamp NULL,
	CONSTRAINT domain_pkey PRIMARY KEY (domain_id)
);
CREATE INDEX idx_domain_name ON public.domain USING btree (domain);
CREATE INDEX idx_domain_openalex_id ON public.domain USING btree (openalex_id);
CREATE INDEX idx_domain_updated_date ON public.domain USING btree (updated_date);
CREATE INDEX idx_domain_wikidata_id ON public.domain USING btree (wikidata_id);


-- public.domain_alternative_name definition

-- Drop table

-- DROP TABLE public.domain_alternative_name;

CREATE TABLE public.domain_alternative_name (
	domain_id int2 NOT NULL,
	alternative_name_seq int2 NOT NULL,
	alternative_name varchar(255) NULL,
	CONSTRAINT domain_alternative_name_pkey PRIMARY KEY (domain_id, alternative_name_seq)
);
CREATE INDEX idx_domain_alt_name ON public.domain_alternative_name USING btree (alternative_name);


-- public.domain_field definition

-- Drop table

-- DROP TABLE public.domain_field;

CREATE TABLE public.domain_field (
	domain_id int2 NOT NULL,
	field_seq int2 NOT NULL,
	field_id int2 NULL,
	CONSTRAINT domain_field_pkey PRIMARY KEY (domain_id, field_seq)
);
CREATE INDEX idx_domain_field_field_id ON public.domain_field USING btree (field_id);


-- public.domain_sibling definition

-- Drop table

-- DROP TABLE public.domain_sibling;

CREATE TABLE public.domain_sibling (
	domain_id int2 NOT NULL,
	sibling_domain_seq int2 NOT NULL,
	sibling_domain_id int2 NULL,
	CONSTRAINT domain_sibling_pkey PRIMARY KEY (domain_id, sibling_domain_seq)
);
CREATE INDEX idx_domain_sibling_sibling_id ON public.domain_sibling USING btree (sibling_domain_id);


-- public.field definition

-- Drop table

-- DROP TABLE public.field;

CREATE TABLE public.field (
	field_id int2 NOT NULL,
	field varchar(120) NULL,
	description varchar(250) NULL,
	openalex_id int2 NULL,
	wikidata_id varchar(10) NULL,
	wikipedia_url varchar(200) NULL,
	domain_id int2 NULL,
	updated_date timestamp NULL,
	created_date timestamp NULL,
	CONSTRAINT field_pkey PRIMARY KEY (field_id)
);
CREATE INDEX idx_field_domain_id ON public.field USING btree (domain_id);
CREATE INDEX idx_field_name ON public.field USING btree (field);
CREATE INDEX idx_field_openalex_id ON public.field USING btree (openalex_id);
CREATE INDEX idx_field_updated_date ON public.field USING btree (updated_date);
CREATE INDEX idx_field_wikidata_id ON public.field USING btree (wikidata_id);


-- public.field_alternative_name definition

-- Drop table

-- DROP TABLE public.field_alternative_name;

CREATE TABLE public.field_alternative_name (
	field_id int2 NOT NULL,
	alternative_name_seq int2 NOT NULL,
	alternative_name varchar(255) NULL,
	CONSTRAINT field_alternative_name_pkey PRIMARY KEY (field_id, alternative_name_seq)
);
CREATE INDEX idx_field_alt_name ON public.field_alternative_name USING btree (alternative_name);


-- public.field_sibling definition

-- Drop table

-- DROP TABLE public.field_sibling;

CREATE TABLE public.field_sibling (
	field_id int2 NOT NULL,
	sibling_field_seq int2 NOT NULL,
	sibling_field_id int2 NULL,
	CONSTRAINT field_sibling_pkey PRIMARY KEY (field_id, sibling_field_seq)
);
CREATE INDEX idx_field_sibling_sibling_id ON public.field_sibling USING btree (sibling_field_id);


-- public.field_subfield definition

-- Drop table

-- DROP TABLE public.field_subfield;

CREATE TABLE public.field_subfield (
	field_id int2 NOT NULL,
	subfield_seq int2 NOT NULL,
	subfield_id int2 NULL,
	CONSTRAINT field_subfield_pkey PRIMARY KEY (field_id, subfield_seq)
);
CREATE INDEX idx_field_subfield_subfield_id ON public.field_subfield USING btree (subfield_id);


-- public.fulltext_origin definition

-- Drop table

-- DROP TABLE public.fulltext_origin;

CREATE TABLE public.fulltext_origin (
	fulltext_origin_id int2 NOT NULL,
	fulltext_origin varchar(20) NULL,
	CONSTRAINT fulltext_origin_pkey PRIMARY KEY (fulltext_origin_id)
);
CREATE INDEX idx_fulltext_origin_name ON public.fulltext_origin USING btree (fulltext_origin);


-- public.funder definition

-- Drop table

-- DROP TABLE public.funder;

CREATE TABLE public.funder (
	funder_id int8 NOT NULL,
	funder varchar(200) NULL,
	country_iso_alpha2_code bpchar(3) NULL,
	description varchar(250) NULL,
	homepage_url varchar(2000) NULL,
	ror_id varchar(9) NULL,
	openalex_id varchar(11) NULL,
	wikidata_id varchar(10) NULL,
	image_url varchar(700) NULL,
	thumbnail_url varchar(1200) NULL,
	updated_date timestamp NULL,
	created_date timestamp NULL,
	CONSTRAINT funder_pkey PRIMARY KEY (funder_id)
);
CREATE INDEX idx_funder_country_code ON public.funder USING btree (country_iso_alpha2_code);
CREATE INDEX idx_funder_name ON public.funder USING btree (funder);
CREATE INDEX idx_funder_openalex_id ON public.funder USING btree (openalex_id);
CREATE INDEX idx_funder_ror_id ON public.funder USING btree (ror_id);
CREATE INDEX idx_funder_updated_date ON public.funder USING btree (updated_date);
CREATE INDEX idx_funder_wikidata_id ON public.funder USING btree (wikidata_id);


-- public.funder_alternative_name definition

-- Drop table

-- DROP TABLE public.funder_alternative_name;

CREATE TABLE public.funder_alternative_name (
	funder_id int8 NOT NULL,
	alternative_name_seq int2 NOT NULL,
	alternative_name varchar(500) NULL,
	CONSTRAINT funder_alternative_name_pkey PRIMARY KEY (funder_id, alternative_name_seq)
);
CREATE INDEX idx_funder_alt_name ON public.funder_alternative_name USING btree (alternative_name);


-- public.funder_publisher definition

-- Drop table

-- DROP TABLE public.funder_publisher;

CREATE TABLE public.funder_publisher (
	funder_id int8 NOT NULL,
	publisher_seq int2 NOT NULL,
	publisher_id int8 NULL,
	CONSTRAINT funder_publisher_pkey PRIMARY KEY (funder_id, publisher_seq)
);
CREATE INDEX idx_funder_publisher_publisher_id ON public.funder_publisher USING btree (publisher_id);


-- public.institution definition

-- Drop table

-- DROP TABLE public.institution;

CREATE TABLE public.institution (
	institution_id int8 NOT NULL,
	institution varchar(200) NULL,
	institution_type_id int2 NULL,
	country_iso_alpha2_code bpchar(3) NULL,
	region_id int2 NULL,
	geonames_city_id int4 NULL,
	latitude float8 NULL,
	longitude float8 NULL,
	homepage_url varchar(2000) NULL,
	is_super_system bool NULL,
	ror_id varchar(9) NULL,
	grid_id varchar(20) NULL,
	openalex_id varchar(11) NULL,
	mag_id int8 NULL,
	wikidata_id varchar(10) NULL,
	wikipedia_url varchar(800) NULL,
	image_url varchar(800) NULL,
	thumbnail_url varchar(1200) NULL,
	updated_date timestamp NULL,
	created_date timestamp NULL,
	CONSTRAINT institution_pkey PRIMARY KEY (institution_id)
);
CREATE INDEX idx_institution_city_id ON public.institution USING btree (geonames_city_id);
CREATE INDEX idx_institution_country_code ON public.institution USING btree (country_iso_alpha2_code);
CREATE INDEX idx_institution_grid_id ON public.institution USING btree (grid_id);
CREATE INDEX idx_institution_name ON public.institution USING btree (institution);
CREATE INDEX idx_institution_openalex_id ON public.institution USING btree (openalex_id);
CREATE INDEX idx_institution_region_id ON public.institution USING btree (region_id);
CREATE INDEX idx_institution_ror_id ON public.institution USING btree (ror_id);
CREATE INDEX idx_institution_type_id ON public.institution USING btree (institution_type_id);
CREATE INDEX idx_institution_updated_date ON public.institution USING btree (updated_date);
CREATE INDEX idx_institution_wikidata_id ON public.institution USING btree (wikidata_id);


-- public.institution_acronym definition

-- Drop table

-- DROP TABLE public.institution_acronym;

CREATE TABLE public.institution_acronym (
	institution_id int8 NOT NULL,
	acronym_seq int2 NOT NULL,
	acronym varchar(70) NULL,
	CONSTRAINT institution_acronym_pkey PRIMARY KEY (institution_id, acronym_seq)
);
CREATE INDEX idx_institution_acronym_name ON public.institution_acronym USING btree (acronym);


-- public.institution_alternative_name definition

-- Drop table

-- DROP TABLE public.institution_alternative_name;

CREATE TABLE public.institution_alternative_name (
	institution_id int8 NOT NULL,
	alternative_name_seq int2 NOT NULL,
	alternative_name varchar(250) NULL,
	CONSTRAINT institution_alternative_name_pkey PRIMARY KEY (institution_id, alternative_name_seq)
);
CREATE INDEX idx_institution_alt_name ON public.institution_alternative_name USING btree (alternative_name);


-- public.institution_associated definition

-- Drop table

-- DROP TABLE public.institution_associated;

CREATE TABLE public.institution_associated (
	institution_id int8 NOT NULL,
	associated_institution_seq int2 NOT NULL,
	associated_institution_id int8 NULL,
	institution_relationship_type_id int2 NULL,
	CONSTRAINT institution_associated_pkey PRIMARY KEY (institution_id, associated_institution_seq)
);
CREATE INDEX idx_inst_associated_assoc_id ON public.institution_associated USING btree (associated_institution_id);
CREATE INDEX idx_inst_associated_rel_type_id ON public.institution_associated USING btree (institution_relationship_type_id);


-- public.institution_funder definition

-- Drop table

-- DROP TABLE public.institution_funder;

CREATE TABLE public.institution_funder (
	institution_id int8 NOT NULL,
	funder_seq int2 NOT NULL,
	funder_id int8 NULL,
	CONSTRAINT institution_funder_pkey PRIMARY KEY (institution_id, funder_seq)
);
CREATE INDEX idx_institution_funder_funder_id ON public.institution_funder USING btree (funder_id);


-- public.institution_international_name definition

-- Drop table

-- DROP TABLE public.institution_international_name;

CREATE TABLE public.institution_international_name (
	institution_id int8 NOT NULL,
	language_code varchar(16) NOT NULL,
	institution_international_name varchar(200) NULL,
	CONSTRAINT institution_international_name_pkey PRIMARY KEY (institution_id, language_code)
);
CREATE INDEX idx_inst_intl_name_lang ON public.institution_international_name USING btree (language_code);
CREATE INDEX idx_inst_intl_name_name ON public.institution_international_name USING btree (institution_international_name);


-- public.institution_lineage definition

-- Drop table

-- DROP TABLE public.institution_lineage;

CREATE TABLE public.institution_lineage (
	institution_id int8 NOT NULL,
	lineage_institution_seq int2 NOT NULL,
	lineage_institution_id int8 NULL,
	CONSTRAINT institution_lineage_pkey PRIMARY KEY (institution_id, lineage_institution_seq)
);
CREATE INDEX idx_inst_lineage_lineage_id ON public.institution_lineage USING btree (lineage_institution_id);


-- public.institution_publisher definition

-- Drop table

-- DROP TABLE public.institution_publisher;

CREATE TABLE public.institution_publisher (
	institution_id int8 NOT NULL,
	publisher_seq int2 NOT NULL,
	publisher_id int8 NULL,
	CONSTRAINT institution_publisher_pkey PRIMARY KEY (institution_id, publisher_seq)
);
CREATE INDEX idx_institution_publisher_pub_id ON public.institution_publisher USING btree (publisher_id);


-- public.institution_relationship_type definition

-- Drop table

-- DROP TABLE public.institution_relationship_type;

CREATE TABLE public.institution_relationship_type (
	institution_relationship_type_id int2 NOT NULL,
	institution_relationship_type varchar(15) NULL,
	CONSTRAINT institution_relationship_type_pkey PRIMARY KEY (institution_relationship_type_id)
);
CREATE INDEX idx_inst_rel_type_name ON public.institution_relationship_type USING btree (institution_relationship_type);


-- public.institution_repository definition

-- Drop table

-- DROP TABLE public.institution_repository;

CREATE TABLE public.institution_repository (
	institution_id int8 NOT NULL,
	repository_seq int2 NOT NULL,
	repository_source_id int8 NULL,
	CONSTRAINT institution_repository_pkey PRIMARY KEY (institution_id, repository_seq)
);
CREATE INDEX idx_institution_repo_source_id ON public.institution_repository USING btree (repository_source_id);


-- public.institution_type definition

-- Drop table

-- DROP TABLE public.institution_type;

CREATE TABLE public.institution_type (
	institution_type_id int2 NOT NULL,
	institution_type varchar(10) NULL,
	CONSTRAINT institution_type_pkey PRIMARY KEY (institution_type_id)
);
CREATE INDEX idx_institution_type_name ON public.institution_type USING btree (institution_type);


-- public.keyword definition

-- Drop table

-- DROP TABLE public.keyword;

CREATE TABLE public.keyword (
	keyword_id int4 NOT NULL,
	keyword varchar(200) NULL,
	CONSTRAINT keyword_pkey PRIMARY KEY (keyword_id)
);
CREATE INDEX idx_keyword_name ON public.keyword USING btree (keyword);


-- public.license definition

-- Drop table

-- DROP TABLE public.license;

CREATE TABLE public.license (
	license_id int2 NOT NULL,
	license varchar(60) NULL,
	CONSTRAINT license_pkey PRIMARY KEY (license_id)
);
CREATE INDEX idx_license_name ON public.license USING btree (license);


-- public.mesh_descriptor definition

-- Drop table

-- DROP TABLE public.mesh_descriptor;

CREATE TABLE public.mesh_descriptor (
	mesh_descriptor_ui varchar(10) NOT NULL,
	mesh_descriptor varchar(120) NULL,
	CONSTRAINT mesh_descriptor_pkey PRIMARY KEY (mesh_descriptor_ui)
);
CREATE INDEX idx_mesh_descriptor_name ON public.mesh_descriptor USING btree (mesh_descriptor);


-- public.mesh_qualifier definition

-- Drop table

-- DROP TABLE public.mesh_qualifier;

CREATE TABLE public.mesh_qualifier (
	mesh_qualifier_ui varchar(10) NOT NULL,
	mesh_qualifier varchar(40) NULL,
	CONSTRAINT mesh_qualifier_pkey PRIMARY KEY (mesh_qualifier_ui)
);
CREATE INDEX idx_mesh_qualifier_name ON public.mesh_qualifier USING btree (mesh_qualifier);


-- public.oa_status definition

-- Drop table

-- DROP TABLE public.oa_status;

CREATE TABLE public.oa_status (
	oa_status_id int2 NOT NULL,
	oa_status varchar(10) NULL,
	CONSTRAINT oa_status_pkey PRIMARY KEY (oa_status_id)
);
CREATE INDEX idx_oa_status_name ON public.oa_status USING btree (oa_status);


-- public.publisher definition

-- Drop table

-- DROP TABLE public.publisher;

CREATE TABLE public.publisher (
	publisher_id int8 NOT NULL,
	publisher varchar(200) NULL,
	hierarchy_level int2 NULL,
	parent_publisher_id int8 NULL,
	homepage_url varchar(2000) NULL,
	ror_id varchar(9) NULL,
	openalex_id varchar(11) NULL,
	wikidata_id varchar(10) NULL,
	image_url varchar(700) NULL,
	thumbnail_url varchar(1200) NULL,
	updated_date timestamp NULL,
	created_date timestamp NULL,
	CONSTRAINT publisher_pkey PRIMARY KEY (publisher_id)
);
CREATE INDEX idx_publisher_name ON public.publisher USING btree (publisher);
CREATE INDEX idx_publisher_openalex_id ON public.publisher USING btree (openalex_id);
CREATE INDEX idx_publisher_parent_id ON public.publisher USING btree (parent_publisher_id);
CREATE INDEX idx_publisher_ror_id ON public.publisher USING btree (ror_id);
CREATE INDEX idx_publisher_updated_date ON public.publisher USING btree (updated_date);
CREATE INDEX idx_publisher_wikidata_id ON public.publisher USING btree (wikidata_id);


-- public.publisher_alternative_name definition

-- Drop table

-- DROP TABLE public.publisher_alternative_name;

CREATE TABLE public.publisher_alternative_name (
	publisher_id int8 NOT NULL,
	alternative_name_seq int2 NOT NULL,
	alternative_name varchar(150) NULL,
	CONSTRAINT publisher_alternative_name_pkey PRIMARY KEY (publisher_id, alternative_name_seq)
);
CREATE INDEX idx_publisher_alt_name ON public.publisher_alternative_name USING btree (alternative_name);


-- public.publisher_country definition

-- Drop table

-- DROP TABLE public.publisher_country;

CREATE TABLE public.publisher_country (
	publisher_id int8 NOT NULL,
	country_seq int2 NOT NULL,
	country_iso_alpha2_code bpchar(3) NULL,
	CONSTRAINT publisher_country_pkey PRIMARY KEY (publisher_id, country_seq)
);
CREATE INDEX idx_publisher_country_code ON public.publisher_country USING btree (country_iso_alpha2_code);


-- public.raw_affiliation_string definition

-- Drop table

-- DROP TABLE public.raw_affiliation_string;

CREATE TABLE public.raw_affiliation_string (
	raw_affiliation_string_id int8 NOT NULL,
	raw_affiliation_string text NULL,
	CONSTRAINT raw_affiliation_string_pkey PRIMARY KEY (raw_affiliation_string_id)
);
CREATE INDEX idx_raw_affil_string ON public.raw_affiliation_string USING btree (raw_affiliation_string);


-- public.raw_author_name definition

-- Drop table

-- DROP TABLE public.raw_author_name;

CREATE TABLE public.raw_author_name (
	raw_author_name_id int8 NOT NULL,
	raw_author_name varchar(800) NULL,
	CONSTRAINT raw_author_name_pkey PRIMARY KEY (raw_author_name_id)
);
CREATE INDEX idx_raw_author_name ON public.raw_author_name USING btree (raw_author_name);


-- public.region definition

-- Drop table

-- DROP TABLE public.region;

CREATE TABLE public.region (
	region_id int2 NOT NULL,
	region varchar(50) NULL,
	CONSTRAINT region_pkey PRIMARY KEY (region_id)
);
CREATE INDEX idx_region_name ON public.region USING btree (region);


-- public."source" definition

-- Drop table

-- DROP TABLE public."source";

CREATE TABLE public."source" (
	source_id int8 NOT NULL,
	"source" varchar(800) NULL,
	abbreviation varchar(200) NULL,
	source_type_id int2 NULL,
	country_iso_alpha2_code bpchar(3) NULL,
	host_organization_publisher_id int8 NULL,
	host_organization_institution_id int8 NULL,
	homepage_url varchar(2000) NULL,
	issn_l bpchar(9) NULL,
	openalex_id varchar(11) NULL,
	mag_id int8 NULL,
	wikidata_id varchar(10) NULL,
	fatcat_id bpchar(26) NULL,
	is_in_doaj bool NULL,
	is_oa bool NULL,
	apc_price_usd int4 NULL,
	updated_date timestamp NULL,
	created_date timestamp NULL,
	CONSTRAINT source_pkey PRIMARY KEY (source_id)
);
CREATE INDEX idx_source_abbreviation ON public.source USING btree (abbreviation);
CREATE INDEX idx_source_country_code ON public.source USING btree (country_iso_alpha2_code);
CREATE INDEX idx_source_host_inst_id ON public.source USING btree (host_organization_institution_id);
CREATE INDEX idx_source_host_pub_id ON public.source USING btree (host_organization_publisher_id);
CREATE INDEX idx_source_is_oa ON public.source USING btree (is_oa);
CREATE INDEX idx_source_issn_l ON public.source USING btree (issn_l);
CREATE INDEX idx_source_name ON public.source USING btree (source);
CREATE INDEX idx_source_openalex_id ON public.source USING btree (openalex_id);
CREATE INDEX idx_source_type_id ON public.source USING btree (source_type_id);
CREATE INDEX idx_source_updated_date ON public.source USING btree (updated_date);
CREATE INDEX idx_source_wikidata_id ON public.source USING btree (wikidata_id);


-- public.source_alternative_title definition

-- Drop table

-- DROP TABLE public.source_alternative_title;

CREATE TABLE public.source_alternative_title (
	source_id int8 NOT NULL,
	alternative_title_seq int2 NOT NULL,
	alternative_title varchar(700) NULL,
	CONSTRAINT source_alternative_title_pkey PRIMARY KEY (source_id, alternative_title_seq)
);
CREATE INDEX idx_source_alt_title ON public.source_alternative_title USING btree (alternative_title);


-- public.source_apc_price definition

-- Drop table

-- DROP TABLE public.source_apc_price;

CREATE TABLE public.source_apc_price (
	source_id int8 NOT NULL,
	apc_price_seq int2 NOT NULL,
	apc_price int4 NULL,
	currency bpchar(3) NULL,
	CONSTRAINT source_apc_price_pkey PRIMARY KEY (source_id, apc_price_seq)
);
CREATE INDEX idx_source_apc_currency ON public.source_apc_price USING btree (currency);
CREATE INDEX idx_source_apc_price ON public.source_apc_price USING btree (apc_price);


-- public.source_issn definition

-- Drop table

-- DROP TABLE public.source_issn;

CREATE TABLE public.source_issn (
	source_id int8 NOT NULL,
	issn_seq int2 NOT NULL,
	issn bpchar(9) NULL,
	CONSTRAINT source_issn_pkey PRIMARY KEY (source_id, issn_seq)
);
CREATE INDEX idx_source_issn ON public.source_issn USING btree (issn);


-- public.source_society definition

-- Drop table

-- DROP TABLE public.source_society;

CREATE TABLE public.source_society (
	source_id int8 NOT NULL,
	society_seq int2 NOT NULL,
	society varchar(500) NULL,
	homepage_url varchar(2000) NULL,
	CONSTRAINT source_society_pkey PRIMARY KEY (source_id, society_seq)
);
CREATE INDEX idx_source_society_name ON public.source_society USING btree (society);


-- public.source_type definition

-- Drop table

-- DROP TABLE public.source_type;

CREATE TABLE public.source_type (
	source_type_id int2 NOT NULL,
	source_type varchar(14) NULL,
	CONSTRAINT source_type_pkey PRIMARY KEY (source_type_id)
);
CREATE INDEX idx_source_type_name ON public.source_type USING btree (source_type);


-- public.subfield definition

-- Drop table

-- DROP TABLE public.subfield;

CREATE TABLE public.subfield (
	subfield_id int2 NOT NULL,
	subfield varchar(120) NULL,
	description varchar(250) NULL,
	openalex_id int2 NULL,
	wikidata_id varchar(10) NULL,
	wikipedia_url varchar(200) NULL,
	domain_id int2 NULL,
	field_id int2 NULL,
	updated_date timestamp NULL,
	created_date timestamp NULL,
	CONSTRAINT subfield_pkey PRIMARY KEY (subfield_id)
);
CREATE INDEX idx_subfield_domain_id ON public.subfield USING btree (domain_id);
CREATE INDEX idx_subfield_field_id ON public.subfield USING btree (field_id);
CREATE INDEX idx_subfield_name ON public.subfield USING btree (subfield);
CREATE INDEX idx_subfield_openalex_id ON public.subfield USING btree (openalex_id);
CREATE INDEX idx_subfield_updated_date ON public.subfield USING btree (updated_date);
CREATE INDEX idx_subfield_wikidata_id ON public.subfield USING btree (wikidata_id);


-- public.subfield_alternative_name definition

-- Drop table

-- DROP TABLE public.subfield_alternative_name;

CREATE TABLE public.subfield_alternative_name (
	subfield_id int2 NOT NULL,
	alternative_name_seq int2 NOT NULL,
	alternative_name varchar(255) NULL,
	CONSTRAINT subfield_alternative_name_pkey PRIMARY KEY (subfield_id, alternative_name_seq)
);
CREATE INDEX idx_subfield_alt_name ON public.subfield_alternative_name USING btree (alternative_name);


-- public.subfield_sibling definition

-- Drop table

-- DROP TABLE public.subfield_sibling;

CREATE TABLE public.subfield_sibling (
	subfield_id int2 NOT NULL,
	sibling_subfield_seq int2 NOT NULL,
	sibling_subfield_id int2 NULL,
	CONSTRAINT subfield_sibling_pkey PRIMARY KEY (subfield_id, sibling_subfield_seq)
);
CREATE INDEX idx_subfield_sibling_sibling_id ON public.subfield_sibling USING btree (sibling_subfield_id);


-- public.subfield_topic definition

-- Drop table

-- DROP TABLE public.subfield_topic;

CREATE TABLE public.subfield_topic (
	subfield_id int2 NOT NULL,
	topic_seq int2 NOT NULL,
	topic_id int2 NULL,
	CONSTRAINT subfield_topic_pkey PRIMARY KEY (subfield_id, topic_seq)
);
CREATE INDEX idx_subfield_topic_topic_id ON public.subfield_topic USING btree (topic_id);


-- public.sustainable_development_goal definition

-- Drop table

-- DROP TABLE public.sustainable_development_goal;

CREATE TABLE public.sustainable_development_goal (
	sustainable_development_goal_id int2 NOT NULL,
	sustainable_development_goal varchar(40) NULL,
	taxonomy_url varchar(30) NULL,
	CONSTRAINT sustainable_development_goal_pkey PRIMARY KEY (sustainable_development_goal_id)
);
CREATE INDEX idx_sdg_name ON public.sustainable_development_goal USING btree (sustainable_development_goal);


-- public.topic definition

-- Drop table

-- DROP TABLE public.topic;

CREATE TABLE public.topic (
	topic_id int2 NOT NULL,
	topic varchar(120) NULL,
	description varchar(1000) NULL,
	openalex_id int2 NULL,
	wikipedia_url varchar(200) NULL,
	domain_id int2 NULL,
	field_id int2 NULL,
	subfield_id int2 NULL,
	updated_date timestamp NULL,
	created_date timestamp NULL,
	CONSTRAINT topic_pkey PRIMARY KEY (topic_id)
);
CREATE INDEX idx_topic_domain_id ON public.topic USING btree (domain_id);
CREATE INDEX idx_topic_field_id ON public.topic USING btree (field_id);
CREATE INDEX idx_topic_name ON public.topic USING btree (topic);
CREATE INDEX idx_topic_openalex_id ON public.topic USING btree (openalex_id);
CREATE INDEX idx_topic_subfield_id ON public.topic USING btree (subfield_id);
CREATE INDEX idx_topic_updated_date ON public.topic USING btree (updated_date);


-- public.topic_keyword definition

-- Drop table

-- DROP TABLE public.topic_keyword;

CREATE TABLE public.topic_keyword (
	topic_id int2 NOT NULL,
	keyword_seq int2 NOT NULL,
	keyword varchar(100) NULL,
	CONSTRAINT topic_keyword_pkey PRIMARY KEY (topic_id, keyword_seq)
);
CREATE INDEX idx_topic_keyword_keyword ON public.topic_keyword USING btree (keyword);


-- public.topic_sibling definition

-- Drop table

-- DROP TABLE public.topic_sibling;

CREATE TABLE public.topic_sibling (
	topic_id int2 NOT NULL,
	sibling_topic_seq int2 NOT NULL,
	sibling_topic_id int2 NULL,
	CONSTRAINT topic_sibling_pkey PRIMARY KEY (topic_id, sibling_topic_seq)
);
CREATE INDEX idx_topic_sibling_sibling_id ON public.topic_sibling USING btree (sibling_topic_id);


-- public."version" definition

-- Drop table

-- DROP TABLE public."version";

CREATE TABLE public."version" (
	version_id int2 NOT NULL,
	"version" varchar(16) NULL,
	CONSTRAINT version_pkey PRIMARY KEY (version_id)
);
CREATE INDEX idx_version_name ON public.version USING btree (version);


-- public.work definition

-- Drop table

-- DROP TABLE public.work;

CREATE TABLE public.work (
	work_id int8 NOT NULL,
	work_type_id int2 NULL,
	crossref_work_type_id int2 NULL,
	source_id int8 NULL,
	pub_date timestamp NULL,
	pub_year int2 NULL,
	volume varchar(100) NULL,
	issue varchar(80) NULL,
	page_first varchar(200) NULL,
	page_last varchar(300) NULL,
	doi_registration_agency_id int2 NULL,
	doi varchar(350) NULL,
	openalex_id varchar(32) NULL,
	mag_id int8 NULL,
	pmid int4 NULL,
	pmcid int4 NULL,
	arxiv_id varchar(80) NULL,
	language_iso2_code bpchar(2) NULL,
	is_paratext bool NULL,
	is_retracted bool NULL,
	is_oa bool NULL,
	any_repository_has_fulltext bool NULL,
	oa_status_id int2 NULL,
	oa_url varchar(4000) NULL,
	apc_list_currency bpchar(3) NULL,
	apc_list_price int4 NULL,
	apc_list_price_usd int4 NULL,
	apc_list_apc_provenance_id int2 NULL,
	apc_paid_currency bpchar(3) NULL,
	apc_paid_price int4 NULL,
	apc_paid_price_usd int4 NULL,
	apc_paid_apc_provenance_id int2 NULL,
	fulltext_origin_id int2 NULL,
	n_refs int4 NULL,
	n_cits int4 NULL,
	updated_date timestamp NULL,
	created_date timestamp NULL,
	CONSTRAINT work_pkey PRIMARY KEY (work_id)
);
CREATE INDEX idx_work_doi ON public.work USING btree (doi);
CREATE INDEX idx_work_doi_reg_agency_id ON public.work USING btree (doi_registration_agency_id);
CREATE INDEX idx_work_fulltext_origin_id ON public.work USING btree (fulltext_origin_id);
CREATE INDEX idx_work_is_oa ON public.work USING btree (is_oa);
CREATE INDEX idx_work_language_code ON public.work USING btree (language_iso2_code);
CREATE INDEX idx_work_oa_status_id ON public.work USING btree (oa_status_id);
CREATE INDEX idx_work_openalex_id ON public.work USING btree (openalex_id);
CREATE INDEX idx_work_pmid ON public.work USING btree (pmid);
CREATE INDEX idx_work_pub_date ON public.work USING btree (pub_date);
CREATE INDEX idx_work_pub_year ON public.work USING btree (pub_year);
CREATE INDEX idx_work_type_id ON public.work USING btree (work_type_id);
CREATE INDEX idx_work_updated_date ON public.work USING btree (updated_date);


-- public.work_abstract definition

-- Drop table

-- DROP TABLE public.work_abstract;

CREATE TABLE public.work_abstract (
	work_id int8 NOT NULL,
	abstract text NULL,
	CONSTRAINT work_abstract_pkey PRIMARY KEY (work_id)
);


-- public.work_affiliation definition

-- Drop table

-- DROP TABLE public.work_affiliation;

CREATE TABLE public.work_affiliation (
	work_id int8 NOT NULL,
	affiliation_seq int2 NOT NULL,
	raw_affiliation_string_id int8 NULL,
	CONSTRAINT work_affiliation_pkey PRIMARY KEY (work_id, affiliation_seq)
);
CREATE INDEX idx_work_affil_raw_string_id ON public.work_affiliation USING btree (raw_affiliation_string_id);


-- public.work_affiliation_institution definition

-- Drop table

-- DROP TABLE public.work_affiliation_institution;

CREATE TABLE public.work_affiliation_institution (
	work_id int8 NOT NULL,
	affiliation_seq int2 NOT NULL,
	institution_seq int2 NOT NULL,
	institution_id int8 NULL,
	CONSTRAINT work_affiliation_institution_pkey PRIMARY KEY (work_id, affiliation_seq, institution_seq)
);
CREATE INDEX idx_work_affil_inst_inst_id ON public.work_affiliation_institution USING btree (institution_id);


-- public.work_author definition

-- Drop table

-- DROP TABLE public.work_author;

CREATE TABLE public.work_author (
	work_id int8 NOT NULL,
	author_seq int2 NOT NULL,
	author_id int8 NULL,
	author_position_id int2 NULL,
	is_corresponding_author bool NULL,
	raw_author_name_id int8 NULL,
	CONSTRAINT work_author_pkey PRIMARY KEY (work_id, author_seq)
);
CREATE INDEX idx_work_author_author_id ON public.work_author USING btree (author_id);
CREATE INDEX idx_work_author_is_corresponding ON public.work_author USING btree (is_corresponding_author);
CREATE INDEX idx_work_author_position_id ON public.work_author USING btree (author_position_id);
CREATE INDEX idx_work_author_raw_name_id ON public.work_author USING btree (raw_author_name_id);


-- public.work_author_affiliation definition

-- Drop table

-- DROP TABLE public.work_author_affiliation;

CREATE TABLE public.work_author_affiliation (
	work_id int8 NOT NULL,
	author_seq int2 NOT NULL,
	affiliation_seq int2 NOT NULL,
	CONSTRAINT work_author_affiliation_pkey PRIMARY KEY (work_id, author_seq, affiliation_seq)
);


-- public.work_author_country definition

-- Drop table

-- DROP TABLE public.work_author_country;

CREATE TABLE public.work_author_country (
	work_id int8 NOT NULL,
	author_seq int2 NOT NULL,
	country_seq int2 NOT NULL,
	country_iso_alpha2_code bpchar(3) NULL,
	CONSTRAINT work_author_country_pkey PRIMARY KEY (work_id, author_seq, country_seq)
);
CREATE INDEX idx_work_author_country_code ON public.work_author_country USING btree (country_iso_alpha2_code);


-- public.work_concept definition

-- Drop table

-- DROP TABLE public.work_concept;

CREATE TABLE public.work_concept (
	work_id int8 NOT NULL,
	concept_seq int2 NOT NULL,
	concept_id int8 NULL,
	score float8 NULL,
	CONSTRAINT work_concept_pkey PRIMARY KEY (work_id, concept_seq)
);
CREATE INDEX idx_work_concept_concept_id ON public.work_concept USING btree (concept_id);
CREATE INDEX idx_work_concept_score ON public.work_concept USING btree (score);


-- public.work_data_source definition

-- Drop table

-- DROP TABLE public.work_data_source;

CREATE TABLE public.work_data_source (
	work_id int8 NOT NULL,
	data_source_seq int2 NOT NULL,
	data_source_id int4 NULL,
	CONSTRAINT work_data_source_pkey PRIMARY KEY (work_id, data_source_seq)
);
CREATE INDEX idx_work_data_source_ds_id ON public.work_data_source USING btree (data_source_id);


-- public.work_detail definition

-- Drop table

-- DROP TABLE public.work_detail;

CREATE TABLE public.work_detail (
	work_id int8 NOT NULL,
	author_first varchar(1000) NULL,
	author_et_al varchar(800) NULL,
	institution_first varchar(200) NULL,
	institution_et_al varchar(500) NULL,
	title text NULL,
	"source" varchar(800) NULL,
	pub_year int2 NULL,
	volume varchar(100) NULL,
	issue varchar(80) NULL,
	pages varchar(350) NULL,
	doi varchar(330) NULL,
	pmid int4 NULL,
	work_type varchar(25) NULL,
	n_cits int4 NULL,
	n_self_cits int4 NULL,
	CONSTRAINT work_detail_pkey PRIMARY KEY (work_id)
);
CREATE INDEX idx_work_detail_doi ON public.work_detail USING btree (doi);
CREATE INDEX idx_work_detail_n_cits ON public.work_detail USING btree (n_cits);
CREATE INDEX idx_work_detail_pmid ON public.work_detail USING btree (pmid);
CREATE INDEX idx_work_detail_pub_year ON public.work_detail USING btree (pub_year);
CREATE INDEX idx_work_detail_title ON public.work_detail USING btree (title);


-- public.work_grant definition

-- Drop table

-- DROP TABLE public.work_grant;

CREATE TABLE public.work_grant (
	work_id int8 NOT NULL,
	grant_seq int2 NOT NULL,
	award_id varchar(1000) NULL,
	funder_id int8 NULL,
	CONSTRAINT work_grant_pkey PRIMARY KEY (work_id, grant_seq)
);
CREATE INDEX idx_work_grant_funder_id ON public.work_grant USING btree (funder_id);


-- public.work_keyword definition

-- Drop table

-- DROP TABLE public.work_keyword;

CREATE TABLE public.work_keyword (
	work_id int8 NOT NULL,
	keyword_seq int2 NOT NULL,
	keyword_id int4 NULL,
	score float8 NULL,
	CONSTRAINT work_keyword_pkey PRIMARY KEY (work_id, keyword_seq)
);
CREATE INDEX idx_work_keyword_keyword_id ON public.work_keyword USING btree (keyword_id);
CREATE INDEX idx_work_keyword_score ON public.work_keyword USING btree (score);


-- public.work_location definition

-- Drop table

-- DROP TABLE public.work_location;

CREATE TABLE public.work_location (
	work_id int8 NOT NULL,
	location_seq int2 NOT NULL,
	is_primary_location bool NULL,
	is_best_oa_location bool NULL,
	source_id int8 NULL,
	landing_page_url varchar(2000) NULL,
	pdf_url varchar(4000) NULL,
	version_id int2 NULL,
	license_id int2 NULL,
	is_oa bool NULL,
	is_accepted bool NULL,
	is_published bool NULL,
	CONSTRAINT work_location_pkey PRIMARY KEY (work_id, location_seq)
);
CREATE INDEX idx_work_location_is_best_oa ON public.work_location USING btree (is_best_oa_location);
CREATE INDEX idx_work_location_is_oa ON public.work_location USING btree (is_oa);
CREATE INDEX idx_work_location_is_primary ON public.work_location USING btree (is_primary_location);
CREATE INDEX idx_work_location_license_id ON public.work_location USING btree (license_id);
CREATE INDEX idx_work_location_source_id ON public.work_location USING btree (source_id);
CREATE INDEX idx_work_location_version_id ON public.work_location USING btree (version_id);


-- public.work_mesh definition

-- Drop table

-- DROP TABLE public.work_mesh;

CREATE TABLE public.work_mesh (
	work_id int8 NOT NULL,
	mesh_seq int2 NOT NULL,
	mesh_descriptor_ui varchar(10) NULL,
	mesh_qualifier_ui varchar(10) NULL,
	is_major_topic bool NULL,
	CONSTRAINT work_mesh_pkey PRIMARY KEY (work_id, mesh_seq)
);
CREATE INDEX idx_work_mesh_descriptor_ui ON public.work_mesh USING btree (mesh_descriptor_ui);
CREATE INDEX idx_work_mesh_is_major_topic ON public.work_mesh USING btree (is_major_topic);
CREATE INDEX idx_work_mesh_qualifier_ui ON public.work_mesh USING btree (mesh_qualifier_ui);


-- public.work_reference definition

-- Drop table

-- DROP TABLE public.work_reference;

CREATE TABLE public.work_reference (
	work_id int8 NOT NULL,
	reference_seq int4 NOT NULL,
	cited_work_id int8 NULL,
	CONSTRAINT work_reference_pkey PRIMARY KEY (work_id, reference_seq)
);
CREATE INDEX idx_work_reference_cited_id ON public.work_reference USING btree (cited_work_id);


-- public.work_related definition

-- Drop table

-- DROP TABLE public.work_related;

CREATE TABLE public.work_related (
	work_id int8 NOT NULL,
	related_work_seq int2 NOT NULL,
	related_work_id int8 NULL,
	CONSTRAINT work_related_pkey PRIMARY KEY (work_id, related_work_seq)
);
CREATE INDEX idx_work_related_related_id ON public.work_related USING btree (related_work_id);


-- public.work_sustainable_development_goal definition

-- Drop table

-- DROP TABLE public.work_sustainable_development_goal;

CREATE TABLE public.work_sustainable_development_goal (
	work_id int8 NOT NULL,
	sustainable_development_goal_seq int2 NOT NULL,
	sustainable_development_goal_id int2 NULL,
	score float8 NULL,
	CONSTRAINT work_sustainable_development_goal_pkey PRIMARY KEY (work_id, sustainable_development_goal_seq)
);
CREATE INDEX idx_work_sdg_id ON public.work_sustainable_development_goal USING btree (sustainable_development_goal_id);
CREATE INDEX idx_work_sdg_score ON public.work_sustainable_development_goal USING btree (score);


-- public.work_title definition

-- Drop table

-- DROP TABLE public.work_title;

CREATE TABLE public.work_title (
	work_id int8 NOT NULL,
	title text NULL,
	CONSTRAINT work_title_pkey PRIMARY KEY (work_id)
);


-- public.work_topic definition

-- Drop table

-- DROP TABLE public.work_topic;

CREATE TABLE public.work_topic (
	work_id int8 NOT NULL,
	topic_seq int2 NOT NULL,
	topic_id int2 NULL,
	score float8 NULL,
	is_primary_topic bool NULL,
	CONSTRAINT work_topic_pkey PRIMARY KEY (work_id, topic_seq)
);
CREATE INDEX idx_work_topic_is_primary ON public.work_topic USING btree (is_primary_topic);
CREATE INDEX idx_work_topic_score ON public.work_topic USING btree (score);
CREATE INDEX idx_work_topic_topic_id ON public.work_topic USING btree (topic_id);


-- public.work_type definition

-- Drop table

-- DROP TABLE public.work_type;

CREATE TABLE public.work_type (
	work_type_id int2 NOT NULL,
	work_type varchar(25) NULL,
	CONSTRAINT work_type_pkey PRIMARY KEY (work_type_id)
);
CREATE INDEX idx_work_type_name ON public.work_type USING btree (work_type);