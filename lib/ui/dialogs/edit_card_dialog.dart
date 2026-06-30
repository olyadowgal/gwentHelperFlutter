import 'package:flutter/material.dart' hide Card;
import '../../domain/models/card.dart';
import '../../domain/models/ability.dart';

class EditCardDialog extends StatefulWidget {
  final Card card;

  const EditCardDialog({super.key, required this.card});

  @override
  State<EditCardDialog> createState() => _EditCardDialogState();
}

class _EditCardDialogState extends State<EditCardDialog> {
  late int _points;
  late List<Ability> _selectedAbilities;

  @override
  void initState() {
    super.initState();
    _points = widget.card.points;
    _selectedAbilities = List.from(widget.card.abilities);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Card'),
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
          onPressed: () => Navigator.of(context).pop({'action': 'delete'}),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('DELETE'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop({
            'action': 'save',
            'card': widget.card.copyWith(
              points: _points,
              abilities: List.from(_selectedAbilities),
            ),
          }),
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}
