import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tapes/models/home_ui_state.dart';
import 'package:tapes/models/note.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id');
  });

  test('maps notes and clock into deterministic UI fields', () {
    final clock = DateTime(2026, 11, 10, 14, 30);
    final notes = [
      Note(id: '1', content: 'a', createdAt: DateTime(2026, 11, 1, 9)),
      Note(id: '2', content: 'b', createdAt: DateTime(2026, 11, 2, 9)),
      Note(id: '3', content: 'c', createdAt: DateTime(2026, 11, 3, 9)),
    ];

    final state = HomeUiState.fromNotes(notes, clock: clock);

    expect(state.now, clock);
    expect(state.currentMonth, DateTime(2026, 11, 1));
    expect(state.dayName, 'Tuesday');
    expect(state.monthName, 'November');
    expect(state.yearString, '2026');
    expect(state.progress, 30);
    expect(state.noteDates.length, 3);
    expect(state.noteDates, contains(DateTime(2026, 11, 1)));
    expect(state.weekDates, hasLength(7));
    expect(state.weekDates.first, DateTime(2026, 11, 8, 14, 30));
    expect(state.monthDates, hasLength(35));
    expect(state.monthDates.first, DateTime(2026, 11, 1));
  });

  test('empty notes produce zero progress', () {
    final state = HomeUiState.fromNotes(
      <Note>[],
      clock: DateTime(2026, 11, 10),
    );

    expect(state.progress, 0);
    expect(state.noteDates, isEmpty);
  });
}
