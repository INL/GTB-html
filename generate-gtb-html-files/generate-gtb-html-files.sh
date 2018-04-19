#!/bin/bash

WHEREAMI=$(dirname $(realpath $0))
. "$WHEREAMI"/sourceme

PROJECTDIR=`dirname "$WHEREAMI"`

if [ -z "$BASE_TARGET_DIR" ]
then
    BASE_TARGET_DIR=target
fi

SOURCEDIR=$PROJECTDIR/source
TARGETDIR=$PROJECTDIR/$BASE_TARGET_DIR
UUID=`uuid`

if [ ! $? -eq 0 ]; then
    echo "Error running uuid. Install if necessary."
    exit 1
fi

if [ -d "$TARGETDIR" ]
then
    rm -Rf "$TARGETDIR"
fi

mkdir "$TARGETDIR"

cp -L -R "$SOURCEDIR"/* "$TARGETDIR"
rm "$TARGETDIR"/*.xml
rm "$TARGETDIR"/xslt/*.xslt
rm "$TARGETDIR"/saxonjs/SaxonJS.js
rm -Rf "$TARGETDIR"/*/notused

VERSIONINFO=`git describe --tags`

# Transform index.xml to index.html:
"$JAVACMD" -classpath "$SAXONJAR" net.sf.saxon.Transform "$SOURCEDIR"/index.xml "$WHEREAMI"/generate-gtb-html-files.xslt "$@" >"$TARGETDIR"/index.html "VERSIONINFO=$VERSIONINFO" "UUID=$UUID"

# Compile Saxon-JS XSLT stylesheet"
# ### This requires Saxon-EE. Therefore, compile the stylesheet in the source folder using Oxygen
#$JAVACMD -classpath "$SAXONJAR" net.sf.saxon.Transform -t -xsl:"$SOURCEDIR"/xslt/gtb.xslt -export:"$TARGETDIR"/xslt/gtb.sef -target:JS -nogo
