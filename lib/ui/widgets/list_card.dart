import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapes/constants/app_colors.dart';
import 'package:tapes/ui/theme/app_theme.dart';

class ListCard extends StatelessWidget {
  final DateTime date;
  final String? databaseName;
  final String? focus;
  final VoidCallback? onTap;

  const ListCard({
    super.key,
    required this.date,
    this.databaseName,
    this.focus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final focusText = focus?.trim();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.tapeCharcoalDark,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tapeInset,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM d, yyyy').format(date),
                      style: const TextStyle(
                        fontFamily: AppTheme.headingFont,
                        color: AppColors.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tapeCharcoalDark,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            (databaseName ?? 'Tapes').trim(),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (focusText != null && focusText.isNotEmpty)
                          Text(
                            focusText,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const Text(
                          '✓ Recorded',
                          style: TextStyle(
                            color: AppColors.actionOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.tapeWindow,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.tapeWindowBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _spoolWheel(),
                    Expanded(
                      child: Container(
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.tapeFilm,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Container(
                            width: double.infinity,
                            height: 1,
                            color: AppColors.tapeGold.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                    _spoolWheel(),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 36,
              child: Center(
                child: ClipPath(
                  clipper: _ChinClipper(),
                  child: SizedBox(
                    width: 120,
                    height: 28,
                    child: ColoredBox(color: AppColors.tapeCharcoalLight),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spoolWheel() {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: AppColors.tapeSpool,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.tapeWindow.withValues(alpha: 0.6),
            ),
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.tapeWindow,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChinClipper extends CustomClipper<Path> {
  const _ChinClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo((size.width - 80) / 2, 0)
      ..lineTo((size.width + 80) / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
