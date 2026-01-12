# Architecture

## Overview

The core text engine stores file contents as a single `String` for simplicity. This works well enough thanks to Dart's runtime, and avoids the complexity of rope or piece-table data structures that would complicate everything else. The cursor and viewport are byte-based offsets into the text. Most text operations within a range use regex, funneling through a minimal `replace` API. Undo operations are recorded on each replace, and a line index with start/end positions is rebuilt after every change.

Beyond the core engine, vid supports multiple buffers, built-in tokenizers for syntax highlighting across various file types, and LSP integration (go to definition, find references, semantic tokens, diagnostics, and more). Interactive popup menus provide file browsing, buffer switching, theme selection, diagnostics lists, and reference navigation.
