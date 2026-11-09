import 'package:flutter_test/flutter_test.dart';
import 'package:tapes/utils/calendar_utils.dart';

void main() {
  group('CalendarUtils.hasNoteOnDate', () {
    test('matches a date regardless of its time components', () {
      final noteDates = {DateTime(2026, 11, 7)};

      expect(
        CalendarUtils.hasNoteOnDate(
          noteDates,
          DateTime(2026, 11, 7, 23, 59, 59),
        ),
        isTrue,
      );
    });

    test('returns false when the date is not in the set', () {
      final noteDates = {DateTime(2026, 11, 7)};

      expect(
        CalendarUtils.hasNoteOnDate(noteDates, DateTime(2026, 11, 8)),
        isFalse,
      );
    });
  });

  group('CalendarUtils.calculateProgress', () {
    test('current month divides by elapsed days, not total days', () {
      final now = DateTime(2026, 11, 10);
      final currentMonth = DateTime(2026, 11, 1);
      final noteDates = {
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 3),
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 5),
      };

      expect(
        CalendarUtils.calculateProgress(noteDates, currentMonth, now: now),
        50,
      );
    });

    test('past month divides by the full 31-day month', () {
      final now = DateTime(2026, 11, 10);
      final currentMonth = DateTime(2026, 10, 1);
      final noteDates = {
        for (var day = 1; day <= 15; day++) DateTime(2026, 10, day),
      };

      // 15/31 = 48.4% -> 48 (a 30-day divisor would give 50)
      expect(
        CalendarUtils.calculateProgress(noteDates, currentMonth, now: now),
        48,
      );
    });

    test('returns 0 when there are no notes', () {
      expect(
        CalendarUtils.calculateProgress(
          <DateTime>{},
          DateTime(2026, 11, 1),
          now: DateTime(2026, 11, 10),
        ),
        0,
      );
    });

    test('leap February uses 29 days', () {
      final now = DateTime(2026, 11, 10);
      final noteDates = {
        for (var day = 1; day <= 28; day++) DateTime(2024, 2, day),
      };

      // 28/29 = 96.6% -> 97 (a 28-day divisor would give 100)
      expect(
        CalendarUtils.calculateProgress(
          noteDates,
          DateTime(2024, 2, 1),
          now: now,
        ),
        97,
      );
    });

    test('non-leap February uses 28 days', () {
      final now = DateTime(2026, 11, 10);
      final noteDates = {
        for (var day = 1; day <= 28; day++) DateTime(2026, 2, day),
      };

      expect(
        CalendarUtils.calculateProgress(
          noteDates,
          DateTime(2026, 2, 1),
          now: now,
        ),
        100,
      );
    });
  });

  group('CalendarUtils.getWeekDates', () {
    test('always returns a Sunday-first 7-day week', () {
      final sampleDays = [
        DateTime(2026, 11, 4), // Wednesday
        DateTime(2026, 11, 5), // Thursday
        DateTime(2026, 11, 7), // Saturday
      ];

      for (final now in sampleDays) {
        final dates = CalendarUtils.getWeekDates(now);

        expect(dates, hasLength(7));
        expect(dates.first.weekday, DateTime.sunday);
        for (var i = 1; i < dates.length; i++) {
          expect(dates[i].difference(dates[i - 1]).inDays, 1);
        }
        expect(
          dates.any(
            (date) =>
                date.year == now.year &&
                date.month == now.month &&
                date.day == now.day,
          ),
          isTrue,
        );
      }
    });
  });

  group('CalendarUtils.getMonthDates', () {
    test('grid length is a multiple of 7 and day 1 keeps its offset', () {
      final months = [
        DateTime(2026, 11, 1), // starts Sunday: 35 cells
        DateTime(2026, 8, 1), // starts Saturday: 42 cells
      ];

      for (final month in months) {
        final dates = CalendarUtils.getMonthDates(month);
        final firstIndex = dates.indexWhere(
          (date) =>
              date.year == month.year &&
              date.month == month.month &&
              date.day == 1,
        );

        expect(dates.length % 7, 0);
        expect(dates.length, anyOf(35, 42));
        expect(dates.first.weekday, DateTime.sunday);
        expect(firstIndex, lessThan(7));
        expect(firstIndex, DateTime(month.year, month.month, 1).weekday % 7);
      }
    });
  });
}
