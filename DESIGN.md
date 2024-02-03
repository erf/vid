# Design

## Architecture

- file as a single `text` String
- create lines of text + metadata on init / changes
- use lines for rendering and cursor movement
- minimal API to replace for a given range on `text`
- undo operations are added to a list on replace
- we add newline to eof if missing (unix)

## Text operations

We want to delete, insert and replace text for a spesific range.
We want to save changes to be able to undo and redo those changes.
We use a `TextOp` class with a `start`, `prevText` and `newText` to solve this.
We use convinience functions on top of that for delete and insert.
We use the `String.replaceRange` to do all text operations.

```
String replaceRange(
  int start,
  int? end,
  String replacement,
)
````

Example:

text = "hello test world"

// action: delete 'test '
range 6,10 newtext ""
undo += range 6-10, prevtext = text.sub(6, 10), newtext
text.replaceRange(undo.start, undo.end, undo.newtext)
clear redo
// text = "hello world"

// action: undo delete
? newtext.isEmpty (delete)
text.replaceRange(undo.start, undo.start + undo.newtext.len, undo.prevtext)
redo += undo
// text = "hello test world"

// action: redo delete
undo += redo
text.replaceRange(undo.start, undo.end, undo.newtext) // same as the initial action (do), so we could pass the same undo obj
// text = "hello world"

// action: insert 'YO '
range 6,6 newtext "YO "
undo += range 6,6, prevtext = text.sub(6, 6) (EMPTY), newtext = 'YO '
text.replaceRange(undo.start, undo.end, undo.newtext)
clear redo
// text = "hello YO world"

// action: undo insert
? newtext.isEmpty (delete)
text.replaceRange(undo.start, undo.start + undo.newtext.len, undo.prevtext)
? newtext.isNotEmpty + range.isEmpty (insert) (THIS CASE)
text.replaceRange(undo.start, undo.start + undo.newtext.len, undo.prevtext)
? newtext.isNotEmpty + range.isNotEmpty (replace)
text.replaceRange(undo.start, undo.start + undo.newtext.len, undo.prevtext)
redo += undo
// text = "hello world"

// action: redo insert
undo += redo
text.replaceRange(undo.start, undo.end, undo.newtext) // same as the initial action (do), so we could pass the same undo obj
// text = "hello YO world"

// action replace 'YO wor' -> 'bo'
textop = range 6,11, prevtext = text.sub(6, 11), newtext = 'bo'
undos += textop
text.replaceRange(undo.start, undo.end, undo.newtext)
clear redo
// text = "hello bold"

// action: undo replace
? newtext.isNotEmpty + range.isNotEmpty (replace)
text.replaceRange(undo.start, undo.start + undo.newtext.len, undo.prevtext)
// text = "hello YO world"

// action: redo replace
undo += redo
text.replaceRange(undo.start, undo.end, undo.newtext) // same as the initial action (do), so we could pass the same undo obj
// text = "hello bold"

## TODO 

- better text data-structure (e.g. Rope, later, if needed)
