class WSColor {
  final int red;
  final int green;
  final int blue;

  WSColor({required this.red, required this.green, required this.blue});

  factory WSColor.fromJson(Map<String, dynamic> json) {
    return WSColor(red: json['r'], green: json['g'], blue: json['b']);
  }
}
