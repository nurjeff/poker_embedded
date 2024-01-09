import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
          child: SizedBox(
        height: 64,
        width: 64,
        child: LoadingIndicator(indicatorType: Indicator.circleStrokeSpin),
      )),
    );
  }
}
