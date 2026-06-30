import 'package:flutter/material.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';

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
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _WeatherToggle(
            label: 'Frost',
            icon: Icons.ac_unit,
            active: frostActive,
            onChanged: (v) => onChanged(CardsRowType.closeCombat, v),
          ),
          _WeatherToggle(
            label: 'Fog',
            icon: Icons.cloud,
            active: fogActive,
            onChanged: (v) => onChanged(CardsRowType.longRange, v),
          ),
          _WeatherToggle(
            label: 'Rain',
            icon: Icons.umbrella,
            active: rainActive,
            onChanged: (v) => onChanged(CardsRowType.siege, v),
          ),
        ],
      );
}

class _WeatherToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final ValueChanged<bool> onChanged;

  const _WeatherToggle({
    required this.label,
    required this.icon,
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onChanged(!active),
        child: Column(
          children: [
            Icon(icon, color: active ? Colors.blue : Colors.grey),
            Text(label, style: TextStyle(color: active ? Colors.blue : Colors.grey)),
          ],
        ),
      );
}
