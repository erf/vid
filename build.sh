#!/bin/sh
mkdir -p build ~/bin
dart compile exe bin/vid.dart -o build/vid
cp build/vid ~/bin/
