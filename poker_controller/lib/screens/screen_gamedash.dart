import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:poker_at_juergen/custom_scaffold.dart';
import 'package:poker_at_juergen/models/model_wsmessage.dart';
import 'package:poker_at_juergen/screens/screen_gameconfig.dart';
import 'package:poker_at_juergen/screens/screen_settings.dart';
import 'package:poker_at_juergen/screens/screen_update.dart';
import '../models/model_gamestate.dart';
import '../network_manager.dart';
import '../websocket_service.dart';

class GameDashboard extends StatefulWidget {
  const GameDashboard({super.key});

  @override
  State<GameDashboard> createState() => _GameDashboardState();
}

class _GameDashboardState extends State<GameDashboard>
    with WidgetsBindingObserver {
  late Future<GameState?> gameStateFuture;
  // ignore: unused_field
  late StreamSubscription<WSMessage> _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    gameStateFuture = NetworkManager().getGameState();
    final webSocketService = WebSocketService();
    _subscription = webSocketService.messages.listen((message) {
      if (mounted) {
        refreshData();
        try {
          switch (message.event) {
            case 'system_updating':
              Navigator.pushAndRemoveUntil<bool>(
                context,
                MaterialPageRoute(builder: (context) => const UpdateScreen()),
                (route) => false,
              );
              break;
            case 'game_started':
              //_countDownController.restart();
              break;
            case 'game_stopped':
            case 'round_changed':
              //_countDownController.restart();
              break;
            case 'game_paused':
            //_countDownController.pause();
            case 'game_resumed':
            //_countDownController.resume();
            case 'sync':
              break;
          }
        } catch (e) {
          print(e);
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        refreshData();
        setState(() {});
      }
    }
  }

  void refreshData() {
    setState(() {
      gameStateFuture = NetworkManager().getGameState();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      FutureBuilder<GameState?>(
        future: gameStateFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return buildDashboard(snapshot.data);
          } else {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Keine Daten, aktualisiere mithilfe des Buttons'),
            ));
          }
        },
      ),
      LinearGradient(
          colors: [Colors.transparent, Colors.black.withAlpha(150)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter),
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshData,
          ),
          IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                ).then((value) => refreshData());
              }),
        ],
      ),
    );
  }

  Widget buildDashboard(GameState? gameState) {
    if (gameState == null) {
      return const Center(
          child: Text(
        'Kein Spielstatus vorhanden',
        style: TextStyle(fontWeight: FontWeight.normal),
      ));
    }

    if (gameState.gameRunning) {
      return gameRunningDash(gameState);
    }
    return gameInactiveDash(gameState);
  }

  Widget gameRunningDash(GameState gameState) {
    int remainingSeconds = gameState.currentRoundDurationSeconds -
        gameState.elapsedSecondsThisRound;
    Duration remainingDuration = Duration(seconds: remainingSeconds);

    String formattedTime = remainingDuration
        .toString()
        .split('.')
        .first
        .padLeft(8, "0")
        .substring(3);

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          gameState.paused
              ? const Text("Zeit pausiert",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
              : const Text("Zeit läuft",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(
            height: 8,
          ),
          const Divider(),
          const SizedBox(
            height: 4,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Runde:",
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  (gameState.currentRoundId + 1).toString(),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Insgesamt:",
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  (gameState.totalRounds + 1).toString(),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Startzeit:",
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  "Vor ${DateTime.now().difference(gameState.startTime!).inMinutes} Minuten",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          const Divider(),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 1,
            children: [
              IconButton(
                icon: gameState.paused
                    ? const Icon(Icons.play_arrow_outlined,
                        size: 50, color: Colors.amber)
                    : const Icon(Icons.pause_outlined,
                        size: 50, color: Colors.amber),
                onPressed: () async {
                  await NetworkManager().pauseResumeGame();
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop, size: 50, color: Colors.amber),
                onPressed: () async {
                  bool confirm = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Bitte bestätigen'),
                            content: const Text(
                                'Bist du sicher, dass du das Spiel beenden möchtest?'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Abbrechen'),
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                              ),
                              TextButton(
                                child: const Text('Bestätigen'),
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                              ),
                            ],
                          );
                        },
                      ) ??
                      false;

                  if (confirm) {
                    await NetworkManager().stopGame();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous_outlined,
                    size: 50, color: Colors.amber),
                onPressed: () async {
                  bool confirm = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Bitte bestätigen'),
                            content: const Text(
                                'Bist du sicher, dass du zur letzten Runde zurückkehren möchtest?'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Abbrechen'),
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                              ),
                              TextButton(
                                child: const Text('Bestätigen'),
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                              ),
                            ],
                          );
                        },
                      ) ??
                      false;

                  if (confirm) {
                    await NetworkManager().prevRound();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_outlined,
                    size: 50, color: Colors.amber),
                onPressed: () async {
                  bool confirm = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Bitte bestätigen'),
                            content: const Text(
                                'Bist du sicher, dass du diese Runde überspringen möchtest?'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Abbrechen'),
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                              ),
                              TextButton(
                                child: const Text('Bestätigen'),
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                              ),
                            ],
                          );
                        },
                      ) ??
                      false;

                  if (confirm) {
                    await NetworkManager().skipRound();
                  }
                },
              ),
            ],
          ),
          const SizedBox(
            height: 32,
          ),
          CircularPercentIndicator(
            radius: 120.0,
            lineWidth: 13.0,
            reverse: true,
            addAutomaticKeepAlive: true,
            animation: true,
            animateFromLastPercent: true,
            percent: (gameState.currentRoundDurationSeconds -
                    gameState.elapsedSecondsThisRound) /
                gameState.currentRoundDurationSeconds,
            center: Text(
              formattedTime,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 34.0),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: Colors.amber,
            backgroundColor: Colors.amber.withAlpha(30),
          ),
          const SizedBox(
            height: 64,
          ),
          gameState.isPauseRound
              ? const Text(
                  "Pausenrunde",
                  style: TextStyle(fontSize: 24),
                )
              : Column(
                  children: [
                    const Text(
                      "Blinds",
                      style: TextStyle(fontSize: 24),
                    ),
                    Text(
                      "${gameState.currentSmallBlind} / ${gameState.currentBigBlind}",
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
          gameState.nextIsPauseRound
              ? const Text("Nächste Runde Pause")
              : Column(
                  children: [
                    Text(
                      "Nächste Runde",
                      style: TextStyle(
                          fontSize: 16, color: Colors.white.withAlpha(100)),
                    ),
                    Text(
                      "${gameState.nextSmallBlind} / ${gameState.nextBigBlind}",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.white.withAlpha(100)),
                    )
                  ],
                )
        ],
      ),
    );
  }

  Widget gameInactiveDash(GameState gameState) {
    return Stack(children: [
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Poker @ Jürgen's",
              style: GoogleFonts.courgette().copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                shadows: [
                  const Shadow(
                    color: Color.fromARGB(255, 255, 230, 120),
                    offset: Offset(-0.5, -0.5),
                    blurRadius: 16,
                  ),
                  const Shadow(
                    color: Color.fromARGB(255, 83, 83, 83),
                    offset: Offset(-0.5, -0.5),
                    blurRadius: 16,
                  ),
                  const Shadow(
                    color: Color.fromARGB(255, 83, 83, 83),
                    offset: Offset(-0.5, -0.5),
                    blurRadius: 16,
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
              height: 48,
            ),
            Text(
              "Kein Spiel aktiv",
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto()
                  .copyWith(fontSize: 24, fontWeight: FontWeight.normal),
            ),
            const SizedBox(
              height: 8,
            ),
            SizedBox(
                width: 250,
                child: ElevatedButton(
                    onPressed: () async {
                      var result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const GamesConfigScreen()),
                      );
                      if (result != null && result) {
                        refreshData();
                      }
                    },
                    child: const Text("Starten",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.normal)))),
            const SizedBox(
              height: 128,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Das System auf dem TV wird automatisch nach 10 Minuten Inaktivität in den Standby-Modus gesetzt.",
                style: TextStyle(
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              '\nso far\n- jeff',
              style: GoogleFonts.shadowsIntoLight(),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Server verbunden",
                  style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .color!
                          .withAlpha(150))),
              const SizedBox(
                width: 8,
              ),
              SizedBox(
                width: 16,
                height: 16,
                child: LoadingIndicator(
                  indicatorType: Indicator.orbit,
                  colors: [Colors.green.withAlpha(150)],
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}
