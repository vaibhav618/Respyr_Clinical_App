import 'package:flutter/material.dart';
import 'package:respyr_clinical/shared/colors.dart';

class AnimatedProgressBar extends StatefulWidget {
  final bool triggerProgress;

  const AnimatedProgressBar({super.key, required this.triggerProgress});

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 180), // 3 minutes
    );

    _progress = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerProgress && !_controller.isAnimating) {
      _controller.forward(from: 0.0);
    }
  }



  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: _progress.value,
      valueColor: AlwaysStoppedAnimation<Color>(AppColor.primaryBlueColor),
      backgroundColor: const Color(0xFFF3F3F3),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
