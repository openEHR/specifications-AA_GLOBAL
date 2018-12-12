#!/bin/bash

# Run from in specifications-XXX directory

find docs -path docs/UML -prune -o -name '*.adoc' -exec sed -i -e 's/{uml_export_dir}\/diagrams/{uml_diagrams_uri}/' -e 's/image::diagrams\//image::{diagrams_uri}\//'  -e 's/image::diagrams\//image::{diagrams_uri}\//' {} \;

find docs -path docs/UML -prune -o -name 'master00-amendment_record.adoc' -exec sed -i -e 's#{openehr_jira}/SPEC#{spec_tickets}/SPEC#g' {} \;

find docs -path docs/UML -prune -o -name 'master00-amendment_record.adoc' -exec sed -i -e 's#\(-[0-9]*\)]#\1^]#g' {} \;


