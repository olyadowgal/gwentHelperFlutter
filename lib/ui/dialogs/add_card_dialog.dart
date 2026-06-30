import 'package:flutter/material.dart' hide Card;
import '../../domain/models/card.dart';
import '../../domain/models/ability.dart';
import '../../domain/models/cards_row_type.dart';

class AddCardDialog extends StatefulWidget {
  final CardsRowType rowType;

  const AddCardDialog({super.key, required this.rowType});

  @override
  State<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  int _points = 1;
  final List<Ability> _selectedAbilities = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Card (${widget.rowType.displayName})'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Points:'),
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
            const Text('Abilities:'),
            ...Ability.values.map((ability) => CheckboxListTile(
                  title: Text(ability.displayName),
                  value: _selectedAbilities.contains(ability),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selectedAbilities.add(ability);
                    } else {
                      _selectedAbilities.remove(ability);
                    }
                  }),
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(
            Card(points: _points, abilities: List.from(_selectedAbilities)),
          ),
          child: const Text('ADD'),
        ),
      ],
    );
  }
}
