import 'package:flutter/material.dart' hide Card;
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import '../resources/game_strings.dart';
import 'card_form_fields.dart';

sealed class EditCardResult {
  const EditCardResult();
}

class EditCardSave extends EditCardResult {
  final Card card;
  EditCardSave(this.card);
}

class EditCardDelete extends EditCardResult {
  const EditCardDelete();
}

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

  void _toggleAbility(Ability ability) => setState(() {
    if (_selectedAbilities.contains(ability)) {
      _selectedAbilities.remove(ability);
    } else {
      _selectedAbilities.add(ability);
    }
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return AlertDialog(
      title: const Text(GameStrings.editCardTitle),
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
          onPressed: () => Navigator.of(context).pop(const EditCardDelete()),
          // The gold outline the theme gives secondary actions would read as
          // safe here, so this button outlines itself in the error color.
          style: TextButton.styleFrom(
            foregroundColor: errorColor,
            side: BorderSide(color: errorColor),
          ),
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
}
