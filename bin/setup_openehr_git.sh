#!/bin/bash

# script to clone all specifications related repos from openEHR Github area

# context = orgs | users
context="orgs"

# name = openEHR
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
			echo "git clone $repo_clone_url"
		fi
	done
fi

exit 0
