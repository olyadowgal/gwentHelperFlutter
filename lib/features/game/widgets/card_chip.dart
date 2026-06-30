import 'package:flutter/material.dart' hide Card;
import 'package:flutter/material.dart' as material show Card;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';

class CardChip extends StatelessWidget {
  final Card card;
  final int displayPoints;
  final VoidCallback onLongPress;

  const CardChip({
    super.key,
    required this.card,
    required this.displayPoints,
    required this.onLongPress,
  });

  String? _abilityIcon() {
    for (final ability in card.abilities) {
      final icon = switch (ability) {
        Ability.decoy => 'assets/icons/ic_decoy.svg',
        Ability.moraleBoost => 'assets/icons/ic_morale_boost.svg',
        Ability.tightBond => 'assets/icons/ic_tight_bond.svg',
        Ability.horn => 'assets/icons/ic_horn.svg',
        _ => null,
      };
      if (icon != null) return icon;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isHero = card.abilities.contains(Ability.hero);
    final iconPath = _abilityIcon();
    // CardChip always sits on a white or hero (secondary) background, both
    // light. onSecondary is theme-confirmed to equal 0xFF263238 (Task 2),
    // matching the dark text/icon color needed for contrast on either.
    final contentColor = Theme.of(context).colorScheme.onSecondary;
    return GestureDetector(
      onLongPress: onLongPress,
      child: material.Card(
        color: isHero
            ? Theme.of(context).colorScheme.secondary
            : Colors.white,
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
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
                if (iconPath != null)
                  SvgPicture.asset(
                    iconPath,
                    width: 14,
                    height: 14,
                    colorFilter: ColorFilter.mode(
                      contentColor,
                      BlendMode.srcIn,
                    ),
                  )
                else
                  const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
