import 'package:flutter/material.dart' hide Card;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';
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
  /// Names the header's icon-only delete button so tests can find it
  /// without relying on its (absent) label text.
  static const deleteButtonKey = Key('edit-card-delete-button');

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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      // Trimmed from Material's roomy defaults so the ability grid gets the
      // width back instead of it being eaten by dialog chrome.
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      // Delete/Cancel/Save live in the header, not the footer, so they're
      // always in view even before the ability grid below has been
      // scrolled to. Delete is icon-only (matching the Scores screen's
      // trash icon) so three actions still fit alongside the title.
      title: Row(
        children: [
          Expanded(
            child: Text(l10n.editCardTitle, overflow: TextOverflow.ellipsis),
          ),
          Tooltip(
            message: l10n.delete,
            child: IconButton(
              key: EditCardDialog.deleteButtonKey,
              onPressed: () =>
                  Navigator.of(context).pop(const EditCardDelete()),
              icon: SvgPicture.asset(
                'assets/icons/ic_trash.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(errorColor, BlendMode.srcIn),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.gameCancel),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(
              EditCardSave(
                widget.card.copyWith(
                  points: _points,
                  abilities: List.from(_selectedAbilities),
                ),
              ),
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
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
    );
  }
}
