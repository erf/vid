# vid

A minimal vim-like text editor for modern terminals written in [Dart](https://dart.dev)

> Made for myself for fun and learning

## Features

- vim motions, operators, visual and command mode (see [bindings.dart](lib/bindings.dart))
- multiple selections with regex search (`:sel <pattern>`)
- syntax highlighting with theme selector (rosepine, ayu, mono)
- LSP support (go to definition, references, hover, rename, completion)
- proper emoji and wide character support
- multi-buffer support with interactive popups
- undo and redo
- file-based YAML configuration

## Building

Requires the [Dart SDK](https://dart.dev/get-dart) (3.10+).

See [build.sh](build.sh).

## Configuration

`vid` loads configuration from YAML files at these locations (in order):

1. `./` — local project config
2. `$XDG_CONFIG_HOME/vid/`
3. `~/.config/vid/`

Two config files are supported:

- **config.yaml** — editor settings (see [config.example.yaml](config.example.yaml))
- **lsp_servers.yaml** — LSP server configs (see [lsp_servers.example.yaml](lsp_servers.example.yaml))

## Contributing

I'm open to PR's that align with vid's minimal philosophy.
