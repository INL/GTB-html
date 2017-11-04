#!/bin/bash

WHEREAMI=$(dirname $(realpath $0))
. "$WHEREAMI"/sourceme

if [ "$1" = "--alleen-index" ]
then
    ALLEEN_INDEX=jawel
    shift
else
    ALLEEN_INDEX=
fi

PROJECTDIR=`dirname "$WHEREAMI"`

if [ -z "$BASE_TARGET_DIR" ]
then
    BASE_TARGET_DIR=target
fi

SOURCEDIR=$PROJECTDIR/source
TARGETDIR=$PROJECTDIR/$BASE_TARGET_DIR

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

if [ -z "$ALLEEN_INDEX" ]
then
    # Transform index.xml to wnt.html, onw.html, etc.:
    for wdb in onw vmnw mnw wnt wft
    do
        $JAVACMD -classpath "$SAXONJAR" net.sf.saxon.Transform "$SOURCEDIR"/index.xml "$WHEREAMI"/generate-gtb-html-files.xslt "$@" >"$TARGETDIR"/$wdb.html "VERSIONINFO=$VERSIONINFO" "SELECTED_SOURCES=$wdb"
    done
fi


# Compile Saxon-JS XSLT stylesheet"
# ### This requires Saxon-EE. Therefore, compile the stylesheet in the source folder using Oxygen
#$JAVACMD -classpath "$SAXONJAR" net.sf.saxon.Transform -t -xsl:"$SOURCEDIR"/xslt/gtb.xslt -export:$TARGETDIR"/xslt/gtb.sef -target:JS -nogo
