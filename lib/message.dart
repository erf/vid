enum MessageType { info, error }

class Message {
  final String text;
  final MessageType type;

  const Message(this.text, this.type);

  factory Message.info(String message) => Message(message, MessageType.info);
  factory Message.error(String message) => Message(message, MessageType.error);
}
