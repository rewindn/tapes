import 'package:flutter_test/flutter_test.dart';
import 'package:tapes/utils/calendar_utils.dart';

void main() {
  group('CalendarUtils.hasNoteOnDate', () {
    test('returns true when the date is in the set', () {
      final noteDates = {DateTime(2026, 11, 7)};
      expect(
        CalendarUtils.hasNoteOnDate(noteDates, DateTime(2026, 11, 7, 15, 30)),
        isTrue,
      );
    });

    test('returns false when the date is not in the set', () {
      final noteDates = {DateTime(2026, 11, 7)};
      expect(CalendarUtils.hasNoteOnDate(noteDates, DateTime(2026, 11, 8)), isFalse);
    });
  });

  group('CalendarUtils.calculateProgress', () {
    test('current month counts days up to now.day', () {
      final now = DateTime(2026, 11, 10);
      final currentMonth = DateTime(2026, 11, 1);
      final noteDates = {
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 3),
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 5),
      };

      expect(CalendarUtils.calculateProgress(noteDates, currentMonth, now: now), 50);
    });

    test('past month counts every day of the month', () {
      final now = DateTime(2026, 11, 10);
      final currentMonth = DateTime(2026, 10, 1); // 31 days
      final noteDates = {
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 2),
        DateTime(2026, 10, 3),
      };

      expect(CalendarUtils.calculateProgress(noteDates, currentMonth, now: now), 10);
    });

    test('returns 0 when there are no notes', () {
      final now = DateTime(2026, 11, 10);

      expect(
        CalendarUtils.calculateProgress(<DateTime>{}, DateTime(2026, 11, 1), now: now),
        0,
      );
    });

    test('returns 100 when every counted day has a note', () {
      final now = DateTime(2026, 11, 5);
      final currentMonth = DateTime(2026, 11, 1);
      final noteDates = {
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 3),
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 5),
      };

      expect(CalendarUtils.calculateProgress(noteDates, currentMonth, now: now), 100);
    });
  });

  group('CalendarUtils.getWeekDates', () {
    test('returns 7 consecutive days starting on Sunday', () {
      final dates = CalendarUtils.getWeekDates(DateTime(2026, 11, 7));

      expect(dates.length, 7);
      expect(dates.first.weekday, DateTime.sunday);
      for (var i = 1; i < dates.length; i++) {
        expect(dates[i].difference(dates[i - 1]).inDays, 1);
      }
    });
  });

  group('CalendarUtils.getMonthDates', () {
    test('grid cell count is always a multiple of 7', () {
      final months = [
        DateTime(2026, 2, 1),
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 15),
      ];

      for (final month in months) {
        final dates = CalendarUtils.getMonthDates(month);

        expect(dates.length % 7, 0);
        expect(dates.first.weekday, DateTime.sunday);
        expect(
          dates.any(
            (date) =>
                date.year == month.year &&
                date.month == month.month &&
                date.day == 1,
          ),
          isTrue,
        );
      }
    });
  });
}
