import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';

class WeatherWidget extends StatelessWidget {
  final bool frostActive;
  final bool fogActive;
  final bool rainActive;
  final void Function(CardsRowType, bool) onChanged;

  const WeatherWidget({
    super.key,
    required this.frostActive,
    required this.fogActive,
    required this.rainActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WeatherToggle(
          icon: 'assets/icons/ic_frost.svg',
          label: l10n.frost,
          active: frostActive,
          onTap: () => onChanged(CardsRowType.closeCombat, !frostActive),
        ),
        _WeatherToggle(
          icon: 'assets/icons/ic_fog.svg',
          label: l10n.fog,
          active: fogActive,
          onTap: () => onChanged(CardsRowType.longRange, !fogActive),
        ),
        _WeatherToggle(
          icon: 'assets/icons/ic_rain.svg',
          label: l10n.rain,
          active: rainActive,
          onTap: () => onChanged(CardsRowType.siege, !rainActive),
        ),
      ],
    );
  }
}

class _WeatherToggle extends StatelessWidget {
  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _WeatherToggle({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Tooltip(
          message: label,
          child: SvgPicture.asset(
            icon,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
