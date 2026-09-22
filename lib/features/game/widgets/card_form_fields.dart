import 'package:flutter/material.dart' hide Card;
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import '../resources/game_strings.dart';

/// The points slider + ability toggles shared by [AddCardDialog] and
/// [EditCardDialog]. A wrapping grid instead of one tall checkbox list, so
/// all abilities fit on screen at once on the app's landscape-only layout.
class CardFormFields extends StatelessWidget {
  static const _abilityTileWidth = 200.0;

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
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Text(GameStrings.points),
          Expanded(
            child: Slider(
              value: points.toDouble(),
              min: 0,
              max: 15,
              divisions: 15,
              label: '$points',
              onChanged: (v) => onPointsChanged(v.round()),
            ),
          ),
          Text('$points'),
        ],
      ),
      const Divider(),
      const Text(GameStrings.abilities),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        children: Ability.values
            .map(
              (ability) => SizedBox(
                width: _abilityTileWidth,
                child: CheckboxListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(ability.displayName),
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
