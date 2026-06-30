import 'package:go_router/go_router.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/scores_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) {
        final extra = state.extra as Map<String, String?>;
        return GameScreen(
          player1Name: extra['player1Name'] ?? 'Player 1',
          player2Name: extra['player2Name'] ?? 'Player 2',
          player1PhotoPath: extra['player1PhotoPath'],
          player2PhotoPath: extra['player2PhotoPath'],
        );
      },
    ),
    GoRoute(
      path: '/scores',
      builder: (context, state) => const ScoresScreen(),
    ),
  ],
);
