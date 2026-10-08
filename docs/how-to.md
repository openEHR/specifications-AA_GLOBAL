# How to publish and release specifications

This guide covers the tasks around the openEHR publishing pipeline: rendering a component's documents to HTML, changing specification text, releasing a component, and fixing a release. It assumes you work with Git and a shell.

A component (RM, AM, LANG, PROC and so on) is the unit of release. Each component has its own `specifications-XX` repository and includes the shared files from this repository.

## Clone the repositories

Publishing needs this repository, the component repositories and `adl-antlr` side by side in one directory.

1. Create a directory to hold the clones, for example `openEHR-specifications`.
2. Download [`bin/setup_openehr_git.sh`](https://github.com/openEHR/specifications-AA_GLOBAL/blob/master/bin/setup_openehr_git.sh) into it. The script needs Linux, cygwin or another Unix-like environment.
3. Run it from that directory:

   ```bash
   bash setup_openehr_git.sh
   ```

The script asks for confirmation, then clones every `specifications-*` repository, `adl-antlr` and `asciidoctor-stylesheet-factory`, or runs `git pull` in those already cloned. It also copies `do_spec_publish.sh` into the current directory.

To publish changes made later, run the script again to pull them, then publish.

## Publish with Docker

Run the commands in this section from the directory that holds the clones.

Pull the published image:

```bash
docker pull ghcr.io/openehr/asciidoctor:latest
```

Or build it from the root of this repository, and use `openehr/asciidoctor` instead of `ghcr.io/openehr/asciidoctor` in the commands below:

```bash
docker build -t openehr/asciidoctor .
```

The image's entrypoint is `spec_publish.sh -f -r -v -t -q -l`, so the first argument is the release and the second is the component. Use `development` for a normal build and `Release-N.N.N` for a release build:

```bash
docker run --rm -u $(id -u):$(id -g) -v "$(pwd):/documents/" ghcr.io/openehr/asciidoctor development RM
docker run --rm -u $(id -u):$(id -g) -v "$(pwd):/documents/" ghcr.io/openehr/asciidoctor Release-1.0.1 QUERY
```

The HTML is written to the component's `docs` directory, for example `specifications-RM/docs`. A release build accepts exactly one component.

To work inside the container, bypass the entrypoint and call the script yourself:

```bash
docker run --rm -it -u $(id -u):$(id -g) -v "$(pwd):/documents/" --entrypoint bash ghcr.io/openehr/asciidoctor
```

```bash
./specifications-AA_GLOBAL/bin/spec_publish.sh -f -r -v -t -q -l development RM
```

## Publish without Docker

Install these tools, then publish from the directory that holds the clones.

- Asciidoctor ([installation](https://asciidoctor.org)).
- The gems `asciidoctor-diagram`, `asciidoctor-diagram-plantuml`, `asciidoctor-bibtex`, `asciidoctor-tabs` and `pygments.rb`, plus `asciidoctor-pdf` if you want PDF output (`-p`).
- Python, `jq` and `bc`.

```bash
./do_spec_publish.sh -r RM
```

This publishes the RM documents into `specifications-RM/docs`. Replace `RM` with any other component, for example `BASE` or `QUERY`. `-r` uses the stylesheets from the specifications website. Run `./do_spec_publish.sh -h` for the other options.

## Change specification text

Edit the `.adoc` files directly, except for the class definitions in `docs/UML/classes`. Those files are generated, and the next generation run overwrites any edit made in them.

- Edit the component's BMM file and regenerate the class files with [bmm-publisher](https://github.com/openEHR/bmm-publisher). The publishing script no longer extracts class files from MagicDraw UML models.

## Release a component

A release is named `Release-N.N.N`, where `N.N.N` is a semver-style three-part id such as `1.2.14`. A new version of an existing release is named `Release-N.N.NvN`, with a trailing `vN` (see [Fix a release](#fix-a-release)). The steps below use `RM Release-1.0.4` as the example.

### Close the Jira work

When all change requests (CRs) in the component's Jira project (for example `SPECRM`) are done, resolve and close every CR and problem report (PR). Then create the saved searches for the PRs and CRs of this release. Their URLs have the form `<jira-home>/projects/SPECPR/versions/NNNNN` for PRs and `<jira-home>/projects/SPECRM/versions/NNNNN` for CRs. You need both ids for `manifest.json`.

### Prepare and tag the release

Work in the component's clone, for example `specifications-RM`.

1. Make every last change to the specification files.
2. In `manifest.json`, check that:
   - `spec_status` is correct for each entry under `specifications`. This release may promote a specification, for example from `TRIAL` to `STABLE`.
   - the entry under `releases` for this release has the correct Jira links and the current date. When needed, prepend a new `cooking` release with an empty date.
3. Create a branch named after the release and check it out. Your remaining changes go on this branch, which becomes the release's maintenance branch.

   ```bash
   git switch -c Release-1.0.4
   ```

4. Publish in release mode, as often as needed, and check the front page and preface page of each specification's HTML output:

   ```bash
   ./do_spec_publish.sh -r -l Release-1.0.4 RM
   ```

5. Commit all changes locally.
6. Add an annotated tag with the release id and a short description:

   ```bash
   git tag -a Release-1.0.4 -m "RM Release 1.0.4"
   ```

7. Push the branch and the tag to GitHub.
8. Switch back to `master` for later work.

### What happens after the push

The push causes a normal commit on GitHub. A webhook makes the `specifications.openehr.org` server pull the repository and copy out the latest commit, plus any tagged commit not yet copied. The copies go to `Release-N.N.N` and `latest` under `/var/www/vhosts/openehr.org/specifications.openehr.org/releases/COMPONENT`. Right after a release the two are the same. Otherwise usually only `latest` is updated. This is how the site serves both the working version and every earlier release.

## Fix a release

If someone finds a significant error in a released specification, including its diagrams, fix it on the release branch.

1. Check out the release branch, for example `Release-1.0.4`.
2. Change the source files.
3. Publish again with the original release id:

   ```bash
   ./do_spec_publish.sh -r -l Release-1.0.4 RM
   ```

4. Commit the changes.
5. Add an annotated tag with the id `Release-N.N.NvN+1`, for example `Release-1.0.4v1`. The final number is one higher than the previous fix release, so it can be `Release-1.0.4v7` if errors were found over time.
6. Push the commits and the tag. The server scripts overwrite the earlier copy of the release with the new one.
7. Merge the changes into the component's `master` branch, unless they are already there.
