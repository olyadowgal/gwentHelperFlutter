enum Ability {
  hero,
  moraleBoost,
  decoy,
  horn,
  mardroeme,
  youngBerserker,
  berserker,
  tightBond,
  spy,
  muster,
  scorchRow;

  String get shortName => switch (this) {
    Ability.hero => 'He',
    Ability.moraleBoost => 'MB',
    Ability.decoy => 'De',
    Ability.horn => 'Ho',
    Ability.mardroeme => 'Ma',
    Ability.youngBerserker => 'YB',
    Ability.berserker => 'Be',
    Ability.tightBond => 'TB',
    Ability.spy => 'Sp',
    Ability.muster => 'Mu',
    Ability.scorchRow => 'Sc',
  };
}
