import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';

import '../../../app_theme.dart';
import '../../../domain/models/player.dart';
import '../../../widgets/hud/hud_avatar.dart';
import '../cubit/home_side_effect.dart';

/// What the saved-players sheet returns: a saved player, or `null` option for
/// the "New player" row (a bare `null` result means the sheet was dismissed).
class SavedPlayersChoice {
  const SavedPlayersChoice(this.option);

  final SavedPlayerOption? option;
}

/// Content of the saved-players bottom sheet: one row per saved player and a
/// "New player" row. Swiping a row left reveals a delete action; deleting only
/// happens after the confirmation dialog, and only removes the player from the
/// saved list (past games and scores are untouched).
class SavedPlayersSheet extends StatefulWidget {
  const SavedPlayersSheet({
    super.key,
    required this.options,
    required this.onDelete,
  });

  final List<SavedPlayerOption> options;

  /// Deletes the player; completes with `true` on success. The sheet reads
  /// this rather than the cubit because it lives in its own route, outside the
  /// screen's `BlocProvider`.
  final Future<bool> Function(Player player) onDelete;

  @override
  State<SavedPlayersSheet> createState() => _SavedPlayersSheetState();
}

class _SavedPlayersSheetState extends State<SavedPlayersSheet> {
  // A local copy so a deleted row leaves the open sheet right away. A stale
  // row could be picked again and would bring the deleted player back.
  late final List<SavedPlayerOption> _options = List.of(widget.options);

  Future<void> _confirmDelete(SavedPlayerOption option) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteSavedPlayerTitle(option.player.name)),
        content: Text(l10n.deleteSavedPlayerMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.gameCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    // Cancel and a tapped barrier both leave everything as it was.
    if (confirmed != true || !mounted) return;
    final deleted = await widget.onDelete(option.player);
    if (!deleted || !mounted) return;
    setState(() => _options.remove(option));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return ListView(
      shrinkWrap: true,
      children: [
        for (final option in _options)
          Slidable(
            key: ValueKey(option.player.id),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.3,
              children: [
                SlidableAction(
                  onPressed: (_) => _confirmDelete(option),
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                  icon: Icons.delete,
                  label: l10n.delete,
                ),
              ],
            ),
            child: ListTile(
              leading: HudAvatar(
                size: 44,
                iconSize: 22,
                image: option.photoPath == null
                    ? null
                    : FileImage(File(option.photoPath!)),
              ),
              title: Text(option.player.name),
              onTap: () =>
                  Navigator.of(context).pop(SavedPlayersChoice(option)),
            ),
          ),
        ListTile(
          leading: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.person_add_alt_1, color: AppTheme.gold),
          ),
          title: Text(l10n.newPlayer),
          onTap: () =>
              Navigator.of(context).pop(const SavedPlayersChoice(null)),
        ),
      ],
    );
  }
}
