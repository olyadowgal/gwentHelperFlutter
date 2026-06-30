enum Ability {
  hero,
  moraleBoost,
  decoy,
  horn,
  mardroeme,
  youngBerserker,
  berserker,
  tightBond;

  String get displayName => switch (this) {
    Ability.hero => 'Hero',
    Ability.moraleBoost => 'Morale Boost',
    Ability.decoy => 'Decoy',
    Ability.horn => 'Horn',
    Ability.mardroeme => 'Mardroeme',
    Ability.youngBerserker => 'Young Berserker',
    Ability.berserker => 'Berserker',
    Ability.tightBond => 'Tight Bond',
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
      };
}
