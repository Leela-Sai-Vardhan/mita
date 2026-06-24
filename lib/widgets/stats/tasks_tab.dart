import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../providers/stats_provider.dart';
import 'stat_card.dart';

class TasksTab extends StatelessWidget {
  final StatsProvider statsProvider;
  const TasksTab({super.key, required this.statsProvider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLineChart(),
          const SizedBox(height: 28),
          _buildStatCardsRow1(),
          const SizedBox(height: 8),
          _buildStatCardsRow2(),
          const SizedBox(height: 24),
          _buildTimeToCompleteCard(),
          const SizedBox(height: 24),
          _buildInsightCard(),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    final data = statsProvider.weeklyCompletionData;

    final spots = data.asMap().entries.map((entry) {
      final rate = (entry.value['rate'] as double).clamp(0.0, 1.0);
      return FlSpot(entry.key.toDouble(), rate);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'COMPLETION RATE',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: AppTheme.mutedText,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 3,
              minY: 0,
              maxY: 1,
              clipData: const FlClipData.all(),
              lineTouchData: LineTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent) {
                    HapticFeedback.selectionClick();
                  }
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final weekIndex = spot.x.toInt();
                      final pct = (spot.y * 100).toInt();
                      return LineTooltipItem(
                        'Week ${weekIndex + 1}: $pct%',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i >= 0 && i < 4) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'W${i + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 0.5,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${(value * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.mutedText,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: AppTheme.success,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.success.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCardsRow1() {
    return Row(
      children: [
        StatCard(
          value: statsProvider.totalTasksCreated.toString(),
          label: 'Total Created',
          icon: Icons.task_alt,
        ),
        const SizedBox(width: 8),
        StatCard(
          value: statsProvider.totalTasksCompleted.toString(),
          label: 'Total Done',
          icon: Icons.check_circle,
          color: AppTheme.success,
        ),
        const SizedBox(width: 8),
        StatCard(
          value: statsProvider.averageTasksPerDay.toStringAsFixed(1),
          label: 'Avg / Day',
          icon: Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildStatCardsRow2() {
    final monthlyRate = (statsProvider.monthlyCompletionRate * 100).toInt();
    final weeklyRate = (statsProvider.weeklyCompletionRate * 100).toInt();

    return Row(
      children: [
        StatCard(
          value: '$monthlyRate%',
          label: 'Monthly Rate',
          icon: Icons.date_range,
          color: AppTheme.success,
        ),
        const SizedBox(width: 8),
        StatCard(
          value: '$weeklyRate%',
          label: 'Weekly Rate',
          icon: Icons.trending_up,
          color: AppTheme.success,
        ),
        const SizedBox(width: 8),
        StatCard(
          value: statsProvider.bestDayTasks.toString(),
          label: 'Best Day',
          icon: Icons.emoji_events,
          color: AppTheme.accent,
        ),
      ],
    );
  }

  Widget _buildTimeToCompleteCard() {
    final avgSec = statsProvider.avgTimeToCompleteSec.round();
    if (avgSec <= 0) return const SizedBox.shrink();

    String label;
    if (avgSec >= 86400) {
      final days = avgSec ~/ 86400;
      label = '$days day${days > 1 ? 's' : ''}';
    } else if (avgSec >= 3600) {
      final hours = avgSec ~/ 3600;
      label = '$hours hour${hours > 1 ? 's' : ''}';
    } else if (avgSec >= 60) {
      final mins = avgSec ~/ 60;
      label = '$mins min${mins > 1 ? 's' : ''}';
    } else {
      label = '$avgSec sec';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.schedule,
              color: AppTheme.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'avg time to complete a task',
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

  Widget _buildInsightCard() {
    final breakdown = statsProvider.timeOfDayBreakdown;
    final total =
        breakdown.values.fold(0, (int a, int b) => a + b);

    if (total == 0) {
      return const SizedBox.shrink();
    }

    final morning = breakdown['morning']!;
    final afternoon = breakdown['afternoon']!;
    final evening = breakdown['evening']!;

    final morningPct = (morning / total * 100).toInt();
    final afternoonPct = (afternoon / total * 100).toInt();
    final eveningPct = (evening / total * 100).toInt();

    String peakPeriod;
    int peakPct;
    if (morning >= afternoon && morning >= evening) {
      peakPeriod = 'Morning';
      peakPct = morningPct;
    } else if (afternoon >= evening) {
      peakPeriod = 'Afternoon';
      peakPct = afternoonPct;
    } else {
      peakPeriod = 'Evening';
      peakPct = eveningPct;
    }

    final article = peakPeriod == 'Morning' ? 'a' : 'an';
    final timeDesc = peakPeriod == 'Morning'
        ? 'before noon'
        : peakPeriod == 'Afternoon'
            ? 'in the afternoon'
            : 'in the evening';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are $article $peakPeriod Achiever!',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$peakPct% of your tasks are done\n$timeDesc.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppTheme.mutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _periodIcon(
                '🌅',
                morning,
                morningPct,
                peakPeriod == 'Morning',
              ),
              const SizedBox(width: 16),
              _periodIcon(
                '☀️',
                afternoon,
                afternoonPct,
                peakPeriod == 'Afternoon',
              ),
              const SizedBox(width: 16),
              _periodIcon(
                '🌙',
                evening,
                eveningPct,
                peakPeriod == 'Evening',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodIcon(
    String emoji,
    int count,
    int pct,
    bool isPeak,
  ) {
    final color = isPeak ? AppTheme.accent : AppTheme.mutedText;

    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            '$count tasks',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            '$pct%',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: color,
              fontWeight: isPeak ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
