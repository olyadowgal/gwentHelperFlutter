import 'package:flutter/material.dart' hide Card;
import 'package:flutter/material.dart' as material show Card;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/app_theme.dart';

class CardChip extends StatelessWidget {
  /// Only used when a host theme leaves the card shape unset; the app theme
  /// always supplies one.
  static const _fallbackRadius = BorderRadius.all(Radius.circular(4));

  static const _borderWidth = 1.5;
  static const _scorchBorderWidth = 3.0;

  static const _chipWidth = 44.0;
  static const _chipHeight = 68.0;
  static const _pointsFontSize = 18.0;
  static const _abilityMarkSize = 18.0;

  final Card card;
  final int displayPoints;
  final VoidCallback onLongPress;
  final VoidCallback? onTap;
  final bool isScorchTarget;

  const CardChip({
    super.key,
    required this.card,
    required this.displayPoints,
    required this.onLongPress,
    this.onTap,
    this.isScorchTarget = false,
  });

  Widget _abilityMark(Color contentColor) {
    for (final ability in card.abilities) {
      final asset = switch (ability) {
        Ability.decoy => 'assets/icons/ic_decoy.svg',
        Ability.moraleBoost => 'assets/icons/ic_morale_boost.svg',
        Ability.tightBond => 'assets/icons/ic_tight_bond.svg',
        Ability.horn => 'assets/icons/ic_horn.svg',
        _ => null,
      };
      if (asset != null) {
        return SvgPicture.asset(
          asset,
          width: _abilityMarkSize,
          height: _abilityMarkSize,
          colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn),
        );
      }
      final icon = switch (ability) {
        Ability.spy => Icons.visibility,
        Ability.muster => Icons.groups,
        Ability.scorchRow => Icons.local_fire_department,
        _ => null,
      };
      if (icon != null) {
        return Icon(icon, size: _abilityMarkSize, color: contentColor);
      }
    }
    return const SizedBox(height: _abilityMarkSize);
  }

  /// The rounding every card in the app uses, so the Scorch border follows the
  /// chip's corners instead of squaring them off.
  BorderRadiusGeometry _cornerRadius(ThemeData theme) {
    final shape = theme.cardTheme.shape;
    return shape is RoundedRectangleBorder
        ? shape.borderRadius
        : _fallbackRadius;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isHero = card.abilities.contains(Ability.hero);
    // Scorch has to be spottable even on a hero, so it outranks the gold edge.
    final borderColor = isScorchTarget
        ? colorScheme.error
        : isHero
        ? colorScheme.primary
        : colorScheme.outline;
    // A bright card face reads as a physical piece on the dark board, unlike
    // the dark panel used for chrome (dialogs, sidebar) elsewhere. Hero
    // cards get the warmer cream, so they stand out from the rest of the
    // hand even before you spot the gold edge.
    final contentColor = AppTheme.background;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: material.Card(
        color: isHero ? AppTheme.cream : AppTheme.cardFace,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: _cornerRadius(theme),
          side: BorderSide(
            color: borderColor,
            width: isScorchTarget ? _scorchBorderWidth : _borderWidth,
          ),
        ),
        child: SizedBox(
          width: _chipWidth,
          height: _chipHeight,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$displayPoints',
                  style: TextStyle(
                    fontSize: _pointsFontSize,
                    fontWeight: FontWeight.bold,
                    color: contentColor,
                  ),
                ),
                _abilityMark(contentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
