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

  String get displayName => switch (this) {
    Ability.hero => 'Hero',
    Ability.moraleBoost => 'Morale Boost',
    Ability.decoy => 'Decoy',
    Ability.horn => 'Horn',
    Ability.mardroeme => 'Mardroeme',
    Ability.youngBerserker => 'Young Berserker',
    Ability.berserker => 'Berserker',
    Ability.tightBond => 'Tight Bond',
    Ability.spy => 'Spy',
    Ability.muster => 'Muster',
    Ability.scorchRow => 'Scorch (Row)',
  };

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
