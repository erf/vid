# Architecture

## Overview

- file as a single `text` String for simplicity
- cursor (and viewport) is byte based 
- use regex for most text operations within range
- minimal API to replace text for a given range
- undo operations are added to a list on replace
- create lines of text + metadata on changes
- use lines for help with motions etc.
- multiple buffers

## Text Operations

All text changes (delete, insert, replace) use `String.replaceRange`. A `TextOp` class with `start`, `prevText` and `newText` tracks changes for undo/redo. See [edit_test.dart](../test/edit_test.dart) for examples.

## TODO 

- more LSP features
- better text data-structure (e.g. Gap Buffer, Piece Table, Rope, later, if needed)
