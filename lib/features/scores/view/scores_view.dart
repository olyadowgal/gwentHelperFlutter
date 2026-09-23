import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:gwent_helper_flutter/arch/bloc_side_effect_handler.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';
import '../cubit/scores_cubit.dart';
import '../cubit/scores_side_effect.dart';
import '../cubit/scores_state.dart';
import '../widgets/score_card_widget.dart';

class ScoresView extends StatelessWidget {
  const ScoresView({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSideEffectHandler<ScoresCubit, ScoresState, ScoresSideEffect>(
        listener: (context, sideEffect) {
          final l10n = AppLocalizations.of(context)!;
          switch (sideEffect) {
            case ShowClearConfirmDialog():
              showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(l10n.clearConfirmTitle),
                  content: Text(l10n.clearConfirmContent),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l10n.scoresCancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(l10n.clear),
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
          builder: (context, state) {
            final l10n = AppLocalizations.of(context)!;
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                leading: IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: SvgPicture.asset(
                    'assets/icons/ic_baseline_arrow_back.svg',
                    key: const Key('scores-back-icon'),
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  Builder(
                    builder: (context) {
                      void clearAll() =>
                          context.read<ScoresCubit>().onClearAllTapped();
                      return Semantics(
                        button: true,
                        label: l10n.scoresClearAll,
                        onLongPress: clearAll,
                        excludeSemantics: true,
                        child: Tooltip(
                          message: l10n.scoresClearAll,
                          triggerMode: TooltipTriggerMode.tap,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onLongPress: clearAll,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: SvgPicture.asset(
                                'assets/icons/ic_trash.svg',
                                key: const Key('scores-clear-icon'),
                                width: 24,
                                height: 24,
                                colorFilter: ColorFilter.mode(
                                  Theme.of(context).colorScheme.error,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: switch (state) {
                ScoresState(isLoading: true) => const Center(
                  child: CircularProgressIndicator(),
                ),
                ScoresState(errorMessage: final msg) when msg != null => Center(
                  child: Text(l10n.errorMessage(msg)),
                ),
                ScoresState(scores: final scores) when scores.isEmpty => Center(
                  child: Text(l10n.scoresEmpty),
                ),
                ScoresState(scores: final scores) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: scores.length,
                  itemBuilder: (context, index) =>
                      ScoreCardWidget(score: scores[index]),
                ),
              },
            );
          },
        ),
      );
}
