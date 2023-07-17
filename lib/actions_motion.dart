import 'dart:math';

import 'package:characters/characters.dart';
import 'package:vid/characters_ext.dart';
import 'package:vid/string_ext.dart';

import 'file_buffer.dart';
import 'file_buffer_ext.dart';
import 'modes.dart';
import 'position.dart';
import 'utils.dart';

typedef Motion = Position Function(FileBuffer, Position);

Position motionCharNext(FileBuffer f, Position p) {
  return Position(
    y: p.y,
    x: clamp(p.x + 1, 0, f.lines[p.y].length - 1),
  );
}

Position motionCharPrev(FileBuffer f, Position p) {
  return Position(
    y: p.y,
    x: max(0, p.x - 1),
  );
}

Position motionCharUp(FileBuffer f, Position p) {
  final line = clamp(p.y - 1, 0, f.lines.length - 1);
  final char = clamp(p.x, 0, f.lines[line].length - 1);
  return Position(y: line, x: char);
}

Position motionCharDown(FileBuffer f, Position p) {
  final line = clamp(p.y + 1, 0, f.lines.length - 1);
  final char = clamp(p.x, 0, f.lines[line].length - 1);
  return Position(y: line, x: char);
}

Position motionFileStart(FileBuffer f, Position p) {
  return Position(y: 0, x: 0);
}

Position motionFileEnd(FileBuffer f, Position position) {
  return Position(
    x: f.lines.last.length,
    y: max(0, f.lines.length - 1),
  );
}

Position motionLineStart(FileBuffer f, Position p) {
  return Position(y: p.y, x: 0);
}

Position motionLineEnd(FileBuffer f, Position p) {
  return Position(y: p.y, x: max(0, f.lines[p.y].length - 1));
}

Position motionWordNext(FileBuffer f, Position p) {
  // TODO: use CharacterRange to find next word ?
  final start = f.indexFromPosition(p);
  final matches = RegExp(r'\S+').allMatches(f.text.string, start);
  if (matches.isEmpty) return p;
  final match =
      matches.firstWhere((m) => m.start > start, orElse: () => matches.first);
  return f.positionFromIndex(match.start);
}

Position motionWordEnd(FileBuffer f, Position p) {
  // TODO: use CharacterRange to find next word ?
  final start = f.indexFromPosition(p);
  final matches = RegExp(r'\S+').allMatches(f.text.string, start);
  if (matches.isEmpty) return p;
  final match =
      matches.firstWhere((m) => m.end - 1 > start, orElse: () => matches.first);
  return f.positionFromIndex(match.end - 1);
}

Position motionWordPrev(FileBuffer f, Position p) {
  // TODO: use CharacterRange to find next word ?
  final start = f.indexFromPosition(p);
  final matches = RegExp(r'\S+').allMatches(f.text.substring(0, start).string);
  if (matches.isEmpty) return p;
  return f.positionFromIndex(matches.last.start);
}

// exit insert mode
Position motionEscape(FileBuffer f, Position p) {
  f.mode = Mode.normal;
  f.pendingAction = null;
  return p;
}

// find the next occurence of the given character on the current line
Position motionFindNextChar(FileBuffer f, Position p, String char) {
  final r = CharacterRange(f.text.string);
  final start = f.indexFromPosition(p);
  if (!r.moveNext(start + 1)) return p;
  if (!r.moveTo(char.ch)) return p;
  return f.positionFromIndex(r.stringBeforeLength);
}

Position motionTillNextChar(FileBuffer f, Position position, String char) {
  final p = motionFindNextChar(f, position, char);
  p.x = max(p.x - 1, position.x);
  return p;
}

// find the previous occurence of the given character on the current line
Position motionFindPrevChar(FileBuffer f, Position p, String char) {
  final r = CharacterRange(f.text.string);
  final start = f.indexFromPosition(p);
  r.moveNext(start + 1);
  r.collapseToFirst(char.ch);
  return f.positionFromIndex(r.stringBeforeLength);
}

Position motionTillPrevChar(FileBuffer f, Position position, String char) {
  final p = motionFindPrevChar(f, position, char);
  p.x = min(p.x + 1, position.x);
  return p;
}
