import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../providers/stats_provider.dart';
import 'stat_card.dart';

class FocusTab extends StatelessWidget {
  final StatsProvider statsProvider;
  const FocusTab({super.key, required this.statsProvider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBarChart(),
          const SizedBox(height: 28),
          _buildSessionBreakdown(),
          const SizedBox(height: 24),
          _buildStatCardsRow1(),
          const SizedBox(height: 24),
          _buildStatCardsRow2(),
          const SizedBox(height: 24),
          _buildSessionQuality(),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final rawData = statsProvider.focusTimeByDay;

    final barValues = last7Days.map((day) {
      final key = DateTime(day.year, day.month, day.day);
      final sec = rawData[key] ?? 0;
      return (sec / 3600.0);
    }).toList();

    final totalHours = barValues.fold(0.0, (a, b) => a + b);
    final dailyAvgHours = totalHours / 7;
    final maxVal = barValues.reduce((a, b) => a > b ? a : b);
    final maxY = (maxVal * 1.2).clamp(0.5, double.infinity);

    final dayAbbr = last7Days
        .map((d) {
          const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
          return names[d.weekday - 1];
        })
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'FOCUS TIME',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: AppTheme.mutedText,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent) {
                    HapticFeedback.selectionClick();
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final index = group.x.toInt();
                    if (index >= 0 && index < 7) {
                      final day = last7Days[index];
                      const dayNames = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun'
                      ];
                      final label = dayNames[day.weekday - 1];
                      final hrs = rod.toY;
                      return BarTooltipItem(
                        '$label\n${hrs.toStringAsFixed(1)}h',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i >= 0 && i < 7) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            dayAbbr[i],
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
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(7, (i) {
                final hours = barValues[i];
                final isAbove = hours > dailyAvgHours;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: hours,
                      gradient: LinearGradient(
                        colors: isAbove
                            ? [AppTheme.accent, const Color(0xFFFF6B7D)]
                            : [
                                const Color(0xFF6B2332),
                                const Color(0xFF8B3342)
                              ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 12,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: dailyAvgHours,
                    color: AppTheme.mutedText.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ],
              ),
            ),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionBreakdown() {
    final deep = statsProvider.deepFocusSessions;
    final quick = statsProvider.quickFocusSessions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'SESSION BREAKDOWN',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: AppTheme.mutedText,
            ),
          ),
        ),
        Row(
          children: [
            _breakdownItem(
              icon: Icons.circle,
              iconColor: AppTheme.accent,
              count: deep,
              label: 'deep focus',
            ),
            const SizedBox(width: 20),
            _breakdownItem(
              icon: Icons.circle,
              iconColor: const Color(0xFFF5A623),
              count: quick,
              label: 'quick focus',
            ),
          ],
        ),
      ],
    );
  }

  Widget _breakdownItem({
    required IconData icon,
    required Color iconColor,
    required int count,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: iconColor, width: 3),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardsRow1() {
    final totalSec = statsProvider.totalFocusSeconds;
    final totalLabel = totalSec >= 3600
        ? '${totalSec ~/ 3600}h ${(totalSec % 3600) ~/ 60}m'
        : '${totalSec ~/ 60}m';

    final avgSec = statsProvider.avgDurationSec.round();
    String avgLabel;
    if (avgSec >= 3600) {
      avgLabel = '${avgSec ~/ 3600}h ${(avgSec % 3600) ~/ 60}m';
    } else {
      avgLabel = '${avgSec ~/ 60}m';
    }
    if (avgSec == 0) avgLabel = '0m';

    final bestDaySec = statsProvider.bestFocusDaySeconds;
    final bestDayLabel = '${(bestDaySec / 3600).toStringAsFixed(1)}h';

    return Row(
      children: [
        StatCard(
          value: totalLabel,
          label: 'Total Focus Time',
          icon: Icons.timer_outlined,
        ),
        const SizedBox(width: 8),
        StatCard(
          value: avgLabel,
          label: 'Avg Duration',
          icon: Icons.speed,
        ),
        const SizedBox(width: 8),
        StatCard(
          value: bestDayLabel,
          label: 'Best Day',
          icon: Icons.emoji_events,
        ),
      ],
    );
  }

  Widget _buildStatCardsRow2() {
    final avgInt = statsProvider.avgInterruptions;
    final avgIntLabel = avgInt > 0 ? avgInt.toStringAsFixed(1) : '0';

    return Row(
      children: [
        StatCard(
          value: statsProvider.totalFocusSessions.toString(),
          label: 'Total Sessions',
          icon: Icons.repeat,
        ),
        const SizedBox(width: 8),
        StatCard(
          value: avgIntLabel,
          label: 'Avg Interruptions',
          icon: Icons.notifications_off_outlined,
        ),
        const SizedBox(width: 8),
        StatCard(
          value: '${statsProvider.focusStreak}',
          label: 'Focus Streak',
          icon: Icons.local_fire_department,
          color: AppTheme.getStreakColor(statsProvider.focusStreak),
        ),
      ],
    );
  }

  Widget _buildSessionQuality() {
    final completed = statsProvider.completedFocusSessions;
    final incomplete =
        statsProvider.totalFocusSessions - statsProvider.completedFocusSessions;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _qualityDot(
            'Completed: $completed',
            AppTheme.success,
          ),
          const SizedBox(width: 32),
          _qualityDot(
            'Incomplete: $incomplete',
            AppTheme.mutedText,
          ),
        ],
      ),
    );
  }

  Widget _qualityDot(String text, Color dotColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
