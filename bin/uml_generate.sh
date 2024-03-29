#!/bin/bash

#
# Note that the version of java needed in the final invocation of this script is Java8, required
# MagicDraw19. Here we use the name 'java8' which should be a logical alias to the Java8 location on your
# machine, or else it could just be an alias for 'java' if your default Java is Java8.
# This can be achieved with bash 'alias' plus the command 'shopt -s expand_aliases', or else a function:
#
#     function java8 () {
#    	command /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java "$@";
#	  };
#	  export -f java8
#

if [ -z "$MAGICDRAW_HOME" ]; then
    echo "MAGICDRAW_HOME environment variable not set, please set it to the MagicDraw installation folder"
    exit 1
fi

# Figure out the MD home 'URL' leader, which is needed for the -Dmd.class.path param below
# We look for $OS which should be set to Windows_NT on cygwin, and either something else or nothing on other unix/OSX
# Then mangle it to make it the proper URL form of a file system location - replace spaces, remove ':', precede with /
# We also set the Classpath delimiter properly, since it's different on different platforms.

if [ "$OS" = Windows_NT ]; then
	md_home_url_leader=$(echo "$MAGICDRAW_HOME" | sed -e 's/^/\//' -e 's/ /%20/g')
	md_home_url_base=$(echo "$MAGICDRAW_HOME" | sed -e 's/:/%3A/g' -e 's/ /%20/g' -e 's/\//%2F/g')
	cp_delim=";"
else
	md_home_url_leader=${MAGICDRAW_HOME}
	md_home_url_base=${MAGICDRAW_HOME}
	cp_delim=":"
fi
md_cp_url=file:$md_home_url_leader/bin/magicdraw.properties?base=$md_home_url_base#CLASSPATH
echo md_cp_url = $md_cp_url

OSGI_LAUNCHER=$(echo "$MAGICDRAW_HOME"/lib/com.nomagic.osgi.launcher-*.jar)
OSGI_FRAMEWORK=$(echo "$MAGICDRAW_HOME"/lib/bundles/org.eclipse.osgi_*.jar)
MD_OSGI_FRAGMENT=$(echo "$MAGICDRAW_HOME"/lib/bundles/com.nomagic.magicdraw.osgi.fragment_*.jar)
 
CP="${OSGI_LAUNCHER}${cp_delim}${OSGI_FRAMEWORK}${cp_delim}${MD_OSGI_FRAGMENT}${cp_delim}\
`  `$MAGICDRAW_HOME/lib/md_api.jar${cp_delim}$MAGICDRAW_HOME/lib/md_common_api.jar${cp_delim}\
`  `$MAGICDRAW_HOME/lib/md.jar${cp_delim}$MAGICDRAW_HOME/lib/md_common.jar${cp_delim}\
`  `$MAGICDRAW_HOME/lib/jna.jar"

java8 -Xmx1200M -Xss1024K \
       -Dmd.class.path=$md_cp_url \
       -Dcom.nomagic.osgi.config.dir="$MAGICDRAW_HOME/configuration" \
       -Desi.system.config="$MAGICDRAW_HOME/data/application.conf" \
       -Dlogback.configurationFile="$MAGICDRAW_HOME/data/logback.xml" \
       -Dcom.nomagic.magicdraw.launcher=org.openehr.adoc.magicdraw.UmlAdocExporterCommandLine  \
       -cp "$CP" \
       -Dmd.additional.class.path="$MAGICDRAW_HOME/plugins/org.openehr.adoc.magicdraw/UmlAdocExporter.jar"  \
       com.nomagic.osgi.launcher.ProductionFrameworkLauncher "$@"
