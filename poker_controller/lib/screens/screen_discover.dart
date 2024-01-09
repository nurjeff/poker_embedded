import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poker_at_juergen/custom_scaffold.dart';
import 'package:poker_at_juergen/misc/preIndicator.dart';
import 'package:poker_at_juergen/network_manager.dart';
import 'package:poker_at_juergen/resolver.dart';
import 'package:poker_at_juergen/screens/screen_gamedash.dart';

import '../websocket_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with WidgetsBindingObserver {
  Resolver? resolver = Resolver();
  Future<bool>? resolverFuture;
  int _searchKey = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    startSearch();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (NetworkManager().host.isNotEmpty) {
        startSearch();
      }
    }
  }

  void startSearch() {
    resolver = null;
    resolver = Resolver();
    _searchKey++;
    setState(() {
      resolverFuture = resolver!.findMulticast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      FutureBuilder(
        key: ValueKey(_searchKey),
        future: resolverFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!) {
              Future.delayed(const Duration(milliseconds: 250), () {
                final webSocketService = WebSocketService();
                // ignore: prefer_interpolation_to_compose_strings
                var wsurl = 'ws://' +
                    NetworkManager().host.replaceAll("http://", "") +
                    "/ws";
                webSocketService.connect(wsurl).then((value) {
                  webSocketService.onConnectionBroken = () {
                    print("websocket connection broke");
                  };
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GameDashboard()),
                    (route) => false,
                  );
                });
              });
            } else {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Kein Server gefunden",
                        style: GoogleFonts.roboto().copyWith(
                            fontSize: 16, fontWeight: FontWeight.normal),
                      ),
                      Text(
                        "Stelle bitte sicher dass sich das Smartphone und der Server im gleichen WLAN Netzwerk befinden und der Server eingeschaltet ist.",
                        style: GoogleFonts.roboto()
                            .copyWith(fontWeight: FontWeight.w300),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: () {
                              startSearch();
                            },
                            child: Text("Erneut versuchen",
                                style: GoogleFonts.roboto().copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal))),
                      )
                    ],
                  ),
                ),
              );
            }
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PreIndicator(),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  "Suche nach Poker Server",
                  style: GoogleFonts.roboto()
                      .copyWith(fontSize: 16, fontWeight: FontWeight.normal),
                )
              ],
            ),
          );
        },
      ),
      LinearGradient(
          colors: [Colors.transparent, Colors.blue.withAlpha(15)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter),
    );
  }
}
