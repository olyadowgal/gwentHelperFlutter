import 'package:flutter/widgets.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'app_localizations.dart';

/// Localized display names for domain enums. Lives here, not on the enums
/// themselves, because domain models don't depend on Flutter/BuildContext.
String localizedAbilityName(BuildContext context, Ability ability) {
  final l10n = AppLocalizations.of(context)!;
  return switch (ability) {
    Ability.hero => l10n.abilityHero,
    Ability.moraleBoost => l10n.abilityMoraleBoost,
    Ability.decoy => l10n.abilityDecoy,
    Ability.horn => l10n.abilityHorn,
    Ability.mardroeme => l10n.abilityMardroeme,
    Ability.youngBerserker => l10n.abilityYoungBerserker,
    Ability.berserker => l10n.abilityBerserker,
    Ability.tightBond => l10n.abilityTightBond,
    Ability.spy => l10n.abilitySpy,
    Ability.muster => l10n.abilityMuster,
    Ability.scorchRow => l10n.abilityScorchRow,
  };
}

String localizedRowTypeName(BuildContext context, CardsRowType rowType) {
  final l10n = AppLocalizations.of(context)!;
  return switch (rowType) {
    CardsRowType.closeCombat => l10n.rowCloseCombat,
    CardsRowType.longRange => l10n.rowLongRange,
    CardsRowType.siege => l10n.rowSiege,
  };
}
