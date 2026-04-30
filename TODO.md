# TODO / Refactoring Ideas

Ongoing list of refactoring ideas and improvements for vid. Items are
prioritized roughly by effort/value ratio.

## Continue enum-param unification (recent trend)

Several pairs/triples of trivial actions could collapse into one parameterized
class. Pattern: enum + single class taking the enum.

- [x] `popupMoveDown` / `popupMoveUp` / `popupPageDown` / `popupPageUp` →
      `PopupMove(PopupMoveType)` *(already done)*
- [x] `addCursorBelow` / `addCursorAbove` → `AddCursor(CursorDir)` *(already done)*
- [x] `nextSelection` / `prevSelection` → `CycleSelection(CycleDir)` *(already done)*
- [x] `centerView` / `topView` / `bottomView` → `ScrollView(ViewPosition)` *(commit a83d431)*
- [x] `increase` / `decrease` → `ChangeNumber(NumberChange)` *(commit febcc53)*
- [x] `repeatFindStr` / `repeatFindStrReverse` → `RepeatFind(RepeatFindDir)`
      *(commit 1dce8a0)*
- [x] `visualLineInsertAtLineStarts` / `visualLineInsertAtLineEnds` →
      `VisualLineInsert(LinePosition)` *(already done)*
- [x] `popupFilterCursorLeft` / `popupFilterCursorRight` /
      `popupFilterCursorToStart` / `popupFilterCursorToEnd` →
      `PopupFilterCursor(FilterCursorPos)`
- [x] `escapeVisual` / `escapeVisualLine` → `EscapeVisual(VisualEscape)`
- [x] `quit` / `forceQuit` → `Quit(QuitMode)`
- [x] `pasteAfter` / `pasteBefore` → `Paste(PasteWhere)`
- [x] `openFilePicker` / `openBufferSelector` / `openThemeSelector` /
      `openDiagnostics` → `OpenPopup(PopupKind)`
- [x] `lineEditExecuteSearch` / `lineEditExecuteSearchBackward` →
      `LineEditExecuteSearch(SearchDir)`
- [ ] `enterVisualMode` / `enterVisualLineMode` — share substantial logic;
      could become `EnterVisual(VisualKind)`. **Lower priority** — visual line
      mode does substantial extra work expanding to lines; unifying may add
      branching without saving much.
- (skipped) `undo` / `redo` — kept separate; conceptually distinct, original
  classes already simple.

NOTE: `ActionType` enum entries themselves stay split (they are parameterless
and used directly in keybinding tables). Only the implementation classes are
unified.

## Multi-cursor edit pattern is duplicated ~7 times — DONE

Resolved in commit `618b0de`: extracted `CursorEdit` +
`applyEditsWithCursors()` in `lib/file_buffer/file_buffer_edits.dart`.
Refactored 7 call sites (InsertActions.insert/backspaceImpl,
InsertEnter, OpenLineAbove/Below, ChangeNumber, _pasteAtCursors,
VisualPaste). Removed ~150 lines of hand-rolled offset tracking.

`ToggleCaseUnderCursor` was *not* refactored to use this helper — it
should instead route through the operator pipeline (separate item below).

This would remove ~50% of the implementation in those actions.

## Unify `ToggleCaseUnderCursor` with the operator pipeline — DONE

Resolved in commit `ee64c8e`. Added `ToggleCase` operator and
`OperatorType.toggleCase`. `~` now routes through
`OperatorActions.handleVisualSelections` in visual modes, and uses
`applyEditsWithCursors` over a "next N graphemes" range in normal mode.
`ToggleCaseUnderCursor` shrunk from ~125 lines to ~70.

Not done: ~~registering `g~` as a normal-mode `OperatorCommand(.toggleCase)`
to enable `g~w`, `g~~` etc. (full vim parity).~~ DONE in commit `4da1cde`.

## Editor.dart refactoring — DEFERRED

Splitting `Editor` (1073 lines) into `BufferManager`, `MouseInputHandler`,
`BracketedPasteHandler`, etc. was considered. **Not worth it right now**:

- `Editor` is the central coordinator; splitting creates indirection without
  reducing complexity.
- Many "extractable" pieces share state with Editor and are only called from
  it.
- Recent project trend has been *unifying*, not fragmenting.

Revisit if a specific subsystem grows further or becomes hard to test.

## Renderer.dart — DONE

Resolved across 5 commits (`cfa44fc`, `93ed9e3`, `548ef3f`, `5bf27ae`,
`b93d494`). `renderer.dart` shrunk from 1478 → 926 lines (−37%).

- [x] Move tab-expansion offset helpers (`_renderedToOriginalOffset`,
      `_getOriginalSlice`) to `String` extension methods in `string_ext.dart`.
- [x] Extract `PopupRenderer` into `lib/popup/popup_renderer.dart` with own
      bounds + row map; added `hitTest()` returning sealed `PopupHit`
      (Outside/Inside/Item) so `editor.dart` no longer reaches into renderer
      internals for mouse clicks.
- [x] Extract `StatusBar` (status bar + command/search line edit) and
      `MessageRenderer` (transient messages) into their own files.
- [x] Unify `_layoutLineCharWrap` / `_layoutLineWordWrap` into
      `_layoutLineWrapped(breakat?)`, and `_renderLineCharWrap` /
      `_renderLineWordWrap` into `_renderLineWrapped(breakat?)`. Extracted
      `_findWordBreakPoint` and `_styleChunk` helpers.
- [x] Extract `GutterRenderer` into `lib/gutter.dart` (colocated with
      `GutterSign` / `GutterSigns`). Owns `width`, gutter cell rendering, and
      end-of-line newline-symbol rendering.

## LspFeature (837 lines)

Has 11+ maps tracking different concerns. Could extract:

- `LspDiagnosticsCache` — diagnostics per URI
- `LspSemanticTokensCache` — tokens, previousTokens, request timers
- `LspCodeActionsCache` — linesWithCodeActions, code action timers
- `LspDocumentTracker` — document versions, open documents

Likely high payoff because each cache is testable in isolation.

## `commitEdit` has duplicated tail across 4 branches

`Editor.commitEdit` (editor.dart:859) has 4 conditional branches that each end
with the same trio: `_saveForRepeat`, `_clearDesiredColumnIfNeeded`,
`file.edit.reset()`. Restructure so the tail runs once at the end.

## Magic numbers → Config

Inline constants like `scrollLines = 3`, `scrollPadding = 3` should move to
`Config`.

## `_loadInitialFiles` error handling

`Editor._loadInitialFiles` (editor.dart:170) calls `print(...); exit(0)` on
load error. Not testable, bypasses cleanup. Should bubble up via `ErrorOr`
and let `init` decide.

## `_emptyBuffer` static fallback

`static final _emptyBuffer = FileBuffer();` (editor.dart:78) is shared across
all `Editor` instances and tests — potential test bleed. Make per-instance,
or rely on the invariant that buffer list is never empty.

## ARCHITECTURE.md is thin (13 lines)

Worth expanding now that the folder reorganization has stabilized:
action/motion/operator/text_object pipeline, multi-cursor model, feature
registry.
