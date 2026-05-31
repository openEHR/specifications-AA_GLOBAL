FROM asciidoctor/docker-asciidoctor:latest

# we also need:
#   - with `apk add`: [wget, curl, git, bc]
#   - with `gem install`: [asciidoctor-diagram asciidoctor-diagram-plantuml asciidoctor-bibtex]
# but they are available in asciidoctor default image

RUN apk add --no-cache jq \
    && gem install --no-document --prerelease \
      asciidoctor-tabs

COPY bin/*.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/spec_publish.sh", "-f", "-r", "-v", "-t", "-q", "-l"]

