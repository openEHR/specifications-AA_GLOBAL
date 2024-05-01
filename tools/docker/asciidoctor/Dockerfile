FROM asciidoctor/docker-asciidoctor

# we also need (wget, curl, git, bc) but they are available in asciidoctor default image

RUN apk update \
 && apk add jq \
 && rm -rf /var/cache/apk/*

RUN gem install pygments.rb \
    && gem install --prerelease asciidoctor-tabs

VOLUME /root/openEHR-specifications
WORKDIR /root/openEHR-specifications

