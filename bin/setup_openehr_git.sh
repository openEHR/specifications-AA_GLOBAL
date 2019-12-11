#!/bin/bash

# script to clone all specifications related repos from openEHR Github area
# and set up some useful scripts for the user

# -------------- GitHub clones --------------
# context = orgs | users
context="orgs"
name="openEHR"

# repo keys
repo_keys='specifications-|adl-antlr|asciidoctor-stylesheet-factory'

read -p "About to clone specifications repos from $name @ Github into directory $PWD; continue[Yy]? "
if [[ $REPLY =~ ^[Yy]$ ]]; then
	# Do the specifications-* repos first
	repo_urls=`curl -s "https://api.github.com/$context/$name/repos?per_page=200" | grep -w clone_url`
	echo "$repo_urls" | grep -E "$repo_keys" | cut -d \" -f 4 |  while read repo_clone_url ; do
		repo=`echo $repo_clone_url | sed 's/^.*\/\([^/]+\)\.git/$1/'`
		if [ -d $repo ]; then
			echo "$repo already cloned; skipping"
		else
			git clone $repo_clone_url
		fi
	done
fi

# -------------- Copy scripts --------------
control_repo="specifications-AA_GLOBAL"
if [ -d $control_repo ]; then
	cp $control_repo/bin/do_*.sh .
else
	echo "Control repo $control_repo not cloned"
fi

exit 0
