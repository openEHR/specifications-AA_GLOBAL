#!/bin/bash
#
# Look in all the specification-* directories and run any UML extractor script there. This is 
# only needed if you want to regenerate all UML in one go. Normally, you will just use the
# do_spec_publish.sh script to publish whichever component you want.
#
# Copy this script to the parent directory of the specifications-AA_GLOBAL repo, and invoke it from there.
#

component_list=$(ls -1d specifications-*)

for spec_component_dir in ${component_list[@]}; do 

	echo "========= cd $spec_component_dir =========="
	cd $spec_component_dir

	find . -name 'do_uml*.sh' | while read uml_gen
	do
		echo "    ---------- running $uml_gen ----------"
		./$uml_gen
	done

	echo 

	cd ..
done

