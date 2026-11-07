import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tapes/models/home_ui_state.dart';
import 'package:tapes/note_repository.dart';
import 'package:tapes/widgets/home/calendar_grid.dart';
import 'package:tapes/widgets/home/progress_ring.dart';
import 'package:tapes/widgets/home/week_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<NoteRepository>();
    return ValueListenableBuilder<Box<dynamic>>(
      valueListenable: repo.listenable,
      builder: (_, _, _) {
        final state = HomeUiState.fromNotes(repo.getAllNotes());

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
                                state.dayName,
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
                                  state.now.day.toString(),
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
                                  state.monthName,
                                  style: const TextStyle(
                                    fontFamily: 'Georgia',
                                    fontFamilyFallback: [
                                      'Times New Roman',
                                      'serif',
                                    ],
                                    fontSize: 48,
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xFF3F3F3F),
                                    height: 1.05,
                                  ),
                                ),
                                Text(
                                  state.yearString,
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
                      ProgressRing(progress: state.progress),
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
                        child: WeekCard(
                          weekDates: state.weekDates,
                          noteDates: state.noteDates,
                        ),
                      ),

                      // Month Calendar Card (Dark Charcoal, overlapping Week Card)
                      Positioned(
                        top: 120,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: CalendarGrid(
                          monthDates: state.monthDates,
                          currentMonth: state.currentMonth,
                          noteDates: state.noteDates,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
