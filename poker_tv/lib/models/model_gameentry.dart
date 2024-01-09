class GameEntry {
  final bool isPause;
  final int durationMinutes;
  final int smallBlind;
  final int bigBlind;

  GameEntry(
      {required this.isPause,
      required this.durationMinutes,
      required this.smallBlind,
      required this.bigBlind});

  factory GameEntry.fromJson(Map<String, dynamic> json) {
    return GameEntry(
      isPause: json['is_pause'],
      durationMinutes: json['duration_minutes'],
      smallBlind: json['small_blind'],
      bigBlind: json['big_blind'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_pause': isPause,
      'duration_minutes': durationMinutes,
      'small_blind': smallBlind,
      'big_blind': bigBlind,
    };
  }
}
