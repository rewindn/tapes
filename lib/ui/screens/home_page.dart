import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tapes/models/home_ui_state.dart';
import 'package:tapes/repositories/note_repository.dart';
import 'package:tapes/ui/widgets/home/calendar_grid.dart';
import 'package:tapes/ui/widgets/home/progress_ring.dart';
import 'package:tapes/ui/widgets/home/week_card.dart';
import 'package:tapes/constants/app_colors.dart';

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
          color: AppColors.background,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 64.0,
                    bottom: 32.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  state.dayName,
                                  style: const TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.tapeGold,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Text(
                                    state.now.day.toString(),
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                state.monthName,
                                style: const TextStyle(
                                  fontFamily: 'PlayfairDisplay',
                                  fontSize: 40.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                state.yearString,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: ProgressRing(progress: state.progress),
                      ),
                    ],
                  ),
                ),

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
