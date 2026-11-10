import 'package:intl/intl.dart';
import 'package:tapes/models/note.dart';
import 'package:tapes/utils/calendar_utils.dart';

class HomeUiState {
  final int progress;
  final List<DateTime> weekDates;
  final List<DateTime> monthDates;
  final Set<DateTime> noteDates;
  final DateTime currentMonth;
  final DateTime now;
  final String dayName;
  final String monthName;
  final String yearString;

  const HomeUiState({
    required this.progress,
    required this.weekDates,
    required this.monthDates,
    required this.noteDates,
    required this.currentMonth,
    required this.now,
    required this.dayName,
    required this.monthName,
    required this.yearString,
  });

  factory HomeUiState.fromNotes(List<Note> notes, {DateTime? clock}) {
    final effectiveNow = clock ?? DateTime.now();
    final currentMonth = DateTime(effectiveNow.year, effectiveNow.month, 1);
    final noteDates = notes
        .map(
          (note) => DateTime(
            note.createdAt.year,
            note.createdAt.month,
            note.createdAt.day,
          ),
        )
        .toSet();

    return HomeUiState(
      progress: CalendarUtils.calculateProgress(
        noteDates,
        currentMonth,
        now: effectiveNow,
      ),
      weekDates: CalendarUtils.getWeekDates(effectiveNow),
      monthDates: CalendarUtils.getMonthDates(currentMonth),
      noteDates: noteDates,
      currentMonth: currentMonth,
      now: effectiveNow,
      dayName: DateFormat.EEEE().format(effectiveNow),
      monthName: DateFormat.MMMM('id').format(currentMonth),
      yearString: currentMonth.year.toString(),
    );
  }
}
