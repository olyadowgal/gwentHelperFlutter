enum CardsRowType {
  closeCombat,
  longRange,
  siege;

  String get displayName => switch (this) {
    CardsRowType.closeCombat => 'Close Combat',
    CardsRowType.longRange => 'Long Range',
    CardsRowType.siege => 'Siege',
  };
}
