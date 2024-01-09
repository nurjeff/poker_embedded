import 'dart:convert';
import 'dart:ui';

import 'package:poker_at_juergen/models/model_gamelist.dart';
import 'package:poker_at_juergen/models/model_gamestate.dart';
import 'package:poker_at_juergen/models/model_settings.dart';

import 'http_service.dart';
import 'models/model_game.dart';

class NetworkManager {
  NetworkManager._privateConstructor();

  static final NetworkManager _instance = NetworkManager._privateConstructor();

  String host = "";

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

  Future<bool> sendAwake() async {
    try {
      var response = await HttpService().get("$host/awake");
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print(e);
      return false;
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

  Future<GameSettings?> getGamesConfigSettings() async {
    try {
      var response = await HttpService().get("$host/config");
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GameSettings.fromJson(jsonData);
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

  Future<bool> updateGameConfig(int config, Game updatedGame) async {
    try {
      var response = await HttpService()
          .post("$host/update?config=$config", updatedGame.toJson());
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createGameConfig(Game createdGame) async {
    try {
      var response =
          await HttpService().post("$host/create", createdGame.toJson());
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteGameConfig(int config) async {
    print("deleting");
    try {
      var response =
          await HttpService().post("$host/delete?config=$config", null);
      if (response.statusCode == 200) {
        return true;
      }
      print(response.statusCode);
      return false;
    } catch (e) {
      return false;
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

  Future<bool> changeAccentColor(Color color) async {
    var body = {"r": color.red, "g": color.green, "b": color.blue};

    try {
      var response = await HttpService().post("$host/color", body);
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<GameState?> toggleMusic() async {
    try {
      var response = await HttpService().post("$host/toggle-music", null);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GameState.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<GameState?> toggleSounds() async {
    try {
      var response = await HttpService().post("$host/toggle-sounds", null);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GameState.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<GameState?> toggleLeds() async {
    try {
      var response = await HttpService().post("$host/toggle-leds", null);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GameState.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> shutdown() async {
    try {
      var response = await HttpService().post("$host/shutdown", null);
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateSystem() async {
    try {
      var response = await HttpService().post("$host/update-system", null);
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reboot() async {
    try {
      var response = await HttpService().post("$host/reboot", null);
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> skipRound() async {
    try {
      var response = await HttpService().post("$host/next-round", null);
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> prevRound() async {
    try {
      var response = await HttpService().post("$host/prev-round", null);
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
