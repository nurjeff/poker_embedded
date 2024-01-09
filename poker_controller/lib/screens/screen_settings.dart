import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:poker_at_juergen/network_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Einstellungen"),
      ),
      body: FutureBuilder(
          future: NetworkManager().getGamesConfigSettings(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Akzentfarbe",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.normal)),
                      ColorPicker(
                        onColorChangeEnd: (c) async {
                          await NetworkManager().changeAccentColor(c);
                        },
                        pickersEnabled: const <ColorPickerType, bool>{
                          ColorPickerType.both: false,
                          ColorPickerType.accent: false,
                          ColorPickerType.primary: false,
                          ColorPickerType.wheel: true
                        },
                        onColorChanged: (Color value) {},
                        color: Color.fromARGB(
                            255,
                            snapshot.data!.accentColor.red,
                            snapshot.data!.accentColor.green,
                            snapshot.data!.accentColor.blue),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Musik abspielen"),
                          Switch(
                              value: snapshot.data!.playMusic,
                              onChanged: (val) async {
                                NetworkManager().toggleMusic().then((value) {
                                  setState(() {});
                                });
                              }),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Ansagen abspielen"),
                          Switch(
                              value: snapshot.data!.playSounds,
                              onChanged: (val) async {
                                NetworkManager().toggleSounds().then((value) {
                                  setState(() {});
                                });
                              }),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("LEDs aktivieren"),
                          Switch(
                              value: snapshot.data!.enableLeds,
                              onChanged: (val) async {
                                NetworkManager().toggleLeds().then((value) {
                                  setState(() {});
                                });
                              }),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          bool confirm = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Bitte bestätigen'),
                                    content: const Text(
                                        'Bist du sicher, dass du das Gerät ausschalten möchtest? Es muss dann am Gerät selbst erneut angeschaltet werden.'),
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
                            await NetworkManager().shutdown();
                          }
                        },
                        child: const Text("Ausschalten"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          bool confirm = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Bitte bestätigen'),
                                    content: const Text(
                                        'Bist du sicher, dass du das Gerät neustarten möchtest? Dies kann einen Moment dauern.'),
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
                            await NetworkManager().reboot();
                          }
                        },
                        child: const Text("Neustarten"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          bool confirm = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Bitte bestätigen'),
                                    content: const Text(
                                        'Bist du sicher, dass du das Gerät aktualisieren möchtest? Bitte tue dies nur wenn es ein tatsächliches Problem gibt. Dies kann bis zu 5 Minuten dauern.'),
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
                            await NetworkManager().updateSystem();
                          }
                        },
                        child: const Text("Systemaktualisierung"),
                      ),
                    ]),
              );
            }
            return const LoadingIndicator(
                indicatorType: Indicator.audioEqualizer);
          }),
    );
  }
}
