import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {
  const CustomScaffold(this.body, this.gradient, {super.key, this.appBar});

  final Widget body;
  final LinearGradient gradient;
  final AppBar? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body:
          Container(decoration: BoxDecoration(gradient: gradient), child: body),
    );
  }
}
