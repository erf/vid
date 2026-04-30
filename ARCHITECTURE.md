# Architecture

## Overview

The core text engine stores file contents as a single `String` for simplicity. This works well enough thanks to Dart's runtime, and avoids the complexity of rope or piece-table data structures that would complicate everything else. The cursor and viewport are byte-based offsets into the text. Most text operations within a range use regex, funneling through a minimal `replace` API. Undo operations are recorded on each replace, and a line index with start/end positions is rebuilt after every change.

All offsets are UTF-8 byte positions, and the cursor is always snapped to grapheme cluster boundaries. This means emoji, wide CJK characters, and combining marks are handled correctly throughout — display width is computed per-grapheme for rendering.

Editing follows the vim model: modes (normal, insert, visual, visual-line, operator-pending, command), motions, operators, and text objects. Motions move cursors, operators act on ranges defined by motions or text objects, and the mode determines how input is interpreted. Undo and redo operate as a linear history of replace operations, with each undo step restoring both text and cursor position.

Beyond the core engine, vid supports multiple buffers, multiple selections (Kakoune-style), built-in tokenizers for syntax highlighting across various file types, and LSP integration (go to definition, find references, semantic tokens, diagnostics, and more). Each buffer maintains a list of `Selection` objects (anchor + cursor pairs) that motions and operators apply to simultaneously, with automatic merging of overlapping selections. Interactive popup menus provide file browsing, buffer switching, theme selection, diagnostics lists, and reference navigation.

Configuration is loaded from YAML files, checked in order: local project dotfiles, `$XDG_CONFIG_HOME/vid/`, and `~/.config/vid/`. Separate files configure editor settings and LSP servers.
