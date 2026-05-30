# specifications-AA_GLOBAL

Global definitions, boilerplate documents, publishing scripts, and shared resources for the openEHR specification ecosystem.

## Repository Purpose

This repo is **not** a specification itself. It provides the shared infrastructure consumed by all `specifications-XX` component repos (RM, AM, BASE, LANG, PROC, SM, QUERY, CNF, TERM, ITS-*). It is the foundation of the openEHR specification publishing pipeline.

## Structure

```
bin/                        # Publishing and setup scripts (bash)
  spec_publish.sh           # Main Asciidoctor publishing script
  do_spec_publish.sh        # Wrapper script
  setup_openehr_git.sh      # Clones/pulls all openEHR spec repos
  uml_generate.sh           # UML diagram extraction (MagicDraw)
docs/
  index.adoc                # Global class index (includes from sibling repos)
  boilerplate/              # Shared AsciiDoc includes used by all specs
    global_vars.adoc        # Global Asciidoctor attributes (URLs, releases, paths)
    basic_style_settings.adoc
    book_style_settings.adoc
    full_front_block.adoc   # Full front matter for specification documents
    short_front_block.adoc  # Short front matter variant
    licence_block.adoc
    doc_id_block.adoc
  references/
    reference_definitions.adoc  # All cross-spec and external reference URLs
    references.bib              # BibTeX bibliography (asciidoctor-bibtex)
  diagrams/                 # Shared diagram sources
  governance/               # Governance diagrams
resources/
  css/                      # Stylesheets (openehr.css, asciidoctor.css, etc.)
  js/                       # JavaScript (asciidoctor-tabs)
  logos/                    # openEHR logos (SVG, PNG)
  images/                   # CC licence badges
  *.yml                     # PDF theme files
manifest_template.json      # Template for component manifest.json files
Dockerfile                  # Docker image for Asciidoctor publishing
```

## Key Conventions

### AsciiDoc Authoring
- All specifications use AsciiDoc (`.adoc`) processed by Asciidoctor
- Boilerplate files are included via `include::{ref_dir}/docs/boilerplate/...`
- `{ref_dir}` resolves to this repo's root relative to the consuming spec repo
- Global variables in `global_vars.adoc` define all shared Asciidoctor attributes
- Reference definitions in `reference_definitions.adoc` define all cross-spec and external URLs
- Release attributes in `global_vars.adoc` set each component's published target:
  `:base_release:`, `:rm_release:`, `:am_release:` point to `latest`; all ITS
  components (`:its_release:`, `:its_rest_release:`, etc.) point to `development`

### Publishing
- `spec_publish.sh` is the main entry point; it finds `specifications-XX/docs/` directories and runs Asciidoctor
- Directory convention: component repos are siblings named `specifications-XX` (e.g., `specifications-RM`)
- Use `-r` flag for remote CSS, `-l Release-N.N.N` for release publishing
- Docker image: `openehr/asciidoctor` (built from root Dockerfile)

### Release Naming
- Releases: `Release-N.N.N` (e.g., `Release-1.0.4`)
- Fix releases: `Release-N.N.NvN` (e.g., `Release-1.0.4v1`)

## Plugin Development

Claude Code plugin development for openEHR goes into `/src/openehr/claude-plugins/`, **not** in this repository.

## When Editing

- **`global_vars.adoc`**: Changes here affect every specification document across all components. Be precise with attribute names and values.
- **`reference_definitions.adoc`**: Contains hundreds of URL definitions organized by component and external standard. Follow existing naming patterns (e.g., `:openehr_rm_latest_*:` for RM latest links).
- **Boilerplate includes**: Used by all spec documents; test changes against multiple components.
- **`spec_publish.sh`**: The publishing pipeline script. Changes affect all component builds.
- **`manifest_template.json`**: Template for component manifests; actual manifests live in each component repo.
  Valid `spec_status` values: `DEVELOPMENT | PAUSED | TRIAL | STABLE | SUPERSEDED | OBSOLETE | ARCHIVED`.
