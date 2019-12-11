# specifications-AA_GLOBAL
Global definitions, documents and scripts for openEHR

## How to set up the Asciidoctor publishing environment for the specifications

NOTE: a Linux-like environment is assumed; cygwin under Windows will work fine.

NOTE: in the below, if you are an openEHR SEC member, you may be doing direct clone + modify master or other branch; if you are not, you will most likely be cloning forked copies and doing pull requests in the usual way. From the point of view of publishing with Asciidoctor, there is no difference.

Firstly, you need to install asciidoctor. This is generally painless - [see here](https://asciidoctor.org).

Secondly you may need MagicDraw, since UML diagrams and definitions are extracted from the UML binary files via MagicDraw. Please contact the openEHR SEC if this is the case.

Now you need to clone the openEHR specifications repos, as follows:

1. Create a directory `openEHR-specifications` or similar to contain the specifications git repo clones
2. Download [this bash script](https://github.com/openEHR/specifications-AA_GLOBAL/blob/master/bin/setup_openehr_git.sh) into that directory and run it (needs to be Linux, cygwin, or other unix-like environment).

You are now ready to go. From the parent directory, in a bash shell, type:
```
$ ./do_spec_publish -r RM
```
This will publish the HTML documents for the RM component in `specifications-RM/docs`. You can do the same for any other component, e.g. BASE, QUERY etc.

To find out what else you can do, type:
```
$ ./do_spec_publish -h
```
