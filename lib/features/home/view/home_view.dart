import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../arch/bloc_side_effect_handler.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_side_effect.dart';
import '../cubit/home_state.dart';
import '../resources/home_strings.dart';
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
  void dispose() {
    _p1Controller.dispose();
    _p2Controller.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(BuildContext context, bool isPlayer1) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
            aspectRatioPresets: [CropAspectRatioPreset.square]),
        IOSUiSettings(aspectRatioPresets: [CropAspectRatioPreset.square]),
      ],
    );
    if (cropped == null) return;
    if (!context.mounted) return;

    final cubit = context.read<HomeCubit>();
    if (isPlayer1) {
      cubit.onPlayer1PhotoPicked(cropped.path);
    } else {
      cubit.onPlayer2PhotoPicked(cropped.path);
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
              context.push('/game', extra: {
                'player1Name': player1Name,
                'player2Name': player2Name,
                'player1PhotoPath': player1PhotoPath,
                'player2PhotoPath': player2PhotoPath,
              });
            case NavigateToScores():
              context.push('/scores');
          }
        },
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text(HomeStrings.appTitle)),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      PlayerInputWidget(
                        label: HomeStrings.player1,
                        controller: _p1Controller,
                        photoPath: state.player1PhotoPath,
                        onPhotoTap: () => _pickPhoto(context, true),
                        onNameChanged:
                            context.read<HomeCubit>().onPlayer1NameChanged,
                      ),
                      const Text(
                        HomeStrings.vs,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      PlayerInputWidget(
                        label: HomeStrings.player2,
                        controller: _p2Controller,
                        photoPath: state.player2PhotoPath,
                        onPhotoTap: () => _pickPhoto(context, false),
                        onNameChanged:
                            context.read<HomeCubit>().onPlayer2NameChanged,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: context.read<HomeCubit>().onPlayTapped,
                    child: const Text(HomeStrings.play),
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: const Icon(Icons.leaderboard),
                    tooltip: HomeStrings.scoresTooltip,
                    onPressed: context.read<HomeCubit>().onScoresTapped,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
