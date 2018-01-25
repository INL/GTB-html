#!/bin/sh

# Alvorens dit script uit te voeren, cd naar het directory waar het zich bevindt.

export BASE_TARGET_DIR=target.test

SAVEPWD=`pwd`

cd generate-gtb-html-files
./generate-gtb-html-files.sh \
  "BASEARTICLEURL=http://gtb.ato.inl.nl/iWDB/search?actie=article" \
  "BASEARTICLECONTENTURL=http://gtb.ato.inl.nl/iWDB/search?actie=article_content" \
  "BASESEARCHURL=http://gtb.ato.inl.nl/iWDB/search?actie=results" \
  "BASELISTURL=http://gtb.ato.inl.nl/iWDB/search?actie=list" \
  "GA_TRACKING_CODE=UA-57793092-1"
  
cd "$SAVEPWD"
rm $BASE_TARGET_DIR/redirect.php
