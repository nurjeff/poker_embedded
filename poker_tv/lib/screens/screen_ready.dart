import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:lottie/lottie.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:poker_tv/network_manager.dart';
import 'package:poker_tv/screens/screen_game.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/model_color.dart';
import '../models/model_wsmessage.dart';
import '../websocket_service.dart';

class ReadyScreen extends StatefulWidget {
  const ReadyScreen({super.key});

  @override
  State<ReadyScreen> createState() => _ReadyScreenState();
}

class _ReadyScreenState extends State<ReadyScreen>
    with SingleTickerProviderStateMixin {
  late FToast fToast;
  late StreamSubscription<WSMessage> _subscription;
  late AnimationController _fadeController;
  late Animation<Color?> _fadeAnimation;
  bool isScreenSaver = false;
  bool updatingSystem = false;

  Container idleContainer = Container(
    color: Colors.black,
  );

  @override
  void initState() {
    var fToast = FToast();
    fToast.init(context);
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.black.withOpacity(1),
    ).animate(_fadeController)
      ..addListener(() {
        // Adding the listener
        if (_fadeController.status == AnimationStatus.completed &&
            !isScreenSaver) {
          setState(() {
            isScreenSaver =
                true; // Set isScreenSaver to true when animation completes
          });
        }
      });

    final webSocketService = WebSocketService();
    _subscription = webSocketService.messages.listen((message) {
      if (mounted) {
        switch (message.event) {
          case 'game_started':
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const GameScreen()),
              (route) => false,
            );
            break;
          case 'idle':
            _fadeController.forward();
            break;
          case 'connection':
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
                  Icon(Icons.cable),
                  SizedBox(
                    width: 12.0,
                  ),
                  Text("Controller-App verbunden"),
                ],
              ),
            );
            fToast.showToast(
              child: toast,
              gravity: ToastGravity.BOTTOM,
              toastDuration: const Duration(seconds: 3),
            );
          case 'accent_changed':
            var cl = WSColor.fromJson(jsonDecode(message.jsonData!));
            Widget toast = Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                color: Color.fromARGB(255, cl.red, cl.green, cl.blue),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.0),
                    child: Icon(
                      Icons.color_lens,
                      size: 30,
                    ),
                  ),
                  SizedBox(
                    width: 12.0,
                  ),
                  Text("Akzentfarbe geändert",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            );
            fToast.showToast(
              child: toast,
              gravity: ToastGravity.BOTTOM,
              toastDuration: const Duration(seconds: 1),
            );
            setState(() {});
          case 'music_changed':
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
                  Icon(Icons.cable),
                  SizedBox(
                    width: 12.0,
                  ),
                  Text("Musikeinstellungen geändert"),
                ],
              ),
            );
            fToast.showToast(
              child: toast,
              gravity: ToastGravity.BOTTOM,
              toastDuration: const Duration(seconds: 3),
            );
          case 'leds_changed':
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
                  Icon(Icons.cable),
                  SizedBox(
                    width: 12.0,
                  ),
                  Text("Ambiente-Einstellungen geändert"),
                ],
              ),
            );
            fToast.showToast(
              child: toast,
              gravity: ToastGravity.BOTTOM,
              toastDuration: const Duration(seconds: 3),
            );
          case 'shutdown':
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
                  Icon(Icons.cable),
                  SizedBox(
                    width: 12.0,
                  ),
                  Text("Wird heruntergefahren"),
                ],
              ),
            );
            fToast.showToast(
              child: toast,
              gravity: ToastGravity.BOTTOM,
              toastDuration: const Duration(seconds: 3),
            );
          case 'update_system':
            Widget toast = Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                color: const Color.fromARGB(255, 255, 123, 0),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download),
                  SizedBox(
                    width: 12.0,
                  ),
                  Text("System wird aktualisiert"),
                ],
              ),
            );
            fToast.showToast(
              child: toast,
              gravity: ToastGravity.BOTTOM,
              toastDuration: const Duration(seconds: 3),
            );
            updatingSystem = true;
            setState(() {});
            break;
          case 'update_failed':
            Widget toast = Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                color: const Color.fromARGB(255, 255, 0, 0),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download),
                  SizedBox(
                    width: 12.0,
                  ),
                  Text("Systemupdate ist fehlgeschlagen"),
                ],
              ),
            );
            fToast.showToast(
              child: toast,
              gravity: ToastGravity.BOTTOM,
              toastDuration: const Duration(seconds: 3),
            );
            updatingSystem = false;
            setState(() {});
            break;
          case 'reboot':
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
                  Icon(Icons.cable),
                  SizedBox(
                    width: 12.0,
                  ),
                  Text("Wird neugestartet"),
                ],
              ),
            );
            fToast.showToast(
              child: toast,
              gravity: ToastGravity.BOTTOM,
              toastDuration: const Duration(seconds: 3),
            );
          case 'sounds_changed':
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
                  Icon(Icons.cable),
                  SizedBox(
                    width: 12.0,
                  ),
                  Text("Audioansage-Einstellungen geändert"),
                ],
              ),
            );
            fToast.showToast(
              child: toast,
              gravity: ToastGravity.BOTTOM,
              toastDuration: const Duration(seconds: 3),
            );
          default:
            setState(() {
              isScreenSaver = false;
            });
            _fadeController.reverse();
            break;
        }
      }
    });

    NetworkManager().getGameState().then((value) {
      if (value != null) {
        if (value.gameRunning) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const GameScreen()),
            (route) => false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Widget getRenderTree() {
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
          Padding(
            padding: const EdgeInsets.all(48.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(),
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                  Text(
                    "Poker @ Jürgen's",
                    style: GoogleFonts.courgette().copyWith(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      shadows: [
                        const Shadow(
                          // Bottom-left shadow
                          color: Color.fromARGB(255, 255, 230, 120),
                          offset: Offset(-0.5, -0.5),
                          blurRadius: 16,
                        ),
                        const Shadow(
                          // Bottom-right shadow
                          color: Color.fromARGB(255, 83, 83, 83),
                          offset: Offset(-0.5, -0.5), blurRadius: 16,
                        ),
                        const Shadow(
                          // Top-right shadow
                          color: Color.fromARGB(255, 83, 83, 83),
                          offset: Offset(-0.5, -0.5), blurRadius: 16,
                        ),
                        const Shadow(
                          color: Color.fromARGB(255, 83, 83, 83),
                          offset: Offset(-0.5, -0.5),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 64,
                  ),
                  QrImageView(
                    data:
                        'https://drive.google.com/file/d/1xbYTp-LkzQMeqwqq7TLtKqUcy6z-x',
                    eyeStyle: const QrEyeStyle(
                        color: Colors.white, eyeShape: QrEyeShape.square),
                    dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.white),
                    version: QrVersions.auto,
                    size: 320,
                    gapless: false,
                  ),
                  const SizedBox(
                    height: 64,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      updatingSystem
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "System wird aktualisiert, bitte warten...",
                                  style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.yellow),
                                ),
                                SizedBox(
                                  height: 32,
                                  width: 32,
                                  child: LoadingIndicator(
                                      indicatorType:
                                          Indicator.circleStrokeSpin),
                                )
                              ],
                            )
                          : const Text(
                              "Warte auf Spielstart",
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                      const SizedBox(
                        height: 16,
                      ),
                      SizedBox(
                        height: 128,
                        child: Lottie.asset('assets/cards.json',
                            frameRate: FrameRate(30.0),
                            filterQuality: FilterQuality.medium,
                            reverse: true),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 64,
                  ),
                  const Text(
                      "Das System wird automatisch nach 10 Minuten Inaktivität in den Standby-Modus gesetzt."),
                  const Text(
                      "Die App kann einfach mithilfe des QR Code heruntergeladen werden."),
                  FutureBuilder(
                    future: getWifiIp(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          snapshot.data ?? "-:-",
                          style: TextStyle(color: Colors.grey.withAlpha(100)),
                        );
                      }
                      return Text(
                        "Rufe Netzwerkadresse ab..",
                        style: TextStyle(color: Colors.grey.withAlpha(100)),
                      );
                    },
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    '\nso far\n- jeff',
                    style: GoogleFonts.shadowsIntoLight(),
                  ),
                  const SizedBox(
                    height: 180,
                  ),
                  Expanded(
                    child: Container(),
                  )
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return IgnorePointer(
                ignoring: _fadeController.value < 1.0 ? false : true,
                child: Container(
                  color: _fadeAnimation.value,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isScreenSaver ? idleContainer : getRenderTree();
  }

  Future<String> getWifiIp() async {
    final info = NetworkInfo();
    String? wifiName = await info.getWifiName();
    String? wifiIP = await info.getWifiIP();
    if (wifiName == null && wifiIP == null) {
      return "Netzwerkinformationen konnten nicht abgerufen werden";
    }
    return "${wifiName ?? "-"}:${wifiIP ?? "-"}";
  }
}
