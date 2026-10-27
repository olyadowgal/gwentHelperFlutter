import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';
import '../../../app_theme.dart';
import '../../../arch/bloc_side_effect_handler.dart';
import '../../../widgets/hud/hud_avatar.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_side_effect.dart';
import '../cubit/home_state.dart';
import '../widgets/background_touch_button.dart';
import '../widgets/player_input_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _p1Controller = TextEditingController();
  final _p2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _p1Controller.addListener(
      () => context.read<HomeCubit>().onPlayer1NameChanged(_p1Controller.text),
    );
    _p2Controller.addListener(
      () => context.read<HomeCubit>().onPlayer2NameChanged(_p2Controller.text),
    );
  }

  @override
  void dispose() {
    _p1Controller.dispose();
    _p2Controller.dispose();
    super.dispose();
  }

  /// Puts the cubit's name into [controller] when they differ, cursor at the
  /// end. Equal text is left alone, so there is no loop with the listeners
  /// that feed typed text back into the cubit.
  void _syncText(TextEditingController controller, String name) {
    if (controller.text == name) return;
    controller.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
  }

  Future<void> _showSavedPlayersSheet(
    bool isPlayer1,
    List<SavedPlayerOption> options,
  ) async {
    final cubit = context.read<HomeCubit>();
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<_SheetChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.panel,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppTheme.olive),
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          for (final option in options)
            ListTile(
              leading: HudAvatar(
                size: 44,
                iconSize: 22,
                image: option.photoPath == null
                    ? null
                    : FileImage(File(option.photoPath!)),
              ),
              title: Text(option.player.name),
              onTap: () => Navigator.of(context).pop(_SheetChoice(option)),
            ),
          ListTile(
            leading: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.person_add_alt_1, color: AppTheme.gold),
            ),
            title: Text(l10n.newPlayer),
            onTap: () => Navigator.of(context).pop(const _SheetChoice(null)),
          ),
        ],
      ),
    );
    // Dismissing the sheet returns null and changes nothing. The fields follow
    // the cubit's state, so they need no manual update here.
    if (choice == null) return;
    final option = choice.option;
    if (option == null) {
      cubit.onNewPlayerSelected(isPlayer1: isPlayer1);
    } else {
      await cubit.onSavedPlayerSelected(
        isPlayer1: isPlayer1,
        player: option.player,
      );
    }
  }

  Future<void> _showPhotoSourceDialog(bool isPlayer1) async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.choosePhotoSource),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              child: Text(l10n.camera),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              child: Text(l10n.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _pickPhoto(isPlayer1, source);
  }

  Future<void> _pickPhoto(bool isPlayer1, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          lockAspectRatio: true,
          // The crop rectangle is already square-locked, so the scale/rotate
          // tab bar only eats vertical space without adding a real choice.
          hideBottomControls: true,
          toolbarColor: AppTheme.background,
          toolbarWidgetColor: AppTheme.gold,
          backgroundColor: AppTheme.background,
          statusBarLight: false,
          navBarLight: false,
          activeControlsWidgetColor: AppTheme.gold,
          cropFrameColor: AppTheme.gold,
          cropGridColor: AppTheme.olive,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioLockEnabled: true,
          rotateButtonsHidden: true,
        ),
      ],
    );
    if (cropped == null || !mounted) return;
    if (isPlayer1) {
      context.read<HomeCubit>().onPlayer1PhotoPicked(cropped.path);
    } else {
      context.read<HomeCubit>().onPlayer2PhotoPicked(cropped.path);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocSideEffectHandler<HomeCubit, HomeState, HomeSideEffect>(
    listener: (context, sideEffect) {
      switch (sideEffect) {
        case NavigateToGame(
          :final player1Name,
          :final player2Name,
          :final player1PhotoPath,
          :final player2PhotoPath,
          :final player1Id,
          :final player2Id,
        ):
          context.push(
            '/game',
            extra: {
              'player1Name': player1Name,
              'player2Name': player2Name,
              'player1PhotoPath': player1PhotoPath,
              'player2PhotoPath': player2PhotoPath,
              'player1Id': player1Id,
              'player2Id': player2Id,
            },
          );
        case NavigateToScores():
          context.push('/scores');
        case ShowSavedPlayers(:final isPlayer1, :final options):
          _showSavedPlayersSheet(isPlayer1, options);
      }
    },
    // The cubit can rename a side on its own (selecting a saved player,
    // "New player", or Play linking a typed name to a saved one), so the
    // fields follow the state rather than only feeding it.
    child: BlocListener<HomeCubit, HomeState>(
      listenWhen: (previous, current) =>
          previous.player1Name != current.player1Name ||
          previous.player2Name != current.player2Name,
      listener: (context, state) {
        _syncText(_p1Controller, state.player1Name);
        _syncText(_p2Controller, state.player2Name);
      },
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            body: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BackgroundTouchButton(
                    label: l10n.scoresTooltip,
                    side: ChevronSide.right,
                    filled: true,
                    fillColor: AppTheme.sidebarSurface,
                    textColor: AppTheme.cream,
                    onTap: context.read<HomeCubit>().onScoresTapped,
                  ),
                  Expanded(
                    child: Center(
                      // The screen is locked to landscape, but the first
                      // frames can still be portrait, where the inputs do
                      // not fit.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PlayerInputWidget(
                              hint: l10n.player1,
                              controller: _p1Controller,
                              photoPath: state.player1PhotoPath,
                              onPhotoTap: () => _showPhotoSourceDialog(true),
                              savedPlayersLabel: l10n.savedPlayers,
                              onChooseSaved: () => context
                                  .read<HomeCubit>()
                                  .onSavedPlayersRequested(isPlayer1: true),
                            ),
                            const SizedBox(width: 32),
                            Text(
                              l10n.homeVs,
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            const SizedBox(width: 32),
                            PlayerInputWidget(
                              hint: l10n.player2,
                              controller: _p2Controller,
                              photoPath: state.player2PhotoPath,
                              onPhotoTap: () => _showPhotoSourceDialog(false),
                              savedPlayersLabel: l10n.savedPlayers,
                              onChooseSaved: () => context
                                  .read<HomeCubit>()
                                  .onSavedPlayersRequested(isPlayer1: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  BackgroundTouchButton(
                    label: l10n.play,
                    side: ChevronSide.left,
                    filled: true,
                    onTap: () => context.read<HomeCubit>().onPlayTapped(
                      player1Fallback: l10n.player1,
                      player2Fallback: l10n.player2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// What the saved-players sheet returns: a saved player, or `null` option for
/// the "New player" row (a bare `null` result means the sheet was dismissed).
class _SheetChoice {
  const _SheetChoice(this.option);

  final SavedPlayerOption? option;
}
