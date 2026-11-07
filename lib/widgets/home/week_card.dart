import 'package:flutter/material.dart';
import 'package:tapes/widgets/home/day_cell.dart';

class WeekCard extends StatelessWidget {
  final List<DateTime> weekDates;
  final Set<DateTime> noteDates;

  const WeekCard({super.key, required this.weekDates, required this.noteDates});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 165,
      decoration: const BoxDecoration(
        color: Color(0xFFFFC467),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: WeekDayHeaders(textColor: Colors.white),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3F3F3F),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: weekDates.map((date) {
                return Expanded(
                  child: Center(
                    child: DateCell(date: date, noteDates: noteDates),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
