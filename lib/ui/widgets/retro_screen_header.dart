import 'package:flutter/material.dart';
import 'package:tapes/constants/app_colors.dart';
import 'package:tapes/ui/theme/app_theme.dart';

class RetroScreenHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const RetroScreenHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 64.0,
        bottom: 32.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: AppTheme.headingFont,
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
