import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

class PreIndicator extends StatelessWidget {
  final int sizeMod;
  const PreIndicator({super.key, this.sizeMod = 2});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / sizeMod,
      child: const LoadingIndicator(
          indicatorType: Indicator.orbit, colors: [Colors.amber]),
    );
  }
}
