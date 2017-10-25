#!/bin/bash

WHEREAMI=$(dirname $(realpath $0))
. "$WHEREAMI"/sourceme

PROJECTDIR=`dirname "$WHEREAMI"`

SOURCEDIR=$PROJECTDIR/source
TARGETDIR=$PROJECTDIR/target

if [ -d "$TARGETDIR" ]
then
    rm -Rf "$TARGETDIR"
fi

mkdir "$TARGETDIR"

cp -L -R "$SOURCEDIR"/* "$TARGETDIR"
rm "$TARGETDIR"/*.xml
rm "$TARGETDIR"/xslt/*.xslt
rm -Rf "$TARGETDIR"/*/notused

VERSIONINFO=`git describe --tags`
# Transform index.xml to index.html:
$JAVACMD -classpath "$SAXONJAR" net.sf.saxon.Transform "$SOURCEDIR"/index.xml "$WHEREAMI"/generate-gtb-html-files.xslt "$@" >"$TARGETDIR"/index.html "VERSIONINFO=$VERSIONINFO"

# Compile Saxon-JS XSLT stylesheet"
# ### This requires Saxon-EE. Therefore, compile the stylesheet in the source folder using Oxygen
#$JAVACMD -classpath "$SAXONJAR" net.sf.saxon.Transform -t -xsl:"$SOURCEDIR"/xslt/gtb.xslt -export:$TARGETDIR"/xslt/gtb.sef -target:JS -nogo
