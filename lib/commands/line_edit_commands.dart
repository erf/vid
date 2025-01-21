import 'package:vid/actions/line_edit.dart';

const lineEditCommands = <String, Function>{
  '': LineEdit.noop,
  'q': LineEdit.quit,
  'quit': LineEdit.quit,
  'q!': LineEdit.forceQuit,
  'quit!': LineEdit.forceQuit,
  'o': LineEdit.open,
  'open': LineEdit.open,
  'r': LineEdit.read,
  'read': LineEdit.read,
  'w': LineEdit.write,
  'write': LineEdit.write,
  'wq': LineEdit.writeAndQuit,
  'x': LineEdit.writeAndQuit,
  'exit': LineEdit.writeAndQuit,
  'nowrap': LineEdit.setNoWrap,
  'charwrap': LineEdit.setCharWrap,
  'wordwrap': LineEdit.setWordWrap,
};
