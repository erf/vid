# Design

- file as a single `text` String
- create lines of text + metadata on init / changes
- use lines for rendering and cursor movement
- minimal API to replace, insert and delete for a given range on `text`
- undo operations are added to a list on replace
- optimize text changes later (if needed)
