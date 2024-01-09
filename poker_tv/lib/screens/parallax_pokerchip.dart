import 'dart:math';
import 'package:flutter/material.dart';

class ParallaxPokerChips extends StatefulWidget {
  const ParallaxPokerChips({super.key});

  @override
  _ParallaxPokerChipsState createState() => _ParallaxPokerChipsState();
}

class _ParallaxPokerChipsState extends State<ParallaxPokerChips>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final int _numberOfChips = 30;
  late List<Widget> _chips;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Now it's safe to use MediaQuery.of(context)
    _chips = List.generate(_numberOfChips, (index) {
      double size = _random.nextDouble() * 50 + 80;
      int durationInSeconds = _random.nextInt(15) + 10;
      double topPosition =
          _random.nextDouble() * MediaQuery.of(context).size.height;

      return AnimatedPokerChip(
        controller: _controller,
        chipSize: size,
        durationInSeconds: durationInSeconds,
        topPosition: topPosition,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: _chips);
  }
}

class AnimatedPokerChip extends StatelessWidget {
  final AnimationController controller;
  final double chipSize;
  final int durationInSeconds;
  final double topPosition;

  const AnimatedPokerChip({
    super.key,
    required this.controller,
    required this.chipSize,
    required this.durationInSeconds,
    required this.topPosition,
  });

  @override
  Widget build(BuildContext context) {
    double start = Random().nextDouble();
    double end = start + Random().nextDouble() - 0.5;

    Animation<double> animation = Tween(begin: start, end: end).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(
          0.0,
          1.0,
          curve: Curves.linear,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        double leftPosition =
            MediaQuery.of(context).size.width * animation.value;
        return Positioned(
          left: leftPosition,
          top: topPosition, // fixed position
          child: Opacity(
            opacity: .03,
            child: Image.asset(
              'assets/pokerchip.png',
              width: chipSize,
              height: chipSize,
            ),
          ),
        );
      },
    );
  }
}
