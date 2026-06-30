import 'package:flutter/material.dart' hide Card;
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import '../resources/game_strings.dart';

class AddCardDialog extends StatefulWidget {
  final CardsRowType rowType;

  const AddCardDialog({super.key, required this.rowType});

  @override
  State<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  int _points = 0;
  final List<Ability> _selectedAbilities = [];

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
            '${GameStrings.addCardTitle} (${widget.rowType.displayName})'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(GameStrings.points),
                  Expanded(
                    child: Slider(
                      value: _points.toDouble(),
                      min: 0,
                      max: 15,
                      divisions: 15,
                      label: '$_points',
                      onChanged: (v) => setState(() => _points = v.round()),
                    ),
                  ),
                  Text('$_points'),
                ],
              ),
              const Divider(),
              const Text(GameStrings.abilities),
              ...Ability.values.map(
                (ability) => CheckboxListTile(
                  title: Text(ability.displayName),
                  value: _selectedAbilities.contains(ability),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selectedAbilities.add(ability);
                    } else {
                      _selectedAbilities.remove(ability);
                    }
                  }),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(GameStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(
              Card(
                points: _points,
                abilities: List.from(_selectedAbilities),
              ),
            ),
            child: const Text(GameStrings.add),
          ),
        ],
      );
}
