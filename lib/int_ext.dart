extension IntExt on int {
  String get hex => '0x${toRadixString(16).toUpperCase()}';
}
