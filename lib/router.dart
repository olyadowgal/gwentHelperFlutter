import 'package:go_router/go_router.dart';
import 'package:gwent_helper_flutter/features/game/view/game_page.dart';
import 'package:gwent_helper_flutter/features/home/view/home_page.dart';
import 'package:gwent_helper_flutter/features/scores/view/scores_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/game',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return GamePage(
          player1Name: extra['player1Name'] as String,
          player2Name: extra['player2Name'] as String,
          player1PhotoPath: extra['player1PhotoPath'] as String?,
          player2PhotoPath: extra['player2PhotoPath'] as String?,
        );
      },
    ),
    GoRoute(path: '/scores', builder: (context, state) => const ScoresPage()),
  ],
);
