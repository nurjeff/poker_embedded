import 'dart:convert';
import 'http_service.dart';
import 'models/model_gamelist.dart';
import 'models/model_gamestate.dart';

class NetworkManager {
  NetworkManager._privateConstructor();

  static final NetworkManager _instance = NetworkManager._privateConstructor();

  String host = "http://127.0.0.1:49267/api/v1/poker";

  factory NetworkManager() {
    return _instance;
  }

  Future<GameState?> getGameState() async {
    try {
      var response = await HttpService().get("$host/state");
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GameState.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<GamesList?> getGamesConfig() async {
    try {
      var response = await HttpService().get("$host/config");
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GamesList.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<GameState?> startGame(int config) async {
    try {
      var response =
          await HttpService().post("$host/start?config=$config", null);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GameState.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<GameState?> stopGame() async {
    try {
      var response = await HttpService().post("$host/stop", null);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GameState.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<GameState?> pauseResumeGame() async {
    try {
      var response = await HttpService().post("$host/pause-resume", null);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GameState.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
