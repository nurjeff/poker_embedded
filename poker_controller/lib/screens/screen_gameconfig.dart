import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:poker_at_juergen/models/model_gamelist.dart';
import 'package:poker_at_juergen/network_manager.dart';
import 'package:poker_at_juergen/screens/screen_editconfig.dart';

import '../models/model_game.dart';
import '../models/model_gameentry.dart';

class GamesConfigScreen extends StatefulWidget {
  const GamesConfigScreen({super.key});

  @override
  State<GamesConfigScreen> createState() => _GamesConfigScreenState();
}

class _GamesConfigScreenState extends State<GamesConfigScreen> {
  late Future<GamesList?> gamesListFuture;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  var isDialOpen = ValueNotifier<bool>(false);

  GamesList? currentGamesList;

  @override
  void initState() {
    super.initState();
    gamesListFuture = NetworkManager().getGamesConfig();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
              onPressed: () {
                NetworkManager().startGame(_currentPage).then((value) {
                  if (value != null) {
                    Navigator.pop(context, true);
                  }
                });
              },
              backgroundColor: Colors.green,
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              child: const Icon(Icons.check)),
          const SizedBox(width: 12),
          SpeedDial(
            childrenButtonSize: const Size(64.0, 64.0),
            elevation: 8,
            spaceBetweenChildren: 6,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.add),
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                foregroundColor: Colors.white,
                label: 'Hinzufügen',
                onTap: () async {
                  Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EditConfigScreen(
                              existingGame: null,
                              currentIndex: _currentPage,
                            )),
                  ).then((value) {
                    _currentPage = 0;
                    gamesListFuture = NetworkManager().getGamesConfig();
                    setState(() {});
                  });
                },
              ),
              SpeedDialChild(
                child: const Icon(Icons.edit),
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                foregroundColor: Colors.white,
                label: 'Bearbeiten',
                onTap: () {
                  if (currentGamesList != null) {
                    if (!currentGamesList!.games[_currentPage].canBeDeleted) {
                      showDialog<String>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Text('Nicht möglich'),
                          content: const Text(
                              'Standardkonfigurationen können nicht editiert werden. \n\nDu kannst stattdessen eigene Konfigurationen erstellen und nach belieben bearbeiten.'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'Cancel'),
                              child: const Text('Okay'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditConfigScreen(
                                  existingGame:
                                      currentGamesList!.games[_currentPage],
                                  currentIndex: _currentPage,
                                )),
                      ).then((value) {
                        _currentPage = 0;
                        gamesListFuture = NetworkManager().getGamesConfig();
                        setState(() {});
                      });
                    }
                  }
                },
              ),
              SpeedDialChild(
                child: const Icon(Icons.delete),
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                foregroundColor: Colors.white,
                label: 'Löschen',
                onTap: () {
                  if (currentGamesList != null) {
                    if (!currentGamesList!.games[_currentPage].canBeDeleted) {
                      showDialog<String>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Text('Nicht möglich'),
                          content: const Text(
                              'Standardkonfigurationen können nicht gelöscht werden. \n\nDu kannst stattdessen eigene Konfigurationen erstellen und nach belieben bearbeiten.'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'Cancel'),
                              child: const Text('Okay'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      NetworkManager()
                          .deleteGameConfig(_currentPage)
                          .then((value) {
                        _currentPage = 0;
                        gamesListFuture = NetworkManager().getGamesConfig();
                        setState(() {});
                      });
                    }
                  }
                },
              ),
            ],
            openCloseDial: isDialOpen,
            animatedIcon: AnimatedIcons.menu_close,
          ),
        ],
      ),
      appBar: AppBar(),
      body: FutureBuilder<GamesList?>(
        future: gamesListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            currentGamesList = null;
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            currentGamesList = null;
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data != null) {
            currentGamesList = snapshot.data!;
            return Column(
              children: [
                const SizedBox(height: 16),
                const Text("Wähle eine Spielkonfiguration",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(),
                const SizedBox(height: 8),
                if (snapshot.data!.games.isNotEmpty)
                  buildPageIndicator(snapshot.data!.games.length, _currentPage),
                Expanded(child: buildGamesList(snapshot.data!)),
              ],
            );
          } else {
            return const Center(child: Text('No games available'));
          }
        },
      ),
    );
  }

  Widget buildGamesList(GamesList gamesList) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      scrollDirection: Axis.horizontal,
      itemCount: gamesList.games.length,
      itemBuilder: (context, index) {
        return buildGamePage(gamesList.games[index]);
      },
    );
  }

  Widget buildGamePage(Game game) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(game.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              game.canBeDeleted
                  ? Container()
                  : Icon(
                      Icons.security,
                      color: Colors.white.withAlpha(100),
                    )
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: game.gameEntries.length,
              itemBuilder: (context, index) {
                return buildGameEntry(game.gameEntries[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGameEntry(GameEntry entry) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Card(
        child: ListTile(
            title: Text(entry.isPause ? 'Pause' : 'Runde'),
            subtitle: entry.isPause
                ? const Text('Blinds: - / -',
                    style: TextStyle(fontWeight: FontWeight.bold))
                : Text('Blinds: ${entry.smallBlind} / ${entry.bigBlind}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text('${entry.durationMinutes} Minuten')),
      ),
    );
  }

  Widget buildPageIndicator(int pageCount, int currentPage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: 8.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentPage == index ? Colors.orange : Colors.grey,
          ),
        );
      }),
    );
  }
}
