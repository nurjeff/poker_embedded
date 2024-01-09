import 'package:poker_at_juergen/models/model_color.dart';

class GameState {
  final bool gameRunning;
  final int totalRounds;
  final int currentGameId;
  final int currentRoundId;
  final int elapsedSecondsThisRound;
  final DateTime? startTime;
  final bool paused;
  final int currentRoundDurationSeconds;
  final int currentSmallBlind;
  final int currentBigBlind;
  final int nextSmallBlind;
  final int nextBigBlind;
  final bool isPauseRound;
  final bool nextIsPauseRound;
  final WSColor currentAccentcolor;

  GameState(
      {required this.gameRunning,
      required this.totalRounds,
      required this.currentGameId,
      required this.currentRoundId,
      required this.elapsedSecondsThisRound,
      this.startTime,
      required this.paused,
      required this.currentRoundDurationSeconds,
      required this.currentSmallBlind,
      required this.currentBigBlind,
      required this.nextSmallBlind,
      required this.nextBigBlind,
      required this.isPauseRound,
      required this.nextIsPauseRound,
      required this.currentAccentcolor});

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      gameRunning: json['game_running'] as bool,
      totalRounds: json['total_rounds'] as int,
      currentGameId: json['current_game_id'] as int,
      currentRoundId: json['current_round_id'] as int,
      elapsedSecondsThisRound: json['elapsed_seconds_this_round'] as int,
      startTime: json['start_time'] == null
          ? null
          : DateTime.parse(json['start_time']),
      paused: json['paused'] as bool,
      currentRoundDurationSeconds:
          json['current_round_duration_seconds'] as int,
      currentSmallBlind: json['current_small_blind'] as int,
      currentBigBlind: json['current_big_blind'] as int,
      nextSmallBlind: json['next_small_blind'] as int,
      nextBigBlind: json['next_big_blind'] as int,
      isPauseRound: json['is_pause_round'] as bool,
      nextIsPauseRound: json['next_is_pause_round'] as bool,
      currentAccentcolor: WSColor.fromJson(json['current_accent_color']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'game_running': gameRunning,
      'total_rounds': totalRounds,
      'current_game_id': currentGameId,
      'current_round_id': currentRoundId,
      'elapsed_seconds_this_round': elapsedSecondsThisRound,
      'start_time': startTime?.toIso8601String(),
      'paused': paused,
      'current_round_duration_seconds': currentRoundDurationSeconds,
      'current_small_blind': currentSmallBlind,
      'current_big_blind': currentBigBlind,
      'next_small_blind': nextSmallBlind,
      'next_big_blind': nextBigBlind,
    };
  }
}
