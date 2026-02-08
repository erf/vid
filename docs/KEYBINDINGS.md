# Vid Keybindings Reference

A comprehensive reference of all keybindings in vid, the minimal vim-like text editor.

## Normal Mode

### Navigation

| Key | Action |
|-----|--------|
| `h` | Move cursor left |
| `l` | Move cursor right |
| `k` | Move cursor up |
| `j` | Move cursor down |
| `w` | Move to next word |
| `W` | Move to next WORD (whitespace-delimited) |
| `b` | Move to previous word |
| `B` | Move to previous WORD |
| `e` | Move to end of word |
| `E` | Move to end of WORD |
| `ge` | Move to end of previous word |
| `gE` | Move to end of previous WORD |
| `0` | Move to start of line |
| `^` | Move to first non-blank character |
| `$` | Move to end of line |
| `gg` | Move to start of file |
| `G` | Move to end of file |
| `{` | Move to previous paragraph |
| `}` | Move to next paragraph |
| `(` | Move to previous sentence |
| `)` | Move to next sentence |
| `%` | Jump to matching bracket |
| `Ctrl+D` | Move down half page |
| `Ctrl+U` | Move up half page |

### Find Characters

| Key | Action |
|-----|--------|
| `f{char}` | Find next occurrence of character |
| `F{char}` | Find previous occurrence of character |
| `t{char}` | Move till (before) next character |
| `T{char}` | Move till (after) previous character |
| `;` | Repeat last find |
| `,` | Repeat last find in reverse |

### Search

| Key | Action |
|-----|--------|
| `/` | Search forward |
| `?` | Search backward |
| `n` | Repeat search |
| `N` | Repeat search in reverse |
| `*` | Search for word under cursor (forward) |
| `#` | Search for word under cursor (backward) |

### Editing

| Key | Action |
|-----|--------|
| `i` | Enter insert mode |
| `a` | Append after cursor |
| `A` | Append at end of line (alias for `$a`) |
| `I` | Insert at first non-blank (alias for `^i`) |
| `o` | Open line below |
| `O` | Open line above |
| `r` | Replace single character |
| `R` | Enter replace mode |
| `s` | Substitute character (alias for `cl`) |
| `S` | Substitute line (alias for `^C`) |
| `x` | Delete character under cursor (alias for `dl`) |
| `X` | Delete character before cursor (alias for `dh`) |
| `D` | Delete to end of line (alias for `d$`) |
| `C` | Change to end of line (alias for `c$`) |
| `J` | Join lines |
| `~` | Toggle case of character under cursor |
| `p` | Paste after cursor |
| `P` | Paste before cursor |
| `Y` | Yank line (alias for `yy`) |
| `u` | Undo |
| `U` | Redo |
| `.` | Repeat last change |
| `Ctrl+A` | Increment number under cursor |
| `Ctrl+X` | Decrement number under cursor |

### Operators

Operators can be combined with motions or text objects (e.g., `dw` deletes a word, `ci(` changes inside parentheses).

| Key | Action |
|-----|--------|
| `d` | Delete |
| `c` | Change (delete and enter insert mode) |
| `y` | Yank (copy) |
| `gu` | Convert to lowercase |
| `gU` | Convert to uppercase |

Double an operator to apply to the whole line: `dd` (delete line), `cc` (change line), `yy` (yank line).

### View Control

| Key | Action |
|-----|--------|
| `zz` | Center view on cursor |
| `zt` | Scroll cursor to top of view |
| `zb` | Scroll cursor to bottom of view |
| `zh` | Toggle syntax highlighting |
| `Ctrl+W` | Toggle word wrap |

### Visual Mode

| Key | Action |
|-----|--------|
| `v` | Enter visual (character) mode |
| `V` | Enter visual line mode |
| `Escape` | Exit visual mode / collapse multi-cursor |

### Multi-Cursor

| Key | Action |
|-----|--------|
| `Enter` | Add cursor below |
| `Ctrl+K` | Add cursor above |
| `Ctrl+N` | Select word under cursor |
| `Tab` / `]s` | Cycle to next selection |
| `Shift+Tab` / `[s` | Cycle to previous selection |
| `]S` | Remove primary selection |

### LSP Commands

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Find references |
| `gR` | LSP rename symbol |
| `ga` | Show code actions |
| `gl` | Show line diagnostic |
| `gs` | Show symbols |
| `Ctrl+R` | Find references |
| `K` | Show hover information |
| `go` | Jump back |
| `gi` | Jump forward |

### File & Buffer Management

| Key | Action |
|-----|--------|
| `q` | Quit |
| `ZZ` | Write and quit |
| `ZQ` | Force quit (discard changes) |
| `Ctrl+P` | Open file picker |
| `Ctrl+F` | Open buffer selector |
| `Ctrl+T` | Open theme selector |
| `Ctrl+E` | Open diagnostics |

---

## Text Objects

Text objects are used with operators in the form `{operator}{a|i}{object}`.
- `a` = "around" (includes delimiters/whitespace)
- `i` = "inside" (excludes delimiters)

### Brackets & Quotes

| Object | Inside | Around |
|--------|--------|--------|
| Parentheses `()` | `i(`, `i)`, `ib` | `a(`, `a)`, `ab` |
| Braces `{}` | `i{`, `i}`, `iB` | `a{`, `a}`, `aB` |
| Brackets `[]` | `i[`, `i]` | `a[`, `a]` |
| Angle brackets `<>` | `i<`, `i>` | `a<`, `a>` |
| Double quotes `"` | `i"` | `a"` |
| Single quotes `'` | `i'` | `a'` |
| Backticks `` ` `` | `` i` `` | `` a` `` |

### Other Text Objects

| Object | Inside | Around |
|--------|--------|--------|
| Word | `iw` | `aw` |
| WORD | `iW` | `aW` |
| Sentence | `is` | `as` |
| Paragraph | `ip` | `ap` |

**Examples:**
- `di(` — delete inside parentheses
- `ca"` — change around double quotes
- `yiw` — yank inside word

---

## Insert Mode

| Key | Action |
|-----|--------|
| `Escape` | Return to normal mode |
| `Backspace` | Delete character before cursor |
| `Enter` | Insert newline |
| `Ctrl+N` | Show completion |
| `Ctrl+P` | Show completion |

Any other key inserts the typed character.

---

## Replace Mode

| Key | Action |
|-----|--------|
| `Escape` | Return to normal mode |
| `Backspace` | Undo last replacement |

Any other key replaces the character under cursor.

---

## Visual Mode

In visual mode, motions extend the selection. Operators act on the selection.

| Key | Action |
|-----|--------|
| `Escape` | Exit visual mode |
| `v` | Exit visual mode |
| `o` | Swap selection anchor and cursor |
| `x` | Delete selection |
| `s` | Substitute (change) selection |
| `Tab` / `]s` | Cycle to next selection |
| `Shift+Tab` / `[s` | Cycle to previous selection |
| `Ctrl+L` | Remove primary selection |
| `Ctrl+A` | Select all matches of current selection |
| `Ctrl+N` | Select next match of selection |

---

## Visual Line Mode

| Key | Action |
|-----|--------|
| `Escape` | Exit visual line mode |
| `V` | Exit visual line mode |
| `o` | Swap selection anchor and cursor |
| `x` | Delete selected lines |
| `s` | Substitute selected lines |
| `I` | Insert at start of each selected line |
| `A` | Append at end of each selected line |
| `Tab` / `]s` | Cycle to next selection |
| `Shift+Tab` / `[s` | Cycle to previous selection |
| `Ctrl+L` | Remove primary selection |
| `Ctrl+A` | Select all matches of current selection |

---

## Command Mode

Enter command mode with `:`.

### File Commands

| Command | Action |
|---------|--------|
| `:q` / `:quit` | Quit |
| `:q!` / `:quit!` | Force quit |
| `:w` / `:write` | Write (save) file |
| `:wq` / `:x` / `:exit` | Write and quit |
| `:e {file}` / `:edit {file}` | Edit/open file |
| `:o {file}` / `:open {file}` | Open file |
| `:r {file}` / `:read {file}` | Read file into buffer |

### Buffer Commands

| Command | Action |
|---------|--------|
| `:bn` / `:bnext` | Next buffer |
| `:bp` / `:bprev` / `:bprevious` | Previous buffer |
| `:b {name}` / `:buffer {name}` | Switch to buffer |
| `:bd` / `:bdelete` | Close buffer |
| `:bd!` / `:bdelete!` | Force close buffer |
| `:ls` / `:buffers` / `:buf` | List buffers |

### LSP Commands

| Command | Action |
|---------|--------|
| `:lsp` | LSP status/info |
| `:d` / `:diagnostics` | Show diagnostics |
| `:da` | Show all diagnostics |
| `:rename` | LSP rename |
| `:fmt` / `:format` | Format document |
| `:sym` / `:symbols` | Show symbols |
| `:ref` / `:references` | Find references |

### View Commands

| Command | Action |
|---------|--------|
| `:nowrap` | Disable line wrapping |
| `:charwrap` | Enable character wrapping |
| `:wordwrap` | Enable word wrapping |

### Selection Commands

| Command | Action |
|---------|--------|
| `:s` / `:sel` / `:select` | Select pattern |
| `:selclear` | Clear selections |

### UI Commands

| Command | Action |
|---------|--------|
| `:th` / `:theme` / `:themes` | Open theme picker |
| `:f` / `:files` / `:browse` | Open file browser |

---

## Popup/Picker Mode

When a popup (file picker, completion, etc.) is open:

| Key | Action |
|-----|--------|
| `Escape` | Cancel/close popup |
| `Enter` | Select item |
| `Ctrl+N` / `↓` | Move down |
| `Ctrl+P` / `↑` | Move up |
| `Ctrl+D` | Page down |
| `Ctrl+U` | Page up |
| `←` | Filter cursor left |
| `→` | Filter cursor right |
| `Home` / `Ctrl+A` | Filter cursor to start |
| `End` / `Ctrl+E` | Filter cursor to end |
| `Backspace` | Delete filter character |

Any other key adds to the filter.

---

## Count Prefixes

Most commands accept a numeric prefix to repeat the action:

- `5j` — move down 5 lines
- `3dw` — delete 3 words
- `10x` — delete 10 characters

Numbers `0-9` can be used as count prefixes in normal, operator-pending, and visual modes.
Note: `0` alone moves to start of line; use it as a count prefix only after other digits.
