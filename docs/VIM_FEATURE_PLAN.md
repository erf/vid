# VIM Feature Plan

## High Priority

| Key | Description |
|-----|-------------|
| `~` | Toggle case of char under cursor |
| `H` | Move to top of screen |
| `M` | Move to middle of screen |
| `L` | Move to bottom of screen |
| `Ctrl+O` | Jump back in jump list |
| `Ctrl+I` | Jump forward in jump list |

## Medium Priority

| Key | Description |
|-----|-------------|
| `+` | Down to first non-blank |
| `-` | Up to first non-blank |
| `_` | Down N-1 lines to first non-blank |
| `\|` | Move to column N |
| `g_` | Last non-blank on line |
| `gj` | Down visual line (wrapped) |
| `gk` | Up visual line (wrapped) |
| `>>` | Indent line |
| `<<` | Dedent line |
| `>` | Indent operator |
| `<` | Dedent operator |
| `=` | Auto-indent operator |
| `gv` | Reselect previous visual |
| `Ctrl+G` | Show file info |
| `ga` | Show char info (ASCII/Unicode) |

## Lower Priority

| Key | Description |
|-----|-------------|
| `q{a-z}` | Record macro to register |
| `q` | Stop recording |
| `@{a-z}` | Play macro |
| `@@` | Repeat last macro |
| `m{a-z}` | Set mark |
| `'{a-z}` | Jump to mark line |
| `` `{a-z} `` | Jump to mark position |
| `''` | Jump to line before last jump |
| ``` `` ``` | Jump to position before last jump |
| `Ctrl+B` | Page up |
| `Ctrl+F` | Page down |
| `Ctrl+Y` | Scroll up (keep cursor) |
| `Ctrl+E` | Scroll down (keep cursor) |
| `g;` | Jump to previous change |
| `g,` | Jump to next change |
| `gn` | Search forward and select |
| `gN` | Search backward and select |
| `&` | Repeat last `:s` on line |
| `g&` | Repeat last `:s` on all lines |

## Ex Commands

| Command | Description |
|---------|-------------|
| `:%s/old/new/g` | Substitute all in file |
| `:s/old/new/g` | Substitute on current line |
| `:'<,'>s/old/new/g` | Substitute in selection |
| `:g/pattern/d` | Delete matching lines |
| `:v/pattern/d` | Delete non-matching lines |
| `:g/pattern/cmd` | Execute cmd on matches |
| `:sort` | Sort lines |
| `:sort!` | Sort reverse |
| `:sort u` | Sort unique |
| `:norm {cmd}` | Execute normal cmd on lines |
| `:!{cmd}` | Run shell command |
| `:.!{cmd}` | Filter line through cmd |
| `:'<,'>!{cmd}` | Filter selection through cmd |
| `:r !{cmd}` | Insert command output |
| `:set {option}` | Set editor option |
| `:noh` | Clear search highlight |

## Text Objects

| Object | Description |
|--------|-------------|
| `it` / `at` | Inside/around HTML tag |
| `i/` / `a/` | Inside/around search match |

## Notes

- vid uses `U` for redo (not `Ctrl+R`)
- vid uses `s` for save (not substitute)
- vid uses `q` for quit (not macro)
- vid has `go`/`gi` for LSP jump back/forward

---

## Done

| Key | Description |
|-----|-------------|
| `N` | Search backward (repeat opposite) |
| `?` | Search backward mode |
| `,` | Repeat f/F/t/T backward |
| `%` | Jump to matching bracket |
| `R` | Replace mode (continuous) |
| `Y` | Yank entire line |
| `E` | End of WORD |
| `gE` | End of previous WORD |
| `X` | Delete char before cursor (`dh`) |
| `ZZ` | Write and quit (`:wq`) |
| `ZQ` | Force quit (`:q!`) |
