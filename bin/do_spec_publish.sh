#!/bin/bash
#
# For convenience, copy this script to the parent directory of the specifications-AA_GLOBAL repo, and invoke it from there
# Use ./do_spec_publish.sh -h to find out the options. The most typical command line is:
#     ./do_spec_publish.sh -r RM # or BASE or PROC or any other component name
#

specifications-AA_GLOBAL/bin/spec_publish.sh "$@"
