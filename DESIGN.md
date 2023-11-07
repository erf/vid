# Design

## Text

- file as a single `text` String
- create lines of text + metadata on init / changes
- use lines for rendering and cursor movement
- minimal API to replace, insert and delete for a given range on `text`
- undo operations are added to a list on replace
- we add newline to eof if missing (unix)

## TODO 

- better text data-structure (e.g. Rope, later, if needed)
