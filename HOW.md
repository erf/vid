# Text engine

- keep file as text String
- use CharacterRange / Characters to manipulate
- keep positions per line and create CharacterRange.at from that
- recreate render lines every time text changes
- simple API to replace / insert text or delete text given a range
- easier to do undo / redo stack, with simpler text changes
- optimize how we recreate visible render lines from text
