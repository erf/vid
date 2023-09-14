#!/bin/sh
dart compile exe --verbosity warning bin/vid.dart -o build/vid
mkdir -p ~/bin
cp build/vid ~/bin/
