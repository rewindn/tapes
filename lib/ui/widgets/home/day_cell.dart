import 'package:flutter/material.dart';
import 'package:tapes/constants/app_colors.dart';

class WeekDayHeaders extends StatelessWidget {
  final Color textColor;

  const WeekDayHeaders({super.key, required this.textColor});

  static const List<String> _days = [
    'Minggu',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _days.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class DateCell extends StatelessWidget {
  final DateTime date;
  final Set<DateTime> noteDates;

  const DateCell({super.key, required this.date, required this.noteDates});

  @override
  Widget build(BuildContext context) {
    final hasNote = noteDates.contains(
      DateTime(date.year, date.month, date.day),
    );
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    Color? bgColor;
    Color textColor = const Color(0xFFB0B0B0);

    if (hasNote) {
      bgColor = AppColors.accentGreen;
      textColor = Colors.white;
    } else if (isToday) {
      bgColor = const Color(0xFFFFBF00);
      textColor = Colors.white;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        date.day.toString(),
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: (hasNote || isToday) ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }
}
