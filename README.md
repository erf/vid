# vid

A minimal vim-like text editor for modern terminals written in [Dart](https://dart.dev)

> Made for myself for fun and learning

## Features

- basic vim motions, operators and command mode (see [bindings.dart](lib/bindings.dart))
- visual mode, visual line mode, and multiple selections with regex search
- syntax highlighting and LSP support
- render and edit emojis and wide characters
- multi-buffer support with interactive popups
- undo and redo
- file-based YAML configuration

## Building

Requires the [Dart SDK](https://dart.dev/get-dart) (3.10+).

For building `vid` run:

```
dart pub get
dart compile exe bin/vid.dart -o build/vid
```

Or see [build.sh](build.sh), which also installs to `~/bin/`.

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
