# LSP Feature Plan

## High Priority

| Feature | Method | Binding |
|---------|--------|---------|
| Workspace Symbols | `workspace/symbol` | `Ctrl+p` |

## Medium Priority

| Feature | Method | Binding |
|---------|--------|---------|
| Signature Help | `textDocument/signatureHelp` | auto after `(` |
| Incremental Sync | `textDocument/didChange` | automatic |

## Lower Priority

| Feature | Method | Binding |
|---------|--------|---------|
| Type Definition | `textDocument/typeDefinition` | `gy` |
| Implementation | `textDocument/implementation` | `gI` |
| Document Highlight | `textDocument/documentHighlight` | automatic |
| Call Hierarchy | `callHierarchy/*` | `:callers` |
| Folding Ranges | `textDocument/foldingRange` | `zc`, `zo` |
| Inlay Hints | `textDocument/inlayHint` | automatic |

---

## Done

| Feature | Method | Binding |
|---------|--------|---------|
| Go to Definition | `textDocument/definition` | `gd` |
| Find All References | `textDocument/references` | `gr` |
| Hover | `textDocument/hover` | `K` |
| Diagnostics | `textDocument/publishDiagnostics` | `gD` |
| Semantic Tokens | `textDocument/semanticTokens/full` | automatic |
| Document Sync | `textDocument/didOpen/didClose/didChange` | automatic |
| Completion | `textDocument/completion` | `Ctrl+n` |
| Rename Symbol | `textDocument/rename` | `gR`, `:rename` |
| Formatting | `textDocument/formatting` | `:format` |
| Code Actions | `textDocument/codeAction` | `ga` |
| Document Symbols | `textDocument/documentSymbol` | `gs`, `:symbols` |
