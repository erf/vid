class VidException implements Exception {
  final String message;
  final String? code;

  const VidException(this.message, {this.code});

  @override
  String toString() {
    return 'VidException{message: $message, code: $code}';
  }
}
