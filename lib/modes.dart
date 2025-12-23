enum Mode {
  normal,
  operatorPending,
  insert,
  replace,
  command,
  search;

  String get label => switch (this) {
    Mode.normal => 'NOR',
    Mode.operatorPending => 'PEN',
    Mode.insert => 'INS',
    Mode.replace => 'REP',
    Mode.command => 'CMD',
    Mode.search => 'SRC',
  };
}
