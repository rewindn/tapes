import 'package:flutter/material.dart';
import 'package:tapes/constants/app_colors.dart';

class ProgressRing extends StatelessWidget {
  final int progress;

  const ProgressRing({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 90,
          height: 90,
          child: CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: 8,
            color: AppColors.accentGreen,
            backgroundColor: const Color(0xFFE5E5E5),
          ),
        ),
        Text(
          '$progress%',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
