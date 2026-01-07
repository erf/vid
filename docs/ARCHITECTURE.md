# Architecture

## Overview

- file as a single `text` String for simplicity
- cursor (and viewport) is byte based 
- use regex for most text operations within range
- minimal API to replace text for a given range
- undo operations are added to a list on replace
- create a line list with start/end positions on changes
- support multiple buffers
- built in tokenizers for various file types for syntax highlighting
- built in LSP support (go to def, all refs, symantic highligthing, diagnostics++)
- built in popup menus for file browsing, buffers, themes, diagnostics

## Text Operations

We use `String.replaceRange` for all text changes.

A `TextOp` class is used to track undo/redo operations.

## TODO 

- more LSP features
- better text data-structure if needed
