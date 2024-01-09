import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'models/model_wsmessage.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocket? _socket;
  final _controller = StreamController<WSMessage>.broadcast();
  final _reconnectInterval = const Duration(seconds: 10);
  Timer? _reconnectTimer;
  String? _url;

  void Function()? onConnectionBroken;

  Future<void> connect(String url) async {
    _url = url;
    await _attemptConnect();
  }

  Future<void> _attemptConnect() async {
    if (_socket != null) {
      return;
    }

    try {
      _socket = await WebSocket.connect(_url!);
      print("Websocket connected");
      _socket!.listen(
        (data) {
          try {
            var msg = WSMessage.fromJson(jsonDecode(data));
            _controller.sink.add(msg);
          } catch (e) {
            print(e);
          }
        },
        onDone: _handleConnectionClosed,
        onError: (error) {
          _handleConnectionClosed();
        },
        cancelOnError: true,
      );
      _socket!.pingInterval = const Duration(seconds: 15);
    } catch (e) {
      _handleConnectionClosed();
    }
  }

  void _handleConnectionClosed() {
    if (onConnectionBroken != null) {
      onConnectionBroken!();
    }
    _socket?.close();
    _socket = null;
    _startReconnectTimer();
  }

  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectInterval, _attemptConnect);
  }

  Stream<WSMessage> get messages => _controller.stream;

  void dispose() {
    _reconnectTimer?.cancel();
    _controller.close();
    _socket?.close();
  }
}
