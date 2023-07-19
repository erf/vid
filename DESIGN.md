# Design

- whole file as a single Characters `text` 
- recreate lines of text + metadata on init / edit for rendering / movement
- minimal API to replace, insert and delete for a given range on `text`
- undo operations are added to a stack on replace
- optimize text changes later (if needed)
