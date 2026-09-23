import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';
import '../../../app_theme.dart';
import '../../../arch/bloc_side_effect_handler.dart';
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
  Widget build(BuildContext context) =>
      BlocSideEffectHandler<HomeCubit, HomeState, HomeSideEffect>(
        listener: (context, sideEffect) {
          switch (sideEffect) {
            case NavigateToGame(
              :final player1Name,
              :final player2Name,
              :final player1PhotoPath,
              :final player2PhotoPath,
            ):
              context.push(
                '/game',
                extra: {
                  'player1Name': player1Name,
                  'player2Name': player2Name,
                  'player1PhotoPath': player1PhotoPath,
                  'player2PhotoPath': player2PhotoPath,
                },
              );
            case NavigateToScores():
              context.push('/scores');
          }
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
      );
}
