FROM ubuntu:18.04

RUN apt-get update \
    && apt-get install -y wget curl git \
    && apt-get clean

RUN apt-get install -y python3 ruby jq bc \
    && apt-get clean

RUN gem install asciidoctor asciidoctor-bibtex pygments.rb

VOLUME /root/openEHR-specifications
WORKDIR /root/openEHR-specifications

