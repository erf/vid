# TODO

- undo / history (simpler text delete/insert API - recreate lines on changes?)
- delete line should save to register
- yank line should include new-line char
- cursor up/down should move to correct render position
- use CharacterRange more?
- star (*) go to similar token
- better architecture for actions and pending mode
- save file without name (requires command mode)
- repeat last action / search using dot (.)
- write more tests
- replace lines with custom Line objects with start, end indices for String and Characters

## Text engine

- keep whole file as text String
- use CharacterRange / Characters to manipulate
- keep positions per line and create CharacterRange.at from that
- recreate render lines every time text changes
- simple API to replace / insert text or delete text given a range
- easier to do undo / redo stack, with simpler text changes
- optimize later how we recreate visible render lines from text
