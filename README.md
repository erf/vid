# vid

A minimal vim-like text editor for modern terminals written in [Dart](https://dart.dev)

> Made for myself for fun and learning

## Documentation

- [Getting Started Guide](docs/GUIDE.md) — quick introduction to vid
- [Keybindings Reference](docs/KEYBINDINGS.md) — complete list of all keybindings

## Features

- vim motions, operators, text objects, visual and command mode
- multiple selections with regex search (`:select <pattern>`)
- syntax highlighting with theme selector (mono, rosepine, ayu, unicorn)
- LSP support (go to definition, references, rename, format and more..)
- proper emoji and wide character support
- multi-buffer support with interactive popups
- undo and redo
- file-based YAML configuration

## Building

Requires the [Dart SDK](https://dart.dev/get-dart) (3.10+).

See [build.sh](build.sh).

## Configuration

`vid` loads configuration from YAML files at these locations (in order):

1. `./` — local project config (hidden dotfiles)
2. `$XDG_CONFIG_HOME/vid/`
3. `~/.config/vid/`

Two config files are supported:

| Local (project) | Global (~/.config/vid/) | Purpose |
|-----------------|-------------------------|--------|
| `.vid.yaml` | `config.yaml` | Editor settings (see [config.example.yaml](config.example.yaml)) |
| `.vid-lsp.yaml` | `lsp_servers.yaml` | LSP server configs (see [lsp_servers.example.yaml](lsp_servers.example.yaml)) |

## Contributing

I'm open to PR's that align with `vid`'s minimal philosophy.
