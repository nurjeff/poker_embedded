class WSMessage {
  final String event;
  final String? jsonData;

  WSMessage({required this.event, this.jsonData});

  factory WSMessage.fromJson(Map<String, dynamic> json) {
    return WSMessage(event: json['event'], jsonData: json['data']);
  }
}
