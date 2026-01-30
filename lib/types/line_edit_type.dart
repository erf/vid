/// Types of line edit commands - used for :commands.
enum LineEditType {
  // Basic commands
  noop,
  quit,
  forceQuit,
  open,
  read,
  write,
  forceWrite,
  writeAndQuit,

  // Wrap modes
  setNoWrap,
  setCharWrap,
  setWordWrap,

  // Buffer commands
  nextBuffer,
  prevBuffer,
  switchToBuffer,
  closeBuffer,
  forceCloseBuffer,
  listBuffers,

  // LSP commands
  lsp,
  diagnostics,
  diagnosticsAll,
  lspRename,
  format,
  symbols,

  // Selection commands
  select,
  selectClear,

  // Popup commands
  themes,
  files,
  references,
}
