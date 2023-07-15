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
- C to change-to-eof-line
- s to substitute

## Text engine

- keep whole file as text String
- use CharacterRange / Characters to manipulate
- keep positions per line and create CharacterRange.at from that
- recreate render lines every time text changes
- simple API to replace / insert text or delete text given a range
- easier to do undo / redo stack, with simpler text changes
- optimize later how we recreate visible render lines from text

### Refactor strategy
- make more tests for actions
- replace current text processing with using TextEngine to edit text
- recreate lines of Characters after that, before rendering
- replace lines of Characters with custom Line objects
- line objects only have start, end indices for String and Characters
- fix broken actions
