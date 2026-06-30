import 'package:flutter/material.dart' hide Card;
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import '../resources/game_strings.dart';

sealed class EditCardResult {}

class EditCardSave extends EditCardResult {
  final Card card;
  EditCardSave(this.card);
}

class EditCardDelete extends EditCardResult {}

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
  Widget build(BuildContext context) => AlertDialog(
        title: const Text(GameStrings.editCardTitle),
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
            onPressed: () => Navigator.of(context).pop(EditCardDelete()),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(GameStrings.delete),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(GameStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(
              EditCardSave(
                widget.card.copyWith(
                  points: _points,
                  abilities: List.from(_selectedAbilities),
                ),
              ),
            ),
            child: const Text(GameStrings.save),
          ),
        ],
      );
}
