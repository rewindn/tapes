import 'package:flutter/material.dart';
import 'package:tapes/widgets/home/day_cell.dart';

class CalendarGrid extends StatelessWidget {
  final List<DateTime> monthDates;
  final DateTime currentMonth;
  final Set<DateTime> noteDates;

  const CalendarGrid({
    super.key,
    required this.monthDates,
    required this.currentMonth,
    required this.noteDates,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF3F3F3F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          const WeekDayHeaders(textColor: Colors.white),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 10,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: monthDates.length,
              itemBuilder: (context, index) {
                final date = monthDates[index];
                if (date.month != currentMonth.month ||
                    date.year != currentMonth.year) {
                  return const SizedBox();
                }
                return Center(
                  child: DateCell(date: date, noteDates: noteDates),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
