import 'model_gameentry.dart';

class Game {
  String name;
  final bool canBeDeleted;
  final List<GameEntry> gameEntries;

  Game(
      {required this.name,
      required this.canBeDeleted,
      required this.gameEntries});

  factory Game.fromJson(Map<String, dynamic> json) {
    var gameEntriesList = json['game_entries'] as List;
    List<GameEntry> gameEntries =
        gameEntriesList.map((entry) => GameEntry.fromJson(entry)).toList();
    return Game(
      name: json['name'],
      canBeDeleted: json['can_be_deleted'],
      gameEntries: gameEntries,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'can_be_deleted': canBeDeleted,
      'game_entries': gameEntries.map((entry) => entry.toJson()).toList(),
    };
  }
}
