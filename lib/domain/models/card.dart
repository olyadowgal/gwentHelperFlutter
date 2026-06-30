import 'package:uuid/uuid.dart';
import 'ability.dart';

class Card {
  final String cardId;
  final int points;
  final List<Ability> abilities;

  Card({
    String? cardId,
    required this.points,
    required this.abilities,
  }) : cardId = cardId ?? const Uuid().v4();

  Card copyWith({int? points, List<Ability>? abilities}) {
    return Card(
      cardId: cardId,
      points: points ?? this.points,
      abilities: abilities ?? this.abilities,
    );
  }
}
