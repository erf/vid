#!/bin/sh
dart compile exe --verbosity warning bin/vid.dart -o build/vid
# NOTE: put ~/bin in your PATH
mkdir -p ~/bin
cp build/vid ~/bin/
