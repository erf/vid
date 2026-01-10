enum Mode {
  normal,
  operatorPending,
  insert,
  replace,
  command,
  search,
  popup,
  select, // Multi-selection mode
  visual; // Visual selection mode

  String get label => switch (this) {
    .normal => 'NOR',
    .operatorPending => 'PEN',
    .insert => 'INS',
    .replace => 'REP',
    .command => 'CMD',
    .search => 'SRC',
    .popup => 'POP',
    .select => 'SEL',
    .visual => 'VIS',
  };
}
