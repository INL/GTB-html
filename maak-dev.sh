#!/bin/sh

# Alvorens dit script uit te voeren, cd naar het directory waar het zich bevindt.

cd generate-gtb-html-files
./generate-gtb-html-files.sh \
  "BASEARTICLEURL=http://gtb.inl.nl/iWDB/search?actie=article" \
  "BASEARTICLECONTENTURL=http://gtb.inl.nl/iWDB/search?actie=article_content" \
  "BASESEARCHURL=http://localhost/redirect.php?actie=results" \
  "BASELISTURL=http://localhost/redirect.php?actie=list" \
  "GA_TRACKING_CODE="
  
echo Let op: de google analytics tracking code UA-57793092-1 wordt niet meegegeven want dit is de ontwikkelversie
