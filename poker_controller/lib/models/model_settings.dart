import 'package:poker_at_juergen/models/model_color.dart';

import 'model_game.dart';

class GameSettings {
  final List<Game> games;
  final WSColor accentColor;
  final bool playMusic;
  final bool playSounds;
  final bool enableLeds;

  GameSettings(
      {required this.games,
      required this.accentColor,
      required this.playMusic,
      required this.playSounds,
      required this.enableLeds});

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
      games: List<Game>.from(json['games'].map((x) => Game.fromJson(x))),
      accentColor: WSColor.fromJson(json['accent_color']),
      playMusic: json['play_music'],
      playSounds: json['play_sounds'],
      enableLeds: json['enable_leds']);
}
