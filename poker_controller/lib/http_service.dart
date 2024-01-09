import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpService {
  static final HttpService _instance = HttpService._internal();

  factory HttpService() {
    return _instance;
  }

  HttpService._internal();

  Future<http.Response> get(String url) async {
    final uri = Uri.parse(url);
    return await http.get(uri);
  }

  Future<http.Response> post(String url, Map<String, dynamic>? data) async {
    final uri = Uri.parse(url);
    return await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: data != null ? json.encode(data) : null,
    );
  }
}
