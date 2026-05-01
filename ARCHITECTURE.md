# Architecture

## Overview

The core text engine stores file contents as a single `String` for simplicity.
This works well enough thanks to Dart's runtime, and avoids the complexity of
rope or piece-table data structures that would complicate everything else. The
cursor and viewport are byte-based offsets into the text. Most text operations
within a range use regex, funneling through a minimal `replace` API. Undo
operations are recorded on each replace, and a line index with start/end
positions is rebuilt after every change.

All offsets are UTF-8 byte positions, and the cursor is always snapped to
grapheme cluster boundaries. This means emoji, wide CJK characters, and
combining marks are handled correctly throughout — display width is computed
per-grapheme for rendering.

Editing follows the vim model: modes (normal, insert, visual, visual-line,
operator-pending, command), motions, operators, and text objects. Motions move
cursors, operators act on ranges defined by motions or text objects, and the
mode determines how input is interpreted. Undo and redo operate as a linear
history of replace operations, with each undo step restoring both text and
cursor position.

Beyond the core engine, vid supports multiple buffers, multiple selections
(Kakoune-style), built-in tokenizers for syntax highlighting across various
file types, and LSP integration (go to definition, find references, semantic
tokens, diagnostics, and more). Each buffer maintains a list of `Selection`
objects (anchor + cursor pairs) that motions and operators apply to
simultaneously, with automatic merging of overlapping selections. Interactive
popup menus provide file browsing, buffer switching, theme selection,
diagnostics lists, and reference navigation.

Configuration is loaded from YAML files, checked in order: local project
dotfiles, `$XDG_CONFIG_HOME/vid/`, and `~/.config/vid/`. Separate files
configure editor settings and LSP servers.

## Core data model

- **`FileBuffer`** (`lib/file_buffer/file_buffer.dart`) — owns the text of one
  open file. Holds the canonical `_text` string, the rebuilt-on-change
  `lines` index (`List<LineInfo>` with start/end byte offsets), the
  `selections` list (always non-empty; first entry is the "main" selection),
  the `viewport` byte offset, undo history, and an `EditBuilder` used to
  accumulate the in-progress edit. Mixed-in operations are split by concern
  across `file_buffer_io.dart`, `file_buffer_nav.dart`, `file_buffer_text.dart`,
  and `file_buffer_edits.dart`.

- **`LineInfo`** (`lib/line_info.dart`) — two byte offsets per line:
  `start` (line start) and `end` (the `\n`, or `text.length` for the last
  line). `length => end - start` excludes the newline. `FileBuffer.lines`
  is a `List<LineInfo>` rebuilt on every text change.

- **`Selection`** (`lib/selection.dart`) — `(anchor, cursor)` byte-offset pair.
  `isCollapsed` when anchor == cursor (a bare cursor); otherwise a visual
  range. Multiple selections drive Kakoune-style multi-cursor editing;
  overlapping selections are merged automatically.

- **`Editor`** (`lib/editor.dart`, ~1000 lines) — top-level coordinator. Owns
  `_buffers`, the active buffer index, `Config`, `Renderer`, `Highlighter`,
  the `FeatureRegistry`, the popup state, the jump list, and yank buffer.
  Routes input through `bindings.dart` and dispatches the resulting
  `EditOperation` via `commitEdit`.

- **`EditOperation`** (`lib/edit_operation.dart`) — the unit of work produced
  by parsing input: `motion`, optional `op` (operator), `count`, plus replay
  metadata. `Editor.commitEdit` consumes one and routes to operator
  application, multi-selection motion, or single-cursor motion.

- **`Config`** (`lib/config.dart`) — immutable settings, mutated only via
  `copyWith`. Loaded from YAML by `ConfigLoader` (`lib/config_loader.dart`).

## Input → edit pipeline

1. Terminal input arrives in `Editor` and is dispatched through `bindings.dart`
   (mode-keyed `const` maps in `mode_bindings.dart`).
2. Bindings invoke action handlers in `lib/action/*` (static method classes
   like `NormalActions`, `OperatorActions`). Actions either mutate state
   directly or produce/extend an `EditOperation` via `EditBuilder`.
3. When an `EditOperation` is complete, `Editor.commitEdit` runs the
   appropriate path:
   - **Operator + motion:** apply operator to the range each motion produces,
     across all selections.
   - **Visual / visual-line, no operator:** apply motion to each selection's
     cursor, preserving anchors.
   - **Multi-cursor normal/operator-pending, no operator:** apply motion to
     each cursor, collapsing selections.
   - **Single cursor, no operator:** advance the cursor `count` times.
4. After dispatch, `commitEdit` saves the operation for repeat (`.`), clears
   `desiredColumn` for non-vertical motions, and resets the edit builder.
5. Any text change is published to listeners via `FileBuffer.addListener`,
   which the `FeatureRegistry` forwards to features as `onTextChange`.

## Rendering

Rendering is split across focused modules so each concern is isolated:

- `lib/renderer.dart` (~900 lines) — top-level frame composition; owns the
  layout pipeline, line wrapping (`_layoutLineWrapped` / `_renderLineWrapped`,
  parameterized by an optional `breakat` for word wrap), and scroll/viewport
  math.
- `lib/gutter.dart` — `GutterRenderer`, `GutterSign(s)`. Owns gutter width,
  gutter-cell rendering, and end-of-line newline-symbol rendering.
- `lib/status_bar.dart` — status line and command-line input row.
- `lib/message_renderer.dart` — transient message overlay.
- `lib/popup/popup_renderer.dart` — popup window rendering and a
  `PopupHit` sealed type returned by `hitTest()` for mouse routing.
- `lib/highlighting/` — `Highlighter` orchestrates regex tokenizers per
  language plus LSP semantic tokens; themes in `theme.dart`.

## Features

Cross-cutting concerns (LSP, cursor-position persistence) implement the
`Feature` interface (`lib/features/feature.dart`):

```dart
abstract class Feature {
  void onInit();
  void onQuit();
  void onFileOpen(FileBuffer file) {}
  void onBufferSwitch(FileBuffer previous, FileBuffer next) {}
  void onBufferClose(FileBuffer file) {}
  void onTextChange(FileBuffer file, int start, int end,
                    String newText, String oldText) {}
}
```

`FeatureRegistry` (`lib/features/feature_registry.dart`) holds the active
features and fans out lifecycle events. Features are accessed by type:

```dart
final lsp = editor.featureRegistry?.get<LspFeature>();
```

`LspFeature` (`lib/features/lsp/lsp_feature.dart`) manages multiple LSP
clients keyed by server config. Per-URI caches live in
`lib/features/lsp/lsp_caches.dart`:

- `LspDiagnosticsCache` — diagnostics + first-error formatter.
- `LspSemanticTokensCache` — current + previous tokens, debounce timers,
  and the line-shift invalidation logic for incremental edits.
- `LspCodeActionsCache` — lines-with-code-actions + per-URI debounce timers.
- `LspDocumentTracker` — open-document → server map and version counter.

## Critical invariants

1. **Text always ends with `\n`** — enforced by `FileBuffer`. All edits must
   preserve this; tests that set `f.text` must include the trailing newline.
2. **Byte offsets, not char indices** — `cursor`, `viewport`, line `start`/`end`
   are UTF-8 byte offsets, not character or grapheme indices. Use
   `string_ext.dart` helpers for tab expansion and `originalSlice`. Convert
   between offsets and (line, column) via `FileBuffer`:
   - `lineNumber(offset)` — binary search, O(log n).
   - `lineOffset(lineNum)` — `lines[lineNum].start`, O(1).
   - `lineStart(offset)` / `lineEnd(offset)` — bounds of the line at offset.
   - `lineText(offset)` / `lineTextAt(lineNum)` — line content (excludes `\n`).
   - `columnInLine(offset)` — grapheme-cluster column within the line.

   To iterate a single line's characters, slice the buffer with
   `text.substring(line.start, line.end)` and walk it via the `characters`
   package (e.g. `lineText(offset).characters`).
3. **Cursor at grapheme boundaries** — never position the cursor mid-grapheme.
   Width and movement use grapheme-aware utilities in `lib/grapheme/`.
4. **`lines` is rebuilt on every change** — don't cache `LineInfo` across
   edits; always go through `lines[i]` or `lineNumber(...)`.
5. **Bindings are `const`** — the maps in `bindings.dart` and
   `mode_bindings.dart` are immutable. Don't mutate at runtime.
6. **`_buffers` is never empty during normal operation** — the constructor
   seeds one buffer; the only drain path (`closeBuffer`) calls `quit()`
   which exits before returning. Accessing `editor.file` on an empty list
   intentionally throws.
7. **Selections list is non-empty** — the first entry is always the primary
   selection; collapsed entries are bare cursors.

## Extension points

- **New motion** — implement `MotionAction` (`lib/motion/motion_base.dart`),
  wrap as a `Motion`, register in `bindings.dart`.
- **New operator** — implement `OperatorAction`
  (`lib/operator/operator_base.dart`), register in `bindings.dart`.
- **New text object** — implement `TextObjectAction`
  (`lib/text_object/text_object_base.dart`), register in `bindings.dart`.
- **New feature** — extend `Feature`, add to the list in `Editor._initFeatures`.
- **New ex-command** — add to `lib/line_edit/` and the command map in
  `bindings.dart`.
- **New language tokenizer** — add under `lib/highlighting/languages/` and
  wire into `Highlighter`.

## Conventions

- Single-letter test vars: `e` = `Editor`, `f` = `FileBuffer`.
- Static action classes (`NormalActions.pasteAfter()`,
  `OperatorActions.change()`).
- Single quotes for strings: `'string'`.
- Import order: `dart:`, packages, `package:vid/`, relative.
- Tests mirror `lib/` structure with `*_test.dart` files.
- `ErrorOr<T>` (`lib/error_or.dart`) for fallible sync operations that the
  caller should handle (e.g. file load).

## Related docs

- `AGENTS.md` — quick agent guide and conventions.
- `docs/GUIDE.md` — getting started.
- `docs/KEYBINDINGS.md` — complete keybinding reference.
- `docs/LSP_FEATURE_PLAN.md` — LSP roadmap.
- `docs/VIM_FEATURE_PLAN.md` — vim parity tracker.
- `config.example.yaml` — all editor config keys with comments.
- `TODO.md` — refactor backlog.
