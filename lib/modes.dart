enum Mode {
  normal,
  operatorPending,
  insert,
  replace,
  command,
  search,
  searchBackward,
  popup,
  visual, // Visual selection mode (character-wise, supports multi-selection)
  visualLine; // Visual line mode (linewise)

  String get label => switch (this) {
    .normal => 'NOR',
    .operatorPending => 'PEN',
    .insert => 'INS',
    .replace => 'REP',
    .command => 'CMD',
    .search => 'SRC',
    .searchBackward => 'SRC',
    .popup => 'POP',
    .visual => 'VIS',
    .visualLine => 'VIL',
  };
}
