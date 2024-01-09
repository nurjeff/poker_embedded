
import 'model_game.dart';

class GamesList {
  final List<Game> games;

  GamesList({required this.games});

  factory GamesList.fromJson(Map<String, dynamic> json) {
    var gamesList = json['games'] as List;
    List<Game> games = gamesList.map((game) => Game.fromJson(game)).toList();
    return GamesList(games: games);
  }

  Map<String, dynamic> toJson() {
    return {
      'games': games.map((game) => game.toJson()).toList(),
    };
  }
}
