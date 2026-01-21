# Getting Started with Vid

A quick introduction to vid, the minimal vim-like text editor.

## Opening Files

```bash
vid file.txt              # Open a file
vid file1.txt file2.txt   # Open multiple files (as buffers)
vid                       # Open empty buffer
```

## The Basics

Vid operates in different **modes**, just like vim:

- **Normal mode** — navigate and manipulate text (default)
- **Insert mode** — type text directly
- **Visual mode** — select text
- **Command mode** — run commands like save/quit

### Switching Modes

| From Normal | To | Key |
|-------------|-----|-----|
| Normal | Insert | `i` (before cursor), `a` (after cursor) |
| Normal | Visual | `v` (character), `V` (line) |
| Normal | Command | `:` |
| Any | Normal | `Escape` |

## Essential Commands

### Moving Around

```
h j k l     ←  ↓  ↑  →       Arrow-style movement
w b         Word forward/back
0 $         Start/end of line
gg G        Start/end of file
Ctrl+D/U    Half-page down/up
```

### Editing

```
i           Insert before cursor
a           Append after cursor
o           Open new line below
dd          Delete line
yy          Yank (copy) line
p           Paste
u           Undo
U           Redo
```

### The Operator + Motion Pattern

Vid follows vim's composable grammar: `{operator}{motion}` or `{operator}{text-object}`

| Example | Meaning |
|---------|---------|
| `dw` | Delete word |
| `d$` | Delete to end of line |
| `ci"` | Change inside quotes |
| `yap` | Yank around paragraph |

Operators: `d` (delete), `c` (change), `y` (yank), `gu` (lowercase), `gU` (uppercase)

### Saving and Quitting

```
:w          Save
:q          Quit
:wq         Save and quit
ZZ          Save and quit (shortcut)
:q!         Quit without saving
```

## Working with Multiple Files

### Buffers

Open files become buffers. Navigate between them:

```
:bn         Next buffer
:bp         Previous buffer
:ls         List all buffers
:b name     Switch to buffer by name
Ctrl+F      Open buffer picker
```

### File Picker

Press `Ctrl+P` to open the fuzzy file picker. Type to filter, `Enter` to open.

## Search

```
/pattern    Search forward
?pattern    Search backward
n           Next match
N           Previous match
*           Search word under cursor
```

## Multi-Cursor Editing

Vid supports multiple cursors for powerful simultaneous editing:

```
Ctrl-J      Add cursor below (also works with Enter)
Ctrl+K      Add cursor above
Ctrl+N      Select word under cursor (visual mode)
Tab         Cycle to next selection
Shift+Tab   Cycle to previous selection
```

In visual mode, `Ctrl+A` selects all matches of the current selection.

## LSP Integration

If you have LSP servers configured (see `lsp_servers.example.yaml`), you get:

```
gd          Go to definition
gr          Find references
K           Hover documentation
ga          Code actions
Ctrl+N      Completion (in insert mode)
:format     Format document
```

## Customization

Vid loads configuration from `~/.config/vid/config.yaml`. See [config.example.yaml](../config.example.yaml) for options.

### Themes

Press `Ctrl+T` or run `:themes` to open the theme selector. Available themes:
- mono (default)
- rosepine
- ayu
- unicorn

## Next Steps

- See [KEYBINDINGS.md](KEYBINDINGS.md) for the complete keybinding reference
- Check [config.example.yaml](../config.example.yaml) for configuration options
- Check [lsp_servers.example.yaml](../lsp_servers.example.yaml) for LSP setup
