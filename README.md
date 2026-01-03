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
- [lsp_server_config.dart](lib/lsp/lsp_server_config.dart) — LSP server configs

## Building

Requires the [Dart SDK](https://dart.dev/get-dart) (3.10+).

```bash
./build.sh
```

This compiles vid to a native executable at `build/vid` and copies it to `~/bin/`.

## Configuration

vid loads configuration from YAML files at the following locations (first found wins):

1. `./vid.yaml` — local project config
2. `$XDG_CONFIG_HOME/vid/config.yaml`
3. `~/.config/vid/config.yaml`

Copy the example config to get started:

```bash
mkdir -p ~/.config/vid
cp config.example.yaml ~/.config/vid/config.yaml
```

All settings are optional — missing values use sensible defaults. See [config.example.yaml](config.example.yaml) for all available options.

## Contributing

I'm open to PR's that align with vid's minimal philosophy.

I don't accept issues solely for suggestions.
