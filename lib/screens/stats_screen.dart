import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/task_provider.dart';
import '../widgets/common_widgets.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DateTime _selectedMonth = DateTime.now();
  bool _showWeeklySummary = false;

  @override
  void initState() {
    super.initState();
    _checkWeeklySummary();
  }

  Future<void> _checkWeeklySummary() async {
    final provider = context.read<TaskProvider>();
    final shouldShow = provider.shouldShowWeeklySummary();
    final alreadyShown = await provider.hasWeeklySummaryBeenShown();
    if (mounted) {
      setState(() {
        _showWeeklySummary = shouldShow && !alreadyShown;
      });
    }
  }

  void _dismissWeeklySummary() async {
    final provider = context.read<TaskProvider>();
    await provider.markWeeklySummaryShown();
    if (mounted) {
      setState(() {
        _showWeeklySummary = false;
      });
    }
  }

  Widget _buildWeeklySummaryCard(TaskProvider provider) {
    final lastWeekStart = provider.getWeekStart(DateTime.now()).subtract(const Duration(days: 7));
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
              const Icon(Icons.analytics_outlined, color: AppTheme.accent, size: 20),
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
                onTap: _dismissWeeklySummary,
                child: const Icon(Icons.close, color: AppTheme.mutedText, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryStatItem('Tasks', lastWeek.tasksCompleted.toString(), Icons.task_alt),
              _summaryStatItem('Perfect Days', lastWeek.perfectDays.toString(), Icons.star),
              _summaryStatItem('Completion', '${(lastWeek.completionRate * 100).toInt()}%', Icons.trending_up),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final weeklyRate = provider.getWeeklyCompletionRate();
        final monthlyRate = provider.getMonthlyCompletionRate();
        final heatmapData = provider.getHeatmapData(days: 90);

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Stats',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (provider.shouldShowWeeklySummary())
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppTheme.mutedText, size: 20),
                          onPressed: () {
                            setState(() {
                              _showWeeklySummary = true;
                            });
                          },
                          tooltip: 'Show weekly summary',
                        ),
                    ],
                  ),
                ),
                if (_showWeeklySummary) _buildWeeklySummaryCard(provider),
                StatRow(
                  label1: 'Current streak',
                  value1: provider.streak.toString(),
                  label2: 'Best streak',
                  value2: provider.bestStreak.toString(),
                ),
                const SizedBox(height: 12),
                StatRow(
                  label1: 'This week',
                  value1: '${(weeklyRate * 100).toInt()}%',
                  label2: 'This month',
                  value2: '${(monthlyRate * 100).toInt()}%',
                ),
                const SizedBox(height: 24),
                Text(
                  'ALL TIME STATS',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.mutedText,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFullStats(provider),
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
                _buildCalendarGrid(heatmapData, provider),
                const SizedBox(height: 24),
                _buildLegend(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullStats(TaskProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Total Tasks',
                  value: provider.totalTasksCreated.toString(),
                  icon: Icons.task_alt,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Completed',
                  value: provider.totalTasksCompleted.toString(),
                  icon: Icons.check_circle,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Perfect Days',
                  value: provider.perfectDaysCount.toString(),
                  icon: Icons.star,
                  color: Colors.amber,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Best Day',
                  value: provider.bestDayTasks.toString(),
                  icon: Icons.emoji_events,
                  color: AppTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Avg/Day',
                  value: provider.averageTasksPerDay.toStringAsFixed(1),
                  icon: Icons.trending_up,
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
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
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
            });
          },
          child: const Icon(Icons.chevron_left, color: AppTheme.mutedText),
        ),
        Text(
          monthYear,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        GestureDetector(
          onTap: () {
            final now = DateTime.now();
            if (_selectedMonth.year < now.year || 
                (_selectedMonth.year == now.year && _selectedMonth.month < now.month)) {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
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

  Widget _buildCalendarGrid(Map<DateTime, bool> heatmapData, TaskProvider provider) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    
    int startWeekday = firstDayOfMonth.weekday;
    int daysInMonth = lastDayOfMonth.day;
    
    List<Widget> rows = [];
    List<Widget> currentRow = [];
    
    for (int i = 1; i < startWeekday; i++) {
      currentRow.add(const SizedBox(width: 40, height: 40));
    }
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final hasActivity = heatmapData[normalizedDate] ?? false;
      final isToday = _isToday(date);
      final isFuture = date.isAfter(DateTime.now());
      
      currentRow.add(_buildCalendarDay(day, hasActivity, isToday, isFuture));
      
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
      children: rows.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: row,
      )).toList(),
    );
  }

  Widget _buildCalendarDay(int day, bool hasActivity, bool isToday, bool isFuture) {
    Color bgColor;
    if (isFuture) {
      bgColor = Colors.transparent;
    } else if (hasActivity) {
      bgColor = AppTheme.success;
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
              : null,
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: isFuture 
                  ? AppTheme.mutedText.withValues(alpha: 0.3)
                  : (hasActivity ? Colors.white : AppTheme.mutedText),
            ),
          ),
        ),
      ),
    );
  }

  void _showDayDetail(int day) {
    // Could show detail in future
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(AppTheme.surface, 'No activity'),
        const SizedBox(width: 16),
        _legendItem(AppTheme.success, 'Completed'),
        const SizedBox(width: 16),
        _legendItem(Colors.transparent, 'Future'),
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
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (color ?? AppTheme.accent).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color ?? AppTheme.accent,
          ),
        ),
        const SizedBox(width: 12),
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
    );
  }
}