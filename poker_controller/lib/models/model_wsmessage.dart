class WSMessage {
  final String event;

  WSMessage({required this.event});

  factory WSMessage.fromJson(Map<String, dynamic> json) {
    return WSMessage(
      event: json['event'],
    );
  }
}
