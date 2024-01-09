import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';
import 'package:poker_tv/network_manager.dart';
import 'package:poker_tv/screens/screen_ready.dart';

import '../websocket_service.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  @override
  void initState() {
    super.initState();
    _fetchGamesConfig();
  }

  Future<void> _fetchGamesConfig() async {
    Future.delayed(const Duration(seconds: 3)).then((value) async {
      while (true) {
        var gamesList = await NetworkManager().getGamesConfig();
        if (gamesList != null) {
          // ignore: use_build_context_synchronously
          final webSocketService = WebSocketService();
          var wsurl =
              // ignore: prefer_interpolation_to_compose_strings
              'ws://' + NetworkManager().host.replaceAll("http://", "") + "/ws";
          await webSocketService.connect(wsurl);

          var fToast = FToast();
          // ignore: use_build_context_synchronously
          fToast.init(context);
          Widget toast = Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.0),
              color: const Color.fromARGB(255, 0, 126, 4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check),
                SizedBox(
                  width: 12.0,
                ),
                Text("Verbindung erfolgreich hergestellt"),
              ],
            ),
          );
          fToast.showToast(
            child: toast,
            gravity: ToastGravity.BOTTOM,
            toastDuration: const Duration(seconds: 5),
          );

          // ignore: use_build_context_synchronously
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ReadyScreen()),
            (route) => false,
          );
          break;
        } else {
          await Future.delayed(const Duration(milliseconds: 250));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var indicatorHeight = MediaQuery.of(context).size.height / 3;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
          ),
          SizedBox(
              width: MediaQuery.of(context).size.width,
              height: double.infinity,
              child: Opacity(
                opacity: .5,
                child: Image.asset(
                  "assets/background.jpg",
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              )),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: indicatorHeight,
                  child: Lottie.asset('assets/cards.json',
                      frameRate: FrameRate(30.0),
                      filterQuality: FilterQuality.high,
                      reverse: true),
                ),
                const Text(
                  "Verbinde zu Server",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
