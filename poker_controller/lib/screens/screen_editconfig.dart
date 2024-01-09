import 'package:flutter/material.dart';
import 'package:poker_at_juergen/network_manager.dart';

import '../models/model_game.dart';
import '../models/model_gameentry.dart';

class EditConfigScreen extends StatefulWidget {
  final Game? existingGame;
  final int currentIndex;

  const EditConfigScreen(
      {super.key, required this.existingGame, required this.currentIndex});

  @override
  State<EditConfigScreen> createState() => _EditConfigScreenState();
}

class _EditConfigScreenState extends State<EditConfigScreen> {
  late Game gameCopy;
  final _formKey = GlobalKey<FormState>();
  bool isPause = false;
  int durationMinutes = 0;
  int smallBlind = 0;
  int bigBlind = 0;

  @override
  void initState() {
    if (widget.existingGame == null) {
      gameCopy = Game(name: "", canBeDeleted: true, gameEntries: []);
    } else {
      gameCopy = widget.existingGame!;
    }
    super.initState();
  }

  // Function to prompt for game config name
  Future<String?> _promptGameConfigName(BuildContext context) async {
    TextEditingController nameController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gib einen Namen ein'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Name'),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Bestätigen'),
              onPressed: () {
                Navigator.of(context).pop(nameController.text);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          gameCopy.gameEntries.length >= 3
              ? FloatingActionButton(
                  onPressed: () async {
                    if (gameCopy.gameEntries.isNotEmpty) {
                      if (widget.existingGame != null) {
                        await NetworkManager()
                            .updateGameConfig(widget.currentIndex, gameCopy)
                            .then(
                          (success) {
                            if (success) {
                              Navigator.pop(context);
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) => const AlertDialog(
                                  title: Text("Fehler"),
                                  content: Text("Das hat nicht funktioniert."),
                                ),
                              );
                            }
                          },
                        );
                      } else {
                        String? newName = await _promptGameConfigName(context);
                        if (newName != null && newName.isNotEmpty) {
                          gameCopy.name = newName;
                          await NetworkManager()
                              .createGameConfig(gameCopy)
                              .then(
                            (success) {
                              if (success) {
                                Navigator.pop(context);
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => const AlertDialog(
                                    title: Text("Fehler"),
                                    content:
                                        Text("Das hat nicht funktioniert."),
                                  ),
                                );
                              }
                            },
                          );
                        }
                      }
                    }
                  },
                  backgroundColor: Colors.green,
                  heroTag: "saveGameConfigButton",
                  child: const Icon(Icons.save),
                )
              : const SizedBox(
                  width: 0,
                  height: 0,
                ),
          const SizedBox(
            width: 16,
          ),
          FloatingActionButton(
            onPressed: () => _showAddGameEntryDialog(context).then((value) {
              setState(() {});
            }),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: buildGamePage(gameCopy),
      appBar: AppBar(
        title: widget.existingGame != null
            ? const Text("Bearbeiten")
            : const Text("Hinzufügen"),
      ),
    );
  }

  Future _showAddGameEntryDialog(BuildContext context,
      {GameEntry? editingEntry}) {
    TextEditingController durationController = TextEditingController(
        text: editingEntry?.durationMinutes.toString() ?? '');
    TextEditingController smallBlindController =
        TextEditingController(text: editingEntry?.smallBlind.toString() ?? '');
    TextEditingController bigBlindController =
        TextEditingController(text: editingEntry?.bigBlind.toString() ?? '');

    bool tempIsPause = editingEntry?.isPause ?? false;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Neuer Eintrag'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Pause'),
                      value: tempIsPause,
                      onChanged: (bool value) {
                        setState(() {
                          tempIsPause = value;
                        });
                      },
                    ),
                    TextFormField(
                      controller: durationController,
                      decoration:
                          const InputDecoration(labelText: 'Dauer in Minuten'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return 'Bitte gib eine gültige Zahl ein';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        durationMinutes = int.parse(value!);
                      },
                    ),
                    if (!tempIsPause) ...[
                      TextFormField(
                        controller: smallBlindController,
                        decoration:
                            const InputDecoration(labelText: 'Small Blind'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null ||
                              int.tryParse(value) == null ||
                              int.parse(value) <= 0) {
                            return 'Bitte gib eine gültige Zahl ein';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          smallBlind = int.parse(value!);
                        },
                      ),
                      TextFormField(
                        controller: bigBlindController,
                        decoration:
                            const InputDecoration(labelText: 'Big Blind'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null ||
                              int.tryParse(value) == null ||
                              int.parse(value) < smallBlind) {
                            return 'Big Blind muss gleich oder größer als Small Blind sein';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          bigBlind = int.parse(value!);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Abbrechen'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Hinzufügen'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      if (editingEntry != null) {
                        gameCopy.gameEntries.remove(editingEntry);
                      }
                      setState(() {
                        gameCopy.gameEntries.add(
                          GameEntry(
                            isPause: tempIsPause,
                            durationMinutes: durationMinutes,
                            smallBlind: tempIsPause ? 0 : smallBlind,
                            bigBlind: tempIsPause ? 0 : bigBlind,
                          ),
                        );
                      });
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildGamePage(Game game) {
    return game.gameEntries.isNotEmpty
        ? Container(
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
                  child: ReorderableListView.builder(
                    itemCount: game.gameEntries.length,
                    itemBuilder: (context, index) {
                      return buildGameEntry(game.gameEntries[index], index);
                    },
                    onReorder: (int oldIndex, int newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final GameEntry item =
                            game.gameEntries.removeAt(oldIndex);
                        game.gameEntries.insert(newIndex, item);
                      });
                    },
                  ),
                ),
              ],
            ),
          )
        : const Center(
            child: Text("Füge neue Einträge hinzu"),
          );
  }

  Widget buildGameEntry(GameEntry entry, int index) {
    return SizedBox(
      key: ValueKey(entry),
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
          trailing: Text('${entry.durationMinutes} Minuten'),
          onTap: () => _handleGameEntryTap(context, entry),
        ),
      ),
    );
  }

  void _handleGameEntryTap(BuildContext context, GameEntry entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eintrag bearbeiten'),
          content:
              const Text('Möchten Sie diesen Eintrag bearbeiten oder löschen?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Bearbeiten'),
              onPressed: () {
                Navigator.of(context).pop();
                _showAddGameEntryDialog(context, editingEntry: entry);
              },
            ),
            TextButton(
              child: const Text('Löschen'),
              onPressed: () {
                setState(() {
                  gameCopy.gameEntries.remove(entry);
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
