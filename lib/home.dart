import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tapes/note.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Box notebox;
  late DateTime currentMonth;
  Set<DateTime> noteDates = {};

  @override
  void initState() {
    super.initState();
    notebox = Hive.box('notebox');
    currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _loadNoteDates();
    notebox.listenable().addListener(_onNoteChanged);
  }

  @override
  void dispose() {
    notebox.listenable().removeListener(_onNoteChanged);
    super.dispose();
  }

  void _onNoteChanged() {
    _loadNoteDates();
    setState(() {});
  }

  void _loadNoteDates() {
    final notes = notebox.values
        .map((data) => Note.fromMap(Map<String, dynamic>.from(data)))
        .toList();

    noteDates = notes.map((note) {
      return DateTime(note.createdAt.year, note.createdAt.month, note.createdAt.day);
    }).toSet();
  }

  bool _hasNoteOnDate(DateTime date) {
    return noteDates.contains(DateTime(date.year, date.month, date.day));
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isSameMonth(DateTime date) {
    return date.month == currentMonth.month && date.year == currentMonth.year;
  }

  int _calculateProgress() {
    final now = DateTime.now();
    final daysToCount = currentMonth.month == now.month && currentMonth.year == now.year
        ? now.day
        : DateTime(currentMonth.year, currentMonth.month + 1, 0).day;

    int notesThisMonth = 0;
    for (int day = 1; day <= daysToCount; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      if (_hasNoteOnDate(date)) notesThisMonth++;
    }

    return daysToCount > 0 ? ((notesThisMonth / daysToCount) * 100).round() : 0;
  }

  List<DateTime> _getWeekDates() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  List<DateTime> _getMonthDates() {
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final startDate = firstDay.subtract(Duration(days: startWeekday));
    final totalCells = ((startWeekday + lastDay.day) / 7).ceil() * 7;
    return List.generate(totalCells, (i) => startDate.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final progress = _calculateProgress();
    final weekDates = _getWeekDates();
    final monthDates = _getMonthDates();

    return Container(
      color: const Color(0xFFFFF8E7),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat.EEEE().format(now),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        DateFormat.MMMM().format(currentMonth),
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        currentMonth.year.toString(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8BC34A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            now.day.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress / 100,
                              strokeWidth: 5,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF8BC34A),
                              ),
                            ),
                            Text(
                              '$progress%',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Week Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCC80),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5D5D5D),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          _DayLabel('Minggu'),
                          _DayLabel('Senin'),
                          _DayLabel('Selasa'),
                          _DayLabel('Rabu'),
                          _DayLabel('Kamis'),
                          _DayLabel('Jumat'),
                          _DayLabel('Sabtu'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: weekDates.map((date) {
                          return _WeekDateCell(
                            day: date.day,
                            hasNote: _hasNoteOnDate(date),
                            isToday: _isToday(date),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Month Calendar
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 0,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A889),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D5D5D),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: const [
                                _DayLabel('Minggu'),
                                _DayLabel('Senin'),
                                _DayLabel('Selasa'),
                                _DayLabel('Rabu'),
                                _DayLabel('Kamis'),
                                _DayLabel('Jumat'),
                                _DayLabel('Sabtu'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                                itemCount: monthDates.length,
                                itemBuilder: (context, index) {
                                  final date = monthDates[index];
                                  return _MonthDateCell(
                                    day: date.day,
                                    hasNote: _hasNoteOnDate(date),
                                    isToday: _isToday(date),
                                    isSameMonth: _isSameMonth(date),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String text;
  const _DayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.length > 5 ? text.substring(0, 5) : text,
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 10,
      ),
    );
  }
}

class _WeekDateCell extends StatelessWidget {
  final int day;
  final bool hasNote;
  final bool isToday;

  const _WeekDateCell({
    required this.day,
    required this.hasNote,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color textColor = Colors.black54;

    if (isToday && !hasNote) {
      bgColor = const Color(0xFFFFA726);
      textColor = Colors.white;
    } else if (hasNote) {
      bgColor = const Color(0xFF8BC34A);
      textColor = Colors.white;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          day.toString(),
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MonthDateCell extends StatelessWidget {
  final int day;
  final bool hasNote;
  final bool isToday;
  final bool isSameMonth;

  const _MonthDateCell({
    required this.day,
    required this.hasNote,
    required this.isToday,
    required this.isSameMonth,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSameMonth) return const SizedBox();

    Color? bgColor;
    Color textColor = Colors.white54;

    if (isToday && !hasNote) {
      bgColor = const Color(0xFFFFA726);
      textColor = Colors.white;
    } else if (hasNote) {
      bgColor = const Color(0xFF8BC34A);
      textColor = Colors.white;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          day.toString(),
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: (hasNote || isToday) ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
