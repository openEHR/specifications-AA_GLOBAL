#!/bin/bash

# RUN THIS SCRIPT FROM THE DIRECTORY CONTAINING Git specifications-XX repo clones

#
# ============== Definitions =============
#
USAGE="${0} [-hlrpt] [component names]: generate publishing outputs; HTML by default 
  -f : force generation
  -h : output this help										
  -r : use remote CSS file location from website
  -p : generate PDF as well								
  -t : generate debug trace of asciidoctor-pdf back-end.
  -l release : use a specific release e.g. 'Release-1.0.3' - only use with a single component e.g. 'RM'

  Component names are the XX part of specifications directories with names of the form
  specifications-XX; 

  Examples:
    ${0} AM                      # publish AM component using local CSS
    ${0} -r AM                   # publish AM component using remote CSS
    ${0} -r                      # publish all components using remote CSS
    ${0} -l Release-2.0.5 -r AM  # publish AM components as Release-2.0.5, using remote CSS
"

NO_COMPONENTS_ERR="No components found. A 'component' is a name like 'AM', 'RM' etc, 
   that forms the final part of a directory with a name of the form 'specifications-XX'
"

COMPONENTS_RELEASE_ERR="When specifying a fixed release, only one component may be specified
"

#
# ============== functions =============
#

# run Asciidoctor with HTML backend
# args: $1 - outfile name minus extension
#       $2 - asciidoctor master source file name
# 		$3 - variable arguments, e.g. "-a rm_release=Release-1.0.3" (can be empty)
#
run_asciidoctor () {
	out_file=${1}.html

	# work out the options
	opts="$3 \
		-a current_year=$year \
		-a grammar_dir=$grammar_dir \
		-a global_ref_repo=$global_ref_repo \
		-a ref_dir=$ref_dir \
		-a stylesdir=$stylesdir \
		-a stylesheet=$stylesheet \
		-a uml_export_dir=$uml_export_dir \
		-a release=$release \
		--out-file=$out_file"

	asciidoctor ${opts} $2
	echo generated $(pwd)/$out_file
}

# run Asciidoctor with PDF backend
# args: $1 - outfile name minus extension
#       $2 - asciidoctor master source file name
# 		$3 - variable arguments, e.g. "-a rm_release=Release-1.0.3" (can be empty)
#
run_asciidoctor_pdf () {
	out_file=${1}.pdf

	# work out the options
	opts="$3 \
		-a current_year=$year \
		-a stylesdir=$stylesdir \
		-a grammar_dir=$grammar_dir \
		-a global_ref_repo=$global_ref_repo \
		-a ref_dir=$ref_dir \
		-a uml_export_dir=$uml_export_dir \
		-a release=$release \
		-a pdf-style=$pdf_theme \
		-a pdf-stylesdir=$ref_dir/resources \
		-a allow-uri-read \
		-r asciidoctor-pdf -b pdf \
		--out-file=$out_file"

	# -a pdf-fontsdir=path/to/fonts 
	if [ "$pdf_trace" = true ]; then
		opts="${opts} --trace"
	fi

	asciidoctor ${opts} $2
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

# relative location of UML directory under any specifications-XX directory
uml_source_dir=computable/UML

# relative location of UML file export directory from a specifications-XX/docs/xxx directory
uml_export_dir=../UML

specs_root_uri=https://www.openehr.org/releases
specs_root_ref_uri=$specs_root_uri/$global_ref_repo/latest

# ------------- static vars --------------
# specifications root dir: this directory must contain clones of all the specifications-XX repos
# as well as the adl-antlr repo.
spec_root=$PWD
echo "setting spec_root to $spec_root"

# directory of specifications-AA_GLOBAL repo clone from a specifications-XX/docs/xxx directory
# resolved during processing of this script
ref_dir=$spec_root/specifications-$global_ref_repo
echo "setting ref_dir to $ref_dir"

# generate a clean directory that can act as a URI for CSS; remove any
# cygdrive prefix added if we are running under cygwin
local_ref_uri=${PWD#/cygdrive/c}/specifications-$global_ref_repo

# Asciidoctor var: location of Antlr grammars
grammar_dir=$spec_root/adl-antlr/src/main/antlr/

# release id
default_release=latest
release=$default_release

use_remote_resources=false
force_generate=false
ad_varargs=""

#
# ================== main =================
#

# ---------- get the options ----------
while getopts "fhprtl:" o; do
    case "${o}" in
        f)
            force_generate=true
            ;;
        r)
            use_remote_resources=true
            ;;
        p)
            gen_pdf=true
            ;;
        t)
            pdf_trace=true
            ;;
        h)
            usage
            ;;
        l)
            release=$OPTARG
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

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
		component_args="${component_args} specifications-$1"
		shift
	done
	component_list=($component_args)
else
	component_list=$(ls -1d specifications-*)
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
	stylesdir=$specs_root_ref_uri/resources/css
else
	stylesdir=${local_ref_uri}/resources/css
fi
echo "setting stylesdir to $stylesdir"

# ---------- do the publishing ----------

for spec_component_dir in ${component_list[@]}; do 

	echo "========= cd $spec_component_dir =========="
	cd $spec_component_dir

	# get a timestamp of UML dir
	ts_uml="0.0"
	if [ -d $uml_source_dir ]; then
		ts_uml=`find $uml_source_dir -printf "%T@\n" | sort | tail -1`
	fi

	# process docs dir
	if [ -d docs ]; then
		# do the main documents first
		find docs -name $master_doc_name | while read docpath
		do
			docdir=$(dirname $docpath)
			docname=$(basename $docdir)
			olddir=$(pwd)

			echo -n "    ------------- checking $docdir "
			# check if target .html file is most recent; if not regenerate
			ts_src_docs=`find $docdir -printf "%T@\n" | sort | tail -1`
			latest_src_doc=`ls -1t $docdir | head -1`
			if [ "$force_generate" = true -o "$latest_src_doc" != "$docname.html" -o $(echo "$ts_uml > $ts_src_docs" | bc -l) -eq 1 ]; then
				echo " REBUILD ---------------"
				cd $docdir

				run_asciidoctor ${docname} $master_doc_name "${ad_varargs}"
				if [[ "$gen_pdf" = true ]]; then
					run_asciidoctor_pdf ${docname} $master_doc_name "${ad_varargs}"
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

			run_asciidoctor ${docname} $index_doc_name "${ad_varargs}"
			cd $olddir
		done
	fi

	echo 

	cd ${spec_root}
done

# cleanup 'http*' directories that bug in Asciidoctor 1.5.2 creates
# echo "*** remove junk http directories due to bug in Asciidoctor 1.5.2"
# find . -type d -name 'http*' -exec rm -rf {} \;

