#!/bin/sh
dart compile exe bin/vid.dart -o build/vid
mkdir -p ~/bin
cp build/vid ~/bin/
