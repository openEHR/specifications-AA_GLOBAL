# specifications-AA_GLOBAL
Global definitions, documents and scripts for openEHR

## How to set up the Asciidoctor publishing environment for the specifications

NOTE: a Linux-like environment is assumed; cygwin under Windows will work fine.

NOTE: in the below, if you are an openEHR SEC member, you may be doing direct clone + modify master or other branch; if you are not, you will most likely be cloning forked copies and doing pull requests in the usual way. From the point of view of publishing with Asciidoctor, there is no difference.

Firstly, you need to install asciidoctor. This is generally painless - [see here](https://asciidoctor.org).

Secondly you may need MagicDraw, since UML diagrams and definitions are extracted from the UML binary files via MagicDraw. Please contact the openEHR SEC if this is the case.

Now you need to clone this repo, and set up the publisher script:

1. Create a directory `openEHR-specifications` or similar in which you will clone the various specifications repositories.
2. clone this repository into that directory, along with any other specifications-xx repositories you are working on
3. copy the script /bin/do_spec_publish.sh into the parent directory of your cloned repos, e.g. `openEHR-specifications`.

You are now ready to go. From the parent directory, in a bash shell, type:
```
$ ./do_spec_publish -r RM
```
This will publish the HTML documents for the RM component in `specifications-RM/docs`. You can do the same for any other component, e.g. BASE, QUERY etc.

To find out what else you can do, type:
```
$ ./do_spec_publish -h
```
