import 'package:flutter/material.dart' hide Card;
import 'package:flutter/material.dart' as material show Card;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';

class CardChip extends StatelessWidget {
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
          width: 14,
          height: 14,
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
        return Icon(icon, size: 14, color: contentColor);
      }
    }
    return const SizedBox(height: 14);
  }

  @override
  Widget build(BuildContext context) {
    final isHero = card.abilities.contains(Ability.hero);
    final contentColor = Theme.of(context).colorScheme.onSecondary;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: material.Card(
        color: isHero ? Theme.of(context).colorScheme.secondary : Colors.white,
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        shape: isScorchTarget
            ? RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 3,
                ),
              )
            : null,
        child: SizedBox(
          width: 28,
          height: 44,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$displayPoints',
                  style: TextStyle(
                    fontSize: 13,
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
