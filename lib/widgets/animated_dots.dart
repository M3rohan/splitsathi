import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedDots extends StatelessWidget {
  const AnimatedDots({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) =>
            Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .moveY(
                  begin: 0,
                  end: -8,
                  duration: 450.ms,
                  delay: (index * 180).ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .moveY(
                  begin: -8,
                  end: 0,
                  duration: 450.ms,
                  curve: Curves.easeInOut,
                ),
      ),
    );
  }
}
