enum MessageType { info, error }

class Message {
  String text;
  MessageType type;

  Message(this.text, this.type);

  factory Message.info(String message) => Message(message, MessageType.info);

  factory Message.error(String message) => Message(message, MessageType.error);
}
