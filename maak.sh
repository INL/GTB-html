#!/bin/sh

# Alvorens dit script uit te voeren, cd naar het directory waar het zich bevindt.

export BASE_TARGET_DIR=target

SAVEPWD=`pwd`

cd generate-gtb-html-files
./generate-gtb-html-files.sh \
  "BASEARTICLEURL=/iWDB/search?actie=article" \
  "BASEARTICLECONTENTURL=/iWDB/search?actie=article_content" \
  "BASESEARCHURL=/iWDB/search?actie=results" \
  "BASELISTURL=/iWDB/search?actie=list" \
  "PLAUSIBLE_TRACKING_DOMAIN=gtb.ivdnt.org"
  
cd "$SAVEPWD"
rm "$BASE_TARGET_DIR/redirect.php"
