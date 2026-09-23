import 'package:flutter/material.dart' hide Card;
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';
import 'package:gwent_helper_flutter/l10n/domain_localizations.dart';

/// The points slider + ability toggles shared by [AddCardDialog] and
/// [EditCardDialog]. A wrapping grid instead of one tall checkbox list, so
/// all abilities fit on screen at once on the app's landscape-only layout.
class CardFormFields extends StatelessWidget {
  // Wide enough for the longest translated ability name that has no space
  // to wrap at, e.g. Dutch "Moreelverhoging" (Morale Boost) — narrower
  // widths force it to break mid-word.
  static const _abilityTileWidth = 165.0;

  final int points;
  final ValueChanged<int> onPointsChanged;
  final List<Ability> selectedAbilities;
  final ValueChanged<Ability> onAbilityToggled;

  const CardFormFields({
    super.key,
    required this.points,
    required this.onPointsChanged,
    required this.selectedAbilities,
    required this.onAbilityToggled,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.points),
            Expanded(
              child: SliderTheme(
                // The default value-indicator text color is unreadable
                // against this dark theme, so it's pinned explicitly here.
                data: SliderTheme.of(context).copyWith(
                  valueIndicatorColor: colorScheme.primary,
                  valueIndicatorTextStyle: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Slider(
                  value: points.toDouble(),
                  min: 0,
                  max: 15,
                  divisions: 15,
                  label: '$points',
                  onChanged: (v) => onPointsChanged(v.round()),
                ),
              ),
            ),
            Text('$points'),
          ],
        ),
        const Divider(),
        Text(l10n.abilities),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: Ability.values
              .map(
                (ability) => SizedBox(
                  width: _abilityTileWidth,
                  child: CheckboxListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    // CheckboxListTile's own default gap/margins assume a
                    // full-width list tile, not a compact grid cell — trim
                    // them so the tile is only as wide as it needs to be.
                    horizontalTitleGap: 4,
                    minLeadingWidth: 0,
                    minVerticalPadding: 0,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(localizedAbilityName(context, ability)),
                    value: selectedAbilities.contains(ability),
                    onChanged: (_) => onAbilityToggled(ability),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
