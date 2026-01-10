enum Mode {
  normal,
  operatorPending,
  insert,
  replace,
  command,
  search,
  popup,
  select, // Multi-selection mode
  visual, // Visual selection mode (character-wise)
  visualLine; // Visual line mode (linewise)

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
    .visualLine => 'VLN',
  };
}
