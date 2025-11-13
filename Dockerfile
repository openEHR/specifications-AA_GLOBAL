FROM asciidoctor/docker-asciidoctor:latest

# we also need:
#   - with `apk add`: [wget, curl, git, bc]
#   - with `gem install`: [asciidoctor-diagram asciidoctor-diagram-plantuml asccidoctor-bibtext]
# but they are available in asciidoctor default image

RUN apk update \
    && apk add jq \
    && gem install --prerelease \
      asciidoctor-tabs \
    && rm -rf /var/cache/apk/*

COPY bin/*.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/spec_publish.sh"]

