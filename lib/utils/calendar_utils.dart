abstract final class CalendarUtils {
  static bool hasNoteOnDate(Set<DateTime> noteDates, DateTime date) {
    return noteDates.contains(DateTime(date.year, date.month, date.day));
  }

  static int calculateProgress(
    Set<DateTime> noteDates,
    DateTime currentMonth, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final daysToCount =
        currentMonth.month == current.month && currentMonth.year == current.year
            ? current.day
            : DateTime(currentMonth.year, currentMonth.month + 1, 0).day;

    int notesThisMonth = 0;
    for (int day = 1; day <= daysToCount; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      if (hasNoteOnDate(noteDates, date)) notesThisMonth++;
    }

    return daysToCount > 0 ? ((notesThisMonth / daysToCount) * 100).round() : 0;
  }

  static List<DateTime> getWeekDates([DateTime? now]) {
    final current = now ?? DateTime.now();
    final weekStart = current.subtract(Duration(days: current.weekday % 7));
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  static List<DateTime> getMonthDates(DateTime currentMonth) {
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final startDate = firstDay.subtract(Duration(days: startWeekday));
    final totalCells = ((startWeekday + lastDay.day) / 7).ceil() * 7;
    return List.generate(totalCells, (i) => startDate.add(Duration(days: i)));
  }
}
