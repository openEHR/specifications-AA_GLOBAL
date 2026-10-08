# AGENTS.md

Guidance for AI coding agents working in **specifications-AA_GLOBAL**.

## What this repo is

Shared infrastructure for the openEHR specification publishing pipeline: global AsciiDoc attributes, boilerplate includes, URL/bibliography definitions, CSS/PDF themes, the publishing scripts, and the Docker image that runs them. It is **not** a specification itself; every `specifications-XX` component repo (RM, AM, BASE, LANG, PROC, SM, QUERY, CNF, TERM, ITS-*) consumes it, so a change here affects all of them. Default branch: `master`.

## Layout

```
bin/
  spec_publish.sh           # main publisher: finds specifications-XX/docs/**/master.adoc, runs Asciidoctor
  do_spec_publish.sh        # one-line wrapper; users copy it to the parent dir
  setup_openehr_git.sh      # clones/pulls all openEHR specifications-* repos (+ adl-antlr)
  uml_generate.sh           # retired: MagicDraw UML -> docs/UML; spec_publish.sh no longer calls it
  old_docs_fixer.sh         # one-off sed migration for old docs; run from inside a component repo
docs/
  index.adoc                # global class index; docs/index.html is its committed build output
  how-to.md                 # human how-to guide: clone, publish, change text, release (README.adoc links it)
  boilerplate/              # shared includes: global_vars, *_style_settings, full/short_front_block, licence_block, doc_id_block
  references/               # reference_definitions.adoc (~350 URL/link attributes) and references.bib (asciidoctor-bibtex)
  diagrams/, images/, governance/diagrams/   # shared figures
resources/
  css/, js/                 # openehr.css, asciidoctor-tabs; served from specifications.openehr.org with -r
  *.yml                     # PDF themes (openehr_full_pdf-theme.yml is the default)
  logos/, images/           # logos, CC licence badges
manifest_template.json      # template for each component's manifest.json
Dockerfile                  # publishing image (see below)
.github/workflows/docker-publish.yml   # manual build + push of the image to ghcr.io
```

## Build and publish

The image is `asciidoctor/docker-asciidoctor:latest` plus `jq` and the prerelease `asciidoctor-tabs` gem (diagram, bibtex, pdf, `bc` come from the base image). Its ENTRYPOINT is `spec_publish.sh -f -r -v -t -q -l`, so **the first argument is the release**, followed by exactly one component.

```bash
# render a component with the published image: run from the PARENT dir that holds all specifications-XX clones
cd /src/openehr
docker run --rm -u $(id -u):$(id -g) -v "$PWD:/documents/" ghcr.io/openehr/asciidoctor development BASE
docker run --rm -u $(id -u):$(id -g) -v "$PWD:/documents/" ghcr.io/openehr/asciidoctor Release-1.0.1 QUERY

# shell inside the image (bypasses the entrypoint)
docker run --rm -it -u $(id -u):$(id -g) -v "$PWD:/documents/" --entrypoint bash ghcr.io/openehr/asciidoctor

# or test local Dockerfile changes: build a local copy, then use `openehr/asciidoctor` in the commands above
docker build -t openehr/asciidoctor specifications-AA_GLOBAL
```

The published image `ghcr.io/openehr/asciidoctor` is built by `.github/workflows/docker-publish.yml`:

- **Manual only** (`workflow_dispatch`); the workflow file must be on `master` before "Run workflow" appears in the Actions tab.
- Mirrors the `docker` job of `bmm-publisher`'s `release.yml` (same actions, `linux/amd64`), plus a smoke test (asciidoctor, jq, bc, `spec_publish.sh`, four gems) before the push.
- Tags: `latest` (only when run on `master`) and `sha-<short>`. Untick `push` for a build-and-test dry run.
- `IMAGE_NAME` is set explicitly: `github.repository` would give `specifications-aa_global`.

## Gotchas

- `spec_publish.sh` derives `ref_dir`, `base_dir` and `grammar_dir` from `$PWD`, so `specifications-AA_GLOBAL`, `specifications-BASE` and `adl-antlr` must be sibling clones of the component being built.
- `-l <release>` is only valid with a single component and sets `<component lowercased>_release`; for a hyphenated component (`ITS-REST`) that is `its-rest_release`, not the `its_rest_release` defined in `global_vars.adoc` (from reading the script, untested).
- To get the script's own help, bypass the entrypoint (`--entrypoint spec_publish.sh image -h`); `docker run image -h` passes `-h` as the release.
- `manifest_vars.adoc` is generated into each `docs/<doc>/` from the component's `manifest.json` on every publish; never hand-edit it.
- Class tables and diagrams in `docs/UML` are generated from each component's BMM by `bmm-publisher`, never hand-edited. `spec_publish.sh` no longer runs the MagicDraw extraction (`uml_generate.sh`, which used to delete `docs/UML/classes` and `docs/UML/diagrams` first), and `-u` is ignored. A `computable/UML/*.mdzip` left in a component repo is no longer read.
- The base image is unpinned (`:latest`), so rebuilding the image can change tool versions without any change in this repo.

## Editing

- **`global_vars.adoc`**: defines every shared attribute for all documents. Component release attributes (`:base_release:`, `:rm_release:`, `:am_release:`, ...) are `latest`; all `:its_*_release:` are `development`. Be precise with names and values.
- **`reference_definitions.adoc`**: follow the existing naming (e.g. `:openehr_rm_latest_*:` for RM latest links), grouped by component and external standard.
- **Boilerplate includes** (`{ref_dir}/docs/boilerplate/...`; `{ref_dir}` is this repo as seen from the consuming repo): test a change against more than one component.
- **`spec_publish.sh`, `Dockerfile`**: affect every component build; keep the Dockerfile ENTRYPOINT flags and the examples in `README.adoc` and `docs/how-to.md` in sync.
- **`manifest_template.json`**: actual manifests live in each component repo. Valid `spec_status`: `DEVELOPMENT | PAUSED | TRIAL | STABLE | SUPERSEDED | OBSOLETE | ARCHIVED`.
- Releases are named `Release-N.N.N`; fix releases `Release-N.N.NvN` (e.g. `Release-1.0.4v1`). The full release procedure is in `docs/how-to.md`.

## Conventions

- Commit subjects follow the existing history: short, lowercase, describing the change (e.g. `adding :openehr_bmm3: and :openehr_lang_latest_bmm3: references`).
- openEHR AI plugins live in the sibling `ai-plugins` repo, not here. Spec-authoring skills (`openehr-specs:*`) apply in the component repos.
