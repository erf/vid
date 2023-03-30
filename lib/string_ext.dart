import 'package:string_width/string_width.dart';

extension StringExt on String {
  int get renderWidth {
    return stringWidth(this);
  }
}
