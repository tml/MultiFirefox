#!/usr/bin/env bash

# Make .icns file from mozilla's firefox svg icon asset (CC-BY-SA 3.0)
# Prereqs: curl, inkscape and pngcrush (brew install inkscape pngcrush)
if [ ! -f firefox-logo.svg ]; then
  curl -L -o firefox-logo.svg https://www.mozilla.org/media/protocol/img/logos/firefox/browser/logo.svg
fi
mkdir firefox.iconset
inkscape --export-filename="$(pwd)/firefox.iconset/icon_32x32.png" --export-width=32 --export-height=32 "$(pwd)/firefox-logo.svg"
pngcrush -ow firefox.iconset/icon_32x32.png
inkscape --export-filename="$(pwd)/firefox.iconset/icon_32x32@2x.png" --export-width=64 --export-height=64 "$(pwd)/firefox-logo.svg"
pngcrush -ow firefox.iconset/icon_32x32@2x.png
inkscape --export-filename="$(pwd)/firefox.iconset/icon_128x128.png" --export-width=128 --export-height=128 "$(pwd)/firefox-logo.svg"
pngcrush -ow firefox.iconset/icon_128x128.png
inkscape --export-filename="$(pwd)/firefox.iconset/icon_128x128@2x.png" --export-width=256 --export-height=256 "$(pwd)/firefox-logo.svg"
pngcrush -ow firefox.iconset/icon_128x128@2x.png
inkscape --export-filename="$(pwd)/firefox.iconset/icon_512x512.png" --export-width=512 --export-height=512 "$(pwd)/firefox-logo.svg"
pngcrush -ow firefox.iconset/icon_512x512.png
inkscape --export-filename="$(pwd)/firefox.iconset/icon_512x512@2x.png" --export-width=1024 --export-height=1024 "$(pwd)/firefox-logo.svg"
pngcrush -ow firefox.iconset/icon_512x512@2x.png
iconutil --convert icns firefox.iconset
rm -rf firefox.iconset
