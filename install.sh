#!/bin/sh
dart compile exe --verbosity warning bin/vid.dart -o build/vid
# put ~/bin in your PATH
cp build/vid ~/bin/
