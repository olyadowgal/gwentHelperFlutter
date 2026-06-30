import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:gwent_helper_flutter/arch/bloc_side_effect_handler.dart';
import '../cubit/scores_cubit.dart';
import '../cubit/scores_side_effect.dart';
import '../cubit/scores_state.dart';
import '../resources/scores_strings.dart';
import '../widgets/score_card_widget.dart';

class ScoresView extends StatelessWidget {
  const ScoresView({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSideEffectHandler<ScoresCubit, ScoresState, ScoresSideEffect>(
        listener: (context, sideEffect) {
          switch (sideEffect) {
            case ShowClearConfirmDialog():
              showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text(ScoresStrings.clearConfirmTitle),
                  content: const Text(ScoresStrings.clearConfirmContent),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(ScoresStrings.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(ScoresStrings.clear),
                    ),
                  ],
                ),
              ).then((confirmed) {
                if (confirmed == true && context.mounted) {
                  context.read<ScoresCubit>().onClearConfirmed();
                }
              });
          }
        },
        child: BlocBuilder<ScoresCubit, ScoresState>(
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              leading: IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/ic_baseline_arrow_back.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFC4C5C5),
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () => context.pop(),
              ),
              actions: [
                GestureDetector(
                  onLongPress: () =>
                      context.read<ScoresCubit>().onClearAllTapped(),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      'assets/icons/ic_trash.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFC4C5C5),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: switch (state) {
              ScoresState(isLoading: true) =>
                const Center(child: CircularProgressIndicator()),
              ScoresState(errorMessage: final msg) when msg != null =>
                Center(child: Text('${ScoresStrings.errorPrefix}$msg')),
              ScoresState(scores: final scores) when scores.isEmpty =>
                const Center(child: Text(ScoresStrings.empty)),
              ScoresState(scores: final scores) => ListView.builder(
                  itemCount: scores.length,
                  itemBuilder: (context, index) =>
                      ScoreCardWidget(score: scores[index]),
                ),
            },
          ),
        ),
      );
}
