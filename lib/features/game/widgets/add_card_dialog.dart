import 'package:flutter/material.dart' hide Card;
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import '../resources/game_strings.dart';
import 'card_form_fields.dart';

class AddCardDialog extends StatefulWidget {
  final CardsRowType rowType;

  const AddCardDialog({super.key, required this.rowType});

  @override
  State<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  int _points = 0;
  final List<Ability> _selectedAbilities = [];

  void _toggleAbility(Ability ability) => setState(() {
    if (_selectedAbilities.contains(ability)) {
      _selectedAbilities.remove(ability);
    } else {
      _selectedAbilities.add(ability);
    }
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${GameStrings.addCardTitle} (${widget.rowType.displayName})'),
    content: SingleChildScrollView(
      // Wide enough that the ability grid fits in a few columns instead of
      // one tall list, capped so it never overflows a narrow screen.
      child: SizedBox(
        width: (MediaQuery.sizeOf(context).width * 0.8).clamp(360.0, 720.0),
        child: CardFormFields(
          points: _points,
          onPointsChanged: (v) => setState(() => _points = v),
          selectedAbilities: _selectedAbilities,
          onAbilityToggled: _toggleAbility,
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(GameStrings.cancel),
      ),
      ElevatedButton(
        onPressed: () => Navigator.of(context).pop(
          Card(points: _points, abilities: List.from(_selectedAbilities)),
        ),
        child: const Text(GameStrings.add),
      ),
    ],
  );
}
