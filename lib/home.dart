import 'dart:math' as math;
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
  dynamic _boxListenable;

  @override
  void initState() {
    super.initState();
    notebox = Hive.box('notebox');
    currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _loadNoteDates();
    _boxListenable = notebox.listenable();
    _boxListenable.addListener(_onNoteChanged);
  }

  @override
  void dispose() {
    _boxListenable?.removeListener(_onNoteChanged);
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
      return DateTime(
        note.createdAt.year,
        note.createdAt.month,
        note.createdAt.day,
      );
    }).toSet();
  }

  bool _hasNoteOnDate(DateTime date) {
    return noteDates.contains(DateTime(date.year, date.month, date.day));
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSameMonth(DateTime date) {
    return date.month == currentMonth.month && date.year == currentMonth.year;
  }

  int _calculateProgress() {
    final now = DateTime.now();
    final daysToCount =
        currentMonth.month == now.month && currentMonth.year == now.year
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
    final dayName = DateFormat.EEEE().format(now);
    final monthName = DateFormat.MMMM('id').format(currentMonth);
    final yearString = currentMonth.year.toString();

    return Container(
      color: const Color(0xFFFFF1DA),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),

            // Header: Day + Badge, Serif Month, Year, and Progress Ring
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3F3F3F),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFBF00),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              now.day.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      IntrinsicWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              monthName,
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontFamilyFallback: ['Times New Roman', 'serif'],
                                fontSize: 48,
                                fontWeight: FontWeight.normal,
                                color: Color(0xFF3F3F3F),
                                height: 1.05,
                              ),
                            ),
                            Text(
                              yearString,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3F3F3F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 104,
                    height: 104,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(104, 104),
                          painter: ProgressRingPainter(
                            progress: progress / 100,
                          ),
                        ),
                        Text(
                          '$progress%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3F3F3F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Layered Week & Month Containers
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Outer Week Card (Orange background)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 165,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC467),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(36),
                        ),
                        boxShadow: const [
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
                            child: _WeekDayHeaders(textColor: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3F3F3F),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: weekDates.map((date) {
                                return Expanded(
                                  child: Center(
                                    child: _DateCell(
                                      day: date.day,
                                      hasNote: _hasNoteOnDate(date),
                                      isToday: _isToday(date),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Month Calendar Card (Dark Charcoal, overlapping Week Card)
                  Positioned(
                    top: 120,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F3F3F),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(36),
                        ),
                        boxShadow: const [
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
                          const _WeekDayHeaders(textColor: Colors.white),
                          const SizedBox(height: 14),
                          Expanded(
                            child: GridView.builder(
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: monthDates.length,
                              itemBuilder: (context, index) {
                                final date = monthDates[index];
                                if (!_isSameMonth(date)) {
                                  return const SizedBox();
                                }
                                return Center(
                                  child: _DateCell(
                                    day: date.day,
                                    hasNote: _hasNoteOnDate(date),
                                    isToday: _isToday(date),
                                  ),
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
          ],
        ),
      ),
    );
  }
}

class _WeekDayHeaders extends StatelessWidget {
  final Color textColor;
  const _WeekDayHeaders({required this.textColor});

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

class _DateCell extends StatelessWidget {
  final int day;
  final bool hasNote;
  final bool isToday;

  const _DateCell({
    required this.day,
    required this.hasNote,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color textColor = const Color(0xFFB0B0B0);

    if (hasNote) {
      bgColor = const Color(0xFF63F204);
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
        day.toString(),
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: (hasNote || isToday) ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }
}

class ProgressRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  const ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8.0) / 2;

    final arcPaint = Paint()
      ..color = const Color(0xFF63F204)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round;

    // Start at -124.4 degrees (-2.17 radians) matching Figma design
    const startAngle = -2.17;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
