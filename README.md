# vid

A minimal vim-like text editor for modern terminals written in [Dart](https://dart.dev)

> Made for myself for fun and learning

## Features

- basic vim motions, operators and command mode
- syntax highlighting and LSP support
- render and edit emojis and wide characters
- multi-buffer support with interactive popups
- undo and redo
- file-based YAML configuration

## Code References

- [bindings.dart](lib/bindings.dart) — key mappings
- [config.example.yaml](config.example.yaml) — configuration options
- [lsp_servers.example.yaml](lsp_servers.example.yaml) — LSP server configs

## Building

Requires the [Dart SDK](https://dart.dev/get-dart) (3.10+).

```bash
./build.sh
```

This compiles vid to a native executable at `build/vid` and copies it to `~/bin/`.

## Configuration

vid loads configuration from YAML files at these locations (first found wins):

1. `./` — local project config
2. `$XDG_CONFIG_HOME/vid/`
3. `~/.config/vid/`

Two config files are supported:
- **config.yaml** — editor settings (see [config.example.yaml](config.example.yaml))
- **lsp_servers.yaml** — LSP server configs (see [lsp_servers.example.yaml](lsp_servers.example.yaml))

Copy the example configs to get started:

```bash
mkdir -p ~/.config/vid
cp config.example.yaml ~/.config/vid/config.yaml
cp lsp_servers.example.yaml ~/.config/vid/lsp_servers.yaml
```

All settings are optional — missing values use sensible defaults.

## Contributing

I'm open to PR's that align with vid's minimal philosophy.

I don't accept issues solely for suggestions.
