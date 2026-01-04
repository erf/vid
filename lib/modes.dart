enum Mode {
  normal,
  operatorPending,
  insert,
  replace,
  command,
  search,
  popup;

  String get label => switch (this) {
    .normal => 'NOR',
    .operatorPending => 'PEN',
    .insert => 'INS',
    .replace => 'REP',
    .command => 'CMD',
    .search => 'SRC',
    .popup => 'POP',
  };
}
