#!/bin/bash

# This script will run asciidoctor on documents found under a directory structure
# which is by default specifications-XX/docs/xxxx, or with the -n option, just
# dddd/docs/xxxx.

#
# ============== Definitions =============
#
def_dir_leader="specifications-"
dir_leader=${def_dir_leader}


USAGE="${0} [-nfuhrptv] [-m pub_hom_dir] [-l release] [component names]: generate publishing outputs; HTML by default 
  -f : force document regeneration
  -n : turn off default directory pattern ${def_dir_leader}
  -u : force UML regeneration
  -h : output this help										
  -r : use remote CSS file location from website
  -p : generate PDF as well								
  -q : generate class name files qualified by package names
  -t : generate debug trace of asciidoctor-pdf back-end.
  -m dir : set a specific publishing home location; default is parent of openEHR specs dirs
  -l release : use a specific release e.g. 'Release-1.0.3' - only use with a single component e.g. 'RM'
  -w : turn on missing attribute warnings
  -v : turn on asciidoctor verbose mode

  Component names are the XX part of specifications directories with names of the form
  ${def_dir_leader}XX; 

  Examples:
    ${0} AM                      # publish AM component using local CSS
    ${0} -r AM                   # publish AM component using remote CSS
    ${0} -r                      # publish all components using remote CSS
    ${0} -l Release-2.0.5 -r AM  # publish AM components as Release-2.0.5, using remote CSS
"

NO_COMPONENTS_ERR="No components found. A 'component' is a name like 'AM', 'RM' etc, 
   that forms the final part of a directory with a name of the form '${def_dir_leader}XX'
"

COMPONENTS_RELEASE_ERR="When specifying a fixed release, only one component may be specified
"

#
# ============== functions =============
#

# run Asciidoctor with HTML backend
# args: $1 - outfile name minus extension
#       $2 - outdir
#       $3 - asciidoctor master source file name
# 		$4 - variable arguments, e.g. "-a rm_release=Release-1.0.3" (can be empty)
#
run_asciidoctor () {
	out_file=${2}${1}.html

	# work out the options
	opts="$4 \
		-a current_year=$year \
		-a grammar_dir=$grammar_dir \
		-a global_ref_repo=$global_ref_repo \
		-a component=$component \
		-a ref_dir=$ref_dir \
		-a base_dir=$base_dir \
		-a stylesdir=$stylesdir \
		-a stylesheet=$stylesheet \
		-a scriptsdir=$scriptsdir \
		-a release=$release \
		-a doc_name=${1} \
		-a allow-uri-read \
		-r asciidoctor-diagram \
		-r asciidoctor-tabs -a tabs-stylesheet=asciidoctor-tabs.css \
		-r asciidoctor-bibtex -a bibtex-file=$ref_dir/docs/references/references.bib"

	# -w missing attribute warnings
	if [ "$warn_missing_attrs" = true ]; then
		opts="${opts} -a attribute-missing=warn"
	fi

	# -v verbose
	if [ "$verbose_mode" = true ]; then
		opts="${opts} -v"
	fi

	# -q package_qualifiers
	if [ "$package_qualifiers" = true ]; then
		opts="${opts} -a package_qualifiers"
	fi

	# -t trace
	if [ "$trace" = true ]; then
		opts="${opts} --trace"
	fi

	asciidoctor ${opts} --out-file=$out_file $3
		
	echo generated $(pwd)/$out_file
}

# run Asciidoctor with PDF backend
# args: $1 - outfile name minus extension
#       $2 - outdir
#       $3 - asciidoctor master source file name
# 		$4 - variable arguments, e.g. "-a rm_release=Release-1.0.3" (can be empty)
#
run_asciidoctor_pdf () {
	out_file=${2}${1}.html

	# work out the options
	opts="$4 \
		-a attribute-missing=warn \
		-a current_year=$year \
		-a stylesdir=$stylesdir \
		-a grammar_dir=$grammar_dir \
		-a global_ref_repo=$global_ref_repo \
		-a component=$component \
		-a ref_dir=$ref_dir \
		-a base_dir=$base_dir \
		-a release=$release \
		-a doc_name=${1} \
		-a allow-uri-read \
		-a pdf-style=$pdf_theme \
		-a pdf-stylesdir=$ref_dir/resources \
		-r asciidoctor-bibtex -a bibtex-file=$ref_dir/docs/references/references.bib"

	# -w missing attribute warnings
	if [ "$warn_missing_attrs" = true ]; then
		opts="${opts} -a attribute-missing=warn"
	fi

	# -v verbose
	if [ "$verbose_mode" = true ]; then
		opts="${opts} -v"
	fi

	# -q package_qualifiers
	if [ "$package_qualifiers" = true ]; then
		opts="${opts} -a package_qualifiers"
	fi

	# -t trace
	if [ "$trace" = true ]; then
		opts="${opts} --trace"
	fi

	asciidoctor ${opts} -r asciidoctor-pdf -b pdf --out-file=$out_file $3
	echo generated $(pwd)/$out_file
}

# run a command in a standard way
# $1 = command string
do_cmd () {
	echo "------ Running: $1"
	eval $1 2>&1
}

usage() { echo "$USAGE" 1>&2; exit 1; }

#
# ================== main =================
#

# ------------- static vars --------------
year=`date +%G`
stylesheet=openehr.css
pdf_theme=openehr_full_pdf-theme.yml
master_doc_name=master.adoc
index_doc_name=index.adoc
global_ref_repo=AA_GLOBAL
uml_gen_dir=docs/UML/classes

manifest_file=manifest.json
manifest_vars_file=manifest_vars.adoc

# relative location of UML directory under any specifications-XX directory
uml_source_dir=computable/UML
uml_root_package="openehr"

specs_root_uri=https://specifications.openehr.org
specs_css_uri=$specs_root_uri/styles
specs_js_uri=$specs_root_uri/js

# ------------- static vars --------------
# release id
default_release=latest
release=$default_release

use_remote_resources=false
force_generate=false
ad_varargs=""

# if this is true, the file names of class files will
# include package names, i.e. be of the form pkg.pkg.class.ext
# rather than just class.ext. Useful to avoid clashes of same
# named classes from different packages.
# package_qualifiers=

#
# ================== main =================
#

# ---------- get the options ----------
while getopts "nfuhpqrtwvm:l:" o; do
    case "${o}" in
        n)
            dir_leader=""
            ;;
        f)
            force_generate=true
            ;;
        u)
            uml_force_generate=true
            ;;
        r)
            use_remote_resources=true
            ;;
        p)
            gen_pdf=true
            ;;
        q)
            package_qualifiers=true
            ;;
        t)
            trace=true
            ;;
        h)
            usage
            ;;
        l)
            release=$OPTARG
            ;;
        m)
            pub_home=$OPTARG
            ;;
        w)
            warn_missing_attrs=true
            ;;
        v)
            verbose_mode=true
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# specifications root dir: this directory must contain clones of all the specifications-XX repos
# as well as the adl-antlr repo.
work_root=$PWD
pub_home=${pub_home:-$PWD}
echo "setting pub_home to $pub_home"
echo "setting work_root to $work_root"

# directory of specifications-AA_GLOBAL repo clone from a specifications-XX/docs/xxx directory
# resolved during processing of this script
ref_dir=$pub_home/specifications-$global_ref_repo
echo "setting ref_dir to $ref_dir"

# set the following only for re-publishing old releases
base_dir=$pub_home/specifications-BASE
echo "setting base_dir to $base_dir"

# generate a clean directory that can act as a URI for CSS; remove any
# cygdrive prefix added if we are running under cygwin
local_ref_uri=${PWD#/cygdrive/c}/specifications-$global_ref_repo

# Asciidoctor var: location of Antlr grammars
grammar_dir=$pub_home/adl-antlr/src/main/antlr/

# Generate special release Asciidoctor option if 'release' was set; only one component is allowed
# in this case, because releases are component specific.
if [ "$release" != "$default_release" ]; then
	if [ $# -ne 1 ]; then
		echo "$COMPONENTS_RELEASE_ERR"
		exit
	else
		# if a release was specified, then for the component, we set an Asciidoctor variable to that release
		# e.g. if component was 'RM' and release = 'Release-1.0.3', then construct a variable string for the
		# Asciidoctor call as 'rm_release=Release-1.0.3'
		
		rel_var=$(echo $1 | tr '[:upper:]' '[:lower:]')_release
		echo " ****** process $1 at release $release (setting $rel_var)"

		# create additional argument string to be passed to asciidoctor function to set release
		ad_varargs="-a $rel_var=$release "
		echo " ****** adoc varargs = $ad_varargs"
	fi
fi

# see if there are individual args like 'AM', 'RM' etc
if [ $# -ge 1 ]; then
	while [ $# -ge 1 ]; do
		component_args="${component_args} ${dir_leader}$1"
		shift
	done
	component_list=($component_args)
else
	component_list=$(ls -1d ${dir_leader}*)
fi

# determine component list
if [ ${#component_list[@]} -eq 0 ]; then
	echo "$NO_COMPONENTS_ERR"
	exit
else
	echo "+++++++++ Processing components: "
	for i in ${component_list[@]}; do echo $i; done
fi

# set some config vars based on command line
if [[ "$use_remote_resources" = true ]]; then
	echo "using remote CSS location"
	stylesdir=$specs_css_uri
	scriptsdir=$specs_js_uri
else
	stylesdir=${local_ref_uri}/resources/css
	scriptsdir=${local_ref_uri}/resources/js
fi
echo "setting stylesdir to $stylesdir"

# ---------- do the publishing ----------

for component_dir in ${component_list[@]}; do 

	echo "========= cd $component_dir =========="
	cd $component_dir
	component=${component_dir#"$dir_leader"}

	# re-run UML extractor to create UML doc files if applicable
	# get a timestamp of UML dir
	ts_uml="0.0"
	ts_uml_docs="0.0"
	if [ -d $uml_source_dir ]; then
		ts_uml=`find $uml_source_dir -printf "%T@\n" | sort | tail -1`

		# get a timestamp of the generated UML docs dir
		if [ -d $uml_gen_dir ]; then
			if [ "$(ls -A $uml_gen_dir)" ]; then
				ts_uml_docs=`find $uml_gen_dir -name '*.adoc' -printf "%T@\n" | sort | tail -1`
			else
				uml_docs_empty=true
			fi
		fi

		# if UML source newer than UML docs or no UML docs, regenerate
		uml_file="computable/UML/openEHR_UML-$component.mdzip"
		uml_regen_cmd="$ref_dir/bin/uml_generate.sh -d svg -i "{%s_release}" -r $uml_root_package ${package_qualifiers:+-q} -c $component -o docs/UML $uml_file" 
		if [[ "$uml_force_generate" = true || \
			  "$uml_docs_empty" = true || \
			  $(echo "$ts_uml > $ts_uml_docs" | bc -l) -eq 1 && -f $uml_file \
		]]; then
			rm -f docs/UML/classes/*.*
			rm -f docs/UML/diagrams/*.*

			echo "$uml_regen_cmd"
			eval $uml_regen_cmd

			# regenerate timestamp of the generated UML docs dir
			ts_uml_docs=`find $uml_gen_dir -name '*.adoc' -printf "%T@\n" | sort | tail -1`
		fi
	fi

	#
	# process the manifest file to generate a manifest_vars.adoc file in each
	# docs/<doc> directory
	#
	if [ -f $manifest_file ]; then
		echo "    ---- processing $manifest_file ----"

		#
		# extract a string of the form:
		#
		# :id: task_planning
		# :spec_title: Task Planning (TP) Specification
		# :copyright_year: 2017
		# :spec_status: TRIAL
		# :keywords: workflow, task, planning, EHR, EMR, reference model, openehr
		# :description: openEHR Task Planning specification
		# :id: tp_vml
		# :spec_title: Task Planning Visual Modelling Language (TP-VML)
		# :copyright_year: 2017
		# :spec_status: TRIAL
		# :keywords: task planning, visual language, workflow
		# :description: openEHR Task Planning Visual Modelling Language

		cat $manifest_file  | jq '.specifications[] | 
			{id: .id, spec_title: .title, copyright_year: .copyright_year, spec_status: .spec_status, keywords: .keywords, description: .description}' | 
			sed -e '/[{}]/d' -e 's/^  /:/' -e 's/"//g' -e s/,$// | while read line 
		do
			if [[ "$line" == ":id:"* ]]; then
				doc_name=`echo $line | sed -e 's/:id: //'`
				doc_dir=docs/$doc_name
				out_path=$doc_dir/$manifest_vars_file
				if [ -d $doc_dir ]; then
					echo "    writing $out_path"
					echo -n > $out_path
				fi
			else
				if [ -d $doc_dir ]; then
					echo $line >> $out_path
				fi
			fi
		done
	fi

	# process docs dir
	if [ -d docs ]; then
		# do the main documents first
		find docs -name $master_doc_name | while read docpath ; do
			docdir=$(dirname $docpath)
			docname=$(basename $docdir)
			olddir=$(pwd)

			echo -n "    ------------- checking $docdir "
			# check if target .html file is most recent; if not regenerate (note, we exclude the newly-created manifest file
			ts_src_docs=`find $docdir ! -name "$manifest_vars_file" -printf "%T@\n" | sort | sed -e /$manifest_vars_file/d | tail -1`
			ts_main_manifest=`stat -c %Y $manifest_file`
			ts_out_doc=`stat -c %Y $docdir.html`
			if [[ "$force_generate" = true || \
				! -f "$docdir.html" || \
				$(echo "$ts_src_docs > $ts_out_doc" | bc -l) -eq 1 || \
				$(echo "$ts_main_manifest > $ts_out_doc" | bc -l) -eq 1 || \
				$(echo "$ts_uml_docs > $ts_out_doc" | bc -l) -eq 1 \
			]]; then
				echo " REBUILD ---------------"
				cd $docdir

				run_asciidoctor ${docname} '../' $master_doc_name "${ad_varargs}"
				if [[ "$gen_pdf" = true ]]; then
					run_asciidoctor_pdf ${docname} '../' $master_doc_name "${ad_varargs}"
				fi
				cd $olddir
			else
				echo " ---------------"
			fi
		done

		# look for index files
		find docs -name $index_doc_name | while read docpath
		do
			docdir=$(dirname $docpath)
			docname=index
			olddir=$(pwd)

			echo "    ------------- cd $docdir ---------------"
			cd $docdir

			run_asciidoctor ${docname} './' $index_doc_name "${ad_varargs}"
			cd $olddir
		done
	fi

	echo 

	cd ${work_root}
done

# cleanup 'http*' directories that bug in Asciidoctor 1.5.2 creates
# echo "*** remove junk http directories due to bug in Asciidoctor 1.5.2"
# find . -type d -name 'http*' -exec rm -rf {} \;

