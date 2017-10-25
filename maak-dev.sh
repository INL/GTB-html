#!/bin/sh

# Alvorens dit script uit te voeren, cd naar het directory waar het zich bevindt.

cd generate-gtb-html-files
./generate-gtb-html-files.sh \
  "BASEARTICLEURL=http://gtb.inl.nl/iWDB/search?actie=article" \
  "BASEARTICLECONTENTURL=http://gtb.inl.nl/iWDB/search?actie=article_content" \
  "BASESEARCHURL=../redirect.php?actie=results" \
  "BASELISTURL=redirect.php?actie=list"
