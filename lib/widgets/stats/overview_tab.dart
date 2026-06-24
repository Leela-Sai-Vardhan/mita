import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/streak_milestones.dart';
import '../../providers/task_provider.dart';
import '../../providers/stats_provider.dart';
import '../../screens/history_detail_screen.dart';
import '../../screens/streak_journey_screen.dart';
import '../../widgets/streak_ring_painter.dart';
import 'stat_card.dart';

class OverviewTab extends StatefulWidget {
  final TaskProvider taskProvider;
  final StatsProvider statsProvider;
  final bool showWeeklySummary;
  final VoidCallback onDismissWeeklySummary;

  const OverviewTab({
    super.key,
    required this.taskProvider,
    required this.statsProvider,
    this.showWeeklySummary = false,
    required this.onDismissWeeklySummary,
  });

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  DateTime _selectedMonth = DateTime.now();

  Widget _buildHeroRow() {
    final provider = widget.taskProvider;
    final streak = provider.streak;
    final perfectDays = provider.perfectDaysCount;
    final totalCreated = provider.totalTasksCreated;
    final totalCompleted = provider.totalTasksCompleted;
    final completionRate =
        totalCreated > 0 ? (totalCompleted / totalCreated * 100).toInt() : 0;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Perfect Days',
            value: perfectDays.toString(),
            icon: Icons.star,
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            label: 'Streak',
            value: streak.toString(),
            icon: Icons.local_fire_department,
            color: AppTheme.getStreakColor(streak),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            label: 'Lifetime',
            value: '$completionRate%',
            icon: Icons.trending_up,
            color: AppTheme.success,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySummaryCard() {
    final provider = widget.taskProvider;
    final lastWeekStart =
        provider.getWeekStart(DateTime.now()).subtract(const Duration(days: 7));
    final lastWeek = provider.getWeeklyStats(weekStart: lastWeekStart);
    final comparison = provider.getWeeklyComparison();

    String comparisonText;
    Color comparisonColor;
    if (comparison > 0) {
      comparisonText = '+$comparison% vs last week';
      comparisonColor = AppTheme.success;
    } else if (comparison < 0) {
      comparisonText = '$comparison% vs last week';
      comparisonColor = AppTheme.accent;
    } else {
      comparisonText = 'same as last week';
      comparisonColor = AppTheme.mutedText;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.2),
            AppTheme.success.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined,
                  color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Last Week Summary',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onDismissWeeklySummary,
                child: const Icon(Icons.close,
                    color: AppTheme.mutedText, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryStatItem(
                  'Tasks', lastWeek.tasksCompleted.toString(), Icons.task_alt),
              _summaryStatItem(
                  'Perfect Days', lastWeek.perfectDays.toString(), Icons.star),
              _summaryStatItem(
                  'Completion',
                  '${(lastWeek.completionRate * 100).toInt()}%',
                  Icons.trending_up),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comparisonText,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: comparisonColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: AppTheme.mutedText, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSummaryCard() {
    final provider = widget.taskProvider;
    final streak = provider.streak;
    final isFrozen = provider.isStreakFrozen;
    final currentMilestone = StreakMilestones.getMilestoneForDays(streak);
    final nextMilestone = StreakMilestones.getNextMilestone(streak);
    final progress = StreakMilestones.getProgressToNextMilestone(streak);
    final streakColor =
        isFrozen ? AppTheme.streakFreeze : AppTheme.getStreakColor(streak);
    final emoji = isFrozen ? '⏳' : '🔥';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StreakJourneyScreen(provider: provider),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: streakColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CustomPaint(
                painter:
                    StatsRingPainter(progress: progress, color: streakColor),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 12)),
                      Text(
                        streak.toString(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: streakColor,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentMilestone?.title ?? 'Current Streak',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (nextMilestone != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  streakColor.withValues(alpha: 0.15),
                              valueColor:
                                  AlwaysStoppedAnimation(streakColor),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${nextMilestone.days - streak}d',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: streakColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${nextMilestone.days - streak} more days to "${nextMilestone.title}"',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                  if (nextMilestone == null && streak >= 3)
                    Text(
                      'Maximum milestone reached!',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppTheme.streakMilestone,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppTheme.mutedText.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final monthYear = DateFormat('MMMM yyyy').format(_selectedMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedMonth =
                  DateTime(_selectedMonth.year, _selectedMonth.month - 1);
            });
          },
          child: const Icon(Icons.chevron_left, color: AppTheme.mutedText),
        ),
        GestureDetector(
          onTap: () => setState(() => _selectedMonth = DateTime.now()),
          child: Text(
            monthYear,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            final now = DateTime.now();
            if (_selectedMonth.year < now.year ||
                (_selectedMonth.year == now.year &&
                    _selectedMonth.month < now.month)) {
              setState(() {
                _selectedMonth =
                    DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              });
            }
          },
          child: Icon(
            Icons.chevron_right,
            color: _selectedMonth.month >= DateTime.now().month &&
                    _selectedMonth.year >= DateTime.now().year
                ? AppTheme.mutedText.withValues(alpha: 0.3)
                : AppTheme.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
          .map((day) => SizedBox(
                width: 40,
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid(Map<DateTime, double> heatmapRatios) {
    final firstDayOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    final startWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    final List<Widget> rows = [];
    List<Widget> currentRow = [];

    for (int i = 1; i < startWeekday; i++) {
      currentRow.add(const SizedBox(width: 40, height: 40));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final ratio = heatmapRatios[normalizedDate] ?? 0.0;
      final isToday = _isToday(date);
      final isFuture = date.isAfter(DateTime.now());

      currentRow.add(_buildCalendarDay(day, ratio, isToday, isFuture));

      if (currentRow.length == 7) {
        rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: currentRow,
        ));
        currentRow = [];
      }
    }

    if (currentRow.isNotEmpty) {
      while (currentRow.length < 7) {
        currentRow.add(const SizedBox(width: 40, height: 40));
      }
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: currentRow,
      ));
    }

    return Column(
      children: rows
          .map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: row,
              ))
          .toList(),
    );
  }

  Widget _buildCalendarDay(
      int day, double ratio, bool isToday, bool isFuture) {
    Color bgColor;
    if (isFuture) {
      bgColor = AppTheme.surface.withValues(alpha: 0.5);
    } else if (ratio > 0.0) {
      bgColor = AppTheme.success.withValues(alpha: 0.2 + (ratio * 0.8));
    } else {
      bgColor = AppTheme.surface;
    }

    return GestureDetector(
      onTap: isFuture ? null : () => _showDayDetail(day),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: AppTheme.accent, width: 2)
              : isFuture
                  ? Border.all(
                      color: AppTheme.mutedText.withValues(alpha: 0.1))
                  : null,
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isFuture
                  ? AppTheme.mutedText.withValues(alpha: 0.3)
                  : (ratio > 0.0 ? Colors.white : AppTheme.mutedText),
            ),
          ),
        ),
      ),
    );
  }

  void _showDayDetail(int day) {
    final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
    if (date.isAfter(DateTime.now())) return;

    final provider = widget.taskProvider;
    final statsProvider = widget.statsProvider;
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final heatmap = provider.getHeatmapData(days: 90);
    final ratio = heatmap[normalizedDate] ?? 0.0;
    final isPerfect = ratio >= 1.0;

    final focusTime = statsProvider.focusTimeByDay[normalizedDate] ?? 0;
    final sessionCount = statsProvider.sessionCountByDay[normalizedDate] ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.mutedText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isPerfect ? AppTheme.success : AppTheme.accent)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPerfect ? Icons.check_circle : Icons.calendar_today,
                    color: isPerfect ? AppTheme.success : AppTheme.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(date),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Completion',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppTheme.mutedText,
                        ),
                      ),
                      Text(
                        '${(ratio * 100).toInt()}%',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ratio >= 1.0
                              ? AppTheme.success
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: AppTheme.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ratio >= 1.0 ? AppTheme.success : AppTheme.accent,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  if (isPerfect) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            size: 16, color: AppTheme.success),
                        const SizedBox(width: 6),
                        Text(
                          'Perfect Day',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 16, color: AppTheme.mutedText),
                      const SizedBox(width: 6),
                      Text(
                        'Focus Time',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppTheme.mutedText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDuration(Duration(seconds: focusTime)),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.play_circle_outline,
                          size: 16, color: AppTheme.mutedText),
                      const SizedBox(width: 6),
                      Text(
                        'Sessions',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppTheme.mutedText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$sessionCount',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showHistoryForDate(date);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'View in History',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  void _showHistoryForDate(DateTime date) async {
    final provider = widget.taskProvider;
    final grouped = await provider.getGroupedTasks(days: 365);
    final tasks = grouped[DateTime(date.year, date.month, date.day)] ?? [];
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryDetailScreen(
          date: date,
          tasks: tasks,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(AppTheme.surface, 'None'),
        const SizedBox(width: 8),
        _legendItem(AppTheme.success.withValues(alpha: 0.2), 'Partial'),
        const SizedBox(width: 8),
        _legendItem(AppTheme.success.withValues(alpha: 0.6), 'Good'),
        const SizedBox(width: 8),
        _legendItem(AppTheme.success, 'Perfect'),
        const SizedBox(width: 8),
        _legendItem(AppTheme.mutedText.withValues(alpha: 0.15), 'Future'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: color == Colors.transparent
                ? Border.all(color: AppTheme.borderEmpty)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppTheme.mutedText,
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.taskProvider;
    final heatmapRatios = provider.getHeatmapData(days: 90);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeroRow(),
          const SizedBox(height: 16),
          if (widget.showWeeklySummary) _buildWeeklySummaryCard(),
          _buildStreakSummaryCard(),
          const SizedBox(height: 24),
          Text(
            'ACTIVITY CALENDAR',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.mutedText,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildCalendarHeader(),
          const SizedBox(height: 8),
          _buildWeekLabels(),
          const SizedBox(height: 8),
          _buildCalendarGrid(heatmapRatios),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
