import 'dart:async';
import 'dart:convert';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:poker_tv/models/model_color.dart';
import 'package:poker_tv/models/model_gamestate.dart';
import 'package:poker_tv/network_manager.dart';
import 'package:poker_tv/screens/screen_ready.dart';
import 'package:intl/intl.dart';

import '../models/model_wsmessage.dart';
import '../websocket_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<WSMessage> _subscription;
  Future<GameState?> _gameStateFuture = NetworkManager().getGameState();
  final CountDownController _countDownController = CountDownController();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  late FToast fToast;

  Timer? timer;

  double cardOpacity = 0.0;

  WSColor? currentAccentColor;

  final FlipCardController _flipCardController = FlipCardController();

  void refreshData() {
    setState(() {
      _gameStateFuture = NetworkManager().getGameState();
    });
  }

  void fadeInOut() {
    // Fade in
    setState(() => cardOpacity = 1.0);

    // Fade out after 10 seconds
    Timer(const Duration(seconds: 10), () {
      setState(() => cardOpacity = 0.0);
    });
  }

  @override
  void initState() {
    _flipCardController.toggleCard();
    timer = Timer.periodic(const Duration(seconds: 4),
        (Timer t) => _flipCardController.toggleCard());
    var fToast = FToast();
    fToast.init(context);
    final webSocketService = WebSocketService();
    _subscription = webSocketService.messages.listen((message) {
      if (mounted) {
        refreshData();
        switch (message.event) {
          case 'game_stopped':
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ReadyScreen()),
              (route) => false,
            );
            break;
          case 'game_paused':
            _countDownController.pause();
            Widget toast = Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                color: const Color.fromARGB(255, 204, 109, 0),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.0),
                    child: Icon(
                      Icons.pause,
                      size: 30,
                    ),
                  ),
                  SizedBox(
                    width: 12.0,
                  ),
                  Text("Zeit pausiert",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            );
            fToast.showToast(
              child: toast,
              gravity: ToastGravity.BOTTOM,
              toastDuration: const Duration(seconds: 3),
            );
          case 'game_resumed':
            _countDownController.resume();
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
                  Padding(
                    padding: EdgeInsets.only(top: 2.0),
                    child: Icon(
                      Icons.play_arrow,
                      size: 30,
                    ),
                  ),
                  SizedBox(
                    width: 12.0,
                  ),
                  Text("Zeit gestartet",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            );
            fToast.showToast(
              child: toast,
              gravity: ToastGravity.BOTTOM,
              toastDuration: const Duration(seconds: 3),
            );
          case 'game_started':
            _countDownController.restart();
            break;
          case 'round_changed':
            fadeInOut();
            _animationController.forward(from: 0.0);
            _countDownController.restart();
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
            currentAccentColor = cl;
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
          case 'skip_round':
            Widget toast = Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                color: const Color.fromARGB(255, 204, 109, 0),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cable),
                  SizedBox(
                    width: 12.0,
                  ),
                  Text("Runde manuell übersprungen!"),
                ],
              ),
            );
            fToast.showToast(
              child: toast,
              gravity: ToastGravity.BOTTOM,
              toastDuration: const Duration(seconds: 3),
            );
          case 'prev_round':
            Widget toast = Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                color: const Color.fromARGB(255, 204, 109, 0),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cable),
                  SizedBox(
                    width: 12.0,
                  ),
                  Text("Runde manuell zurückgesetzt!"),
                ],
              ),
            );
            fToast.showToast(
              child: toast,
              gravity: ToastGravity.BOTTOM,
              toastDuration: const Duration(seconds: 3),
            );
        }
      }
    });
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.easeInOutCubicEmphasized),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reverse();
        }
      });
  }

  @override
  void dispose() {
    timer?.cancel();
    _animationController.dispose();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            ),
          ),
          FutureBuilder(
            future: _gameStateFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Stack(children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 40.0),
                      child: AnimatedOpacity(
                        opacity: cardOpacity,
                        duration: const Duration(seconds: 5),
                        child: FlipCard(
                          speed: 1000,
                          controller: _flipCardController,
                          fill: Fill.fillBack,
                          direction: FlipDirection.VERTICAL,
                          side: CardSide.FRONT,
                          front: SizedBox(
                              width: 450,
                              height: 563,
                              child: Stack(
                                children: [
                                  Image.asset(
                                    "assets/spadecard.png",
                                    fit: BoxFit.fill,
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 80.0, vertical: 8),
                                        child: Container(
                                          color: Colors.white.withAlpha(220),
                                          width: double.infinity,
                                          height: double.infinity,
                                          child: Center(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                      "Runde: ${snapshot.data!.currentRoundId + 1}",
                                                      style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 32,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  Text(
                                                      "Insgesamt: ${snapshot.data!.totalRounds}",
                                                      style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 32,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  const SizedBox(
                                                    height: 32,
                                                  ),
                                                  Text(
                                                    "Spiel läuft seit ${DateTime.now().difference(snapshot.data!.startTime!).inMinutes} Minuten",
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 32,
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              )),
                          back: SizedBox(
                              width: 450,
                              height: 563,
                              child: Stack(
                                children: [
                                  Image.asset(
                                    "assets/heartcard.png",
                                    fit: BoxFit.fill,
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 80.0, vertical: 8),
                                        child: Container(
                                          color: Colors.white.withAlpha(220),
                                          width: double.infinity,
                                          height: double.infinity,
                                          child: Center(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                      "Runde: ${snapshot.data!.currentRoundId + 1}",
                                                      style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 32,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  Text(
                                                      "Insgesamt: ${snapshot.data!.totalRounds}",
                                                      style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 32,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  const SizedBox(
                                                    height: 32,
                                                  ),
                                                  Text(
                                                    "Spiel läuft seit ${DateTime.now().difference(snapshot.data!.startTime!).inMinutes} Minuten",
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 32,
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              )),
                        ),
                      ),
                    ),
                  ),
                  Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        height: 80,
                        child: Container(
                          color: Colors.black.withAlpha(40),
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 32.0, right: 32.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: StreamBuilder(
                                    stream: Stream.periodic(
                                        const Duration(seconds: 1)),
                                    builder: (context, snapshot) {
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          const Icon(Icons.schedule),
                                          const SizedBox(
                                            width: 8,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4.0),
                                            child: Text(
                                              DateFormat('HH:mm:ss')
                                                  .format(DateTime.now()),
                                              style:
                                                  const TextStyle(fontSize: 30),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildTimer(snapshot.data!),
                      const SizedBox(
                        height: 100,
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              snapshot.data!.isPauseRound
                                  ? const Column(
                                      children: [
                                        Text(
                                          "Pausenrunde",
                                          style: TextStyle(
                                              fontSize: 48,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          " ",
                                          style: TextStyle(
                                              fontSize: 48,
                                              fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        const Text("Small Blind | Big Blind",
                                            style: TextStyle(
                                                fontSize: 30,
                                                fontWeight: FontWeight.w300)),
                                        Text(
                                          "${snapshot.data!.currentSmallBlind} | ${snapshot.data!.currentBigBlind}",
                                          style: const TextStyle(
                                              fontSize: 100,
                                              fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    ),
                              const SizedBox(
                                height: 32,
                              ),
                              const Text("Nächste Runde",
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w300)),
                              snapshot.data!.nextIsPauseRound
                                  ? const Text(
                                      "Pausenrunde",
                                      style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.normal),
                                    )
                                  : Text(
                                      "${snapshot.data!.nextSmallBlind} | ${snapshot.data!.nextBigBlind}",
                                      style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.normal),
                                    )
                            ]),
                      )
                    ],
                  )
                ]);
              }
              return Center(
                child: SizedBox(
                  height: 128,
                  child: Lottie.asset('assets/cards.json',
                      frameRate: FrameRate(30.0),
                      filterQuality: FilterQuality.medium,
                      reverse: true),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildTimer(GameState gameState) {
    int remainingSeconds = gameState.currentRoundDurationSeconds -
        gameState.elapsedSecondsThisRound;
    Duration remainingDuration = Duration(seconds: remainingSeconds);

    String formattedTime = remainingDuration
        .toString()
        .split('.')
        .first
        .padLeft(8, "0")
        .substring(3);
    return Align(
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: CircularPercentIndicator(
          radius: 175.0,
          lineWidth: 20.0,
          reverse: true,
          addAutomaticKeepAlive: true,
          animation: true,
          animationDuration: 950,
          animateFromLastPercent: true,
          percent: (gameState.currentRoundDurationSeconds -
                  gameState.elapsedSecondsThisRound) /
              gameState.currentRoundDurationSeconds,
          center: Text(
            formattedTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 80,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  // Bottom-left shadow
                  color: Color.fromARGB(255, 83, 83, 83),
                  offset: Offset(-0.5, -0.5),
                  blurRadius: 8,
                ),
                Shadow(
                  // Bottom-right shadow
                  color: Color.fromARGB(255, 83, 83, 83),
                  offset: Offset(-0.5, -0.5), blurRadius: 8,
                ),
                Shadow(
                  // Top-right shadow
                  color: Color.fromARGB(255, 83, 83, 83),
                  offset: Offset(-0.5, -0.5), blurRadius: 8,
                ),
                Shadow(
                  color: Color.fromARGB(255, 83, 83, 83),
                  offset: Offset(-0.5, -0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: Color.fromARGB(
              255,
              gameState.currentAccentcolor.red,
              gameState.currentAccentcolor.green,
              gameState.currentAccentcolor.blue),
          backgroundColor: Color.fromARGB(
              30,
              gameState.currentAccentcolor.red,
              gameState.currentAccentcolor.green,
              gameState.currentAccentcolor.blue),
        ),
      ),
    );
  }
}
