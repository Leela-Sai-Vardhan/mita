import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/models/task_model.dart';
import '../providers/task_provider.dart';
import '../services/ad_service.dart';
import 'focus_screen.dart';

class HistoryDetailScreen extends StatefulWidget {
  final DateTime date;
  final List<Task> tasks;

  const HistoryDetailScreen({
    super.key,
    required this.date,
    required this.tasks,
  });

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final dateString = DateFormat('yyyy-MM-dd').format(widget.date);
        final currentTasks = provider.allTasks.where((t) => 
          DateFormat('yyyy-MM-dd').format(t.date) == dateString
        ).toList();

        final completedTasks = currentTasks.where((t) => t.isCompleted).toList();
        final completionRate = currentTasks.isEmpty ? 0.0 : completedTasks.length / currentTasks.length;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          DateFormat('EEEE, d MMMM yyyy').format(widget.date),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDaySummary(currentTasks, completedTasks.length, currentTasks.length, completionRate),
            const SizedBox(height: 24),
            _buildProductivityInsight(completedTasks),
            const SizedBox(height: 24),
            Text(
              'TASKS',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.mutedText,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...currentTasks.map((task) => _buildTaskCard(task, provider)),
          ],
        ),
      ),
    );
    },
    );
  }

  Widget _buildDaySummary(List<Task> currentTasks, int completed, int total, double rate) {
    final avgDuration = _calculateAverageDuration(currentTasks);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'DAY SUMMARY',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.mutedText,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total', total.toString(), Icons.list_alt),
              _buildSummaryItem('Completed', '$completed/$total', Icons.check_circle),
              _buildSummaryItem('Avg. Time', avgDuration, Icons.timer),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: AppTheme.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                rate == 1.0 ? AppTheme.success : AppTheme.accent,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rate == 1.0 ? '🎉 Perfect Day!' : '${(rate * 100).toInt()}% completion rate',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: rate == 1.0 ? AppTheme.success : AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.mutedText, size: 20),
        const SizedBox(height: 4),
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
    );
  }

  Widget _buildProductivityInsight(List<Task> completedTasks) {
    final insight = _getProductivityInsight(completedTasks);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            insight.emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  insight.subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ProductivityInsight _getProductivityInsight(List<Task> completedTasks) {
    if (completedTasks.isEmpty) {
      return _ProductivityInsight(
        emoji: '😴',
        title: 'No Completed Tasks',
        subtitle: 'Complete tasks to see your productivity pattern',
      );
    }

    int morningCount = 0;
    int afternoonCount = 0;
    int eveningCount = 0;

    for (final task in completedTasks) {
      if (task.completedAt != null) {
        final hour = task.completedAt!.hour;
        if (hour >= 5 && hour < 12) {
          morningCount++;
        } else if (hour >= 12 && hour < 17) {
          afternoonCount++;
        } else {
          eveningCount++;
        }
      }
    }

    final maxCount = [morningCount, afternoonCount, eveningCount].reduce((a, b) => a > b ? a : b);

    if (maxCount == morningCount && morningCount > 0) {
      return _ProductivityInsight(
        emoji: '🌅',
        title: 'Morning Champion',
        subtitle: 'You\'re most productive in the morning',
      );
    } else if (maxCount == afternoonCount && afternoonCount > 0) {
      return _ProductivityInsight(
        emoji: '☀️',
        title: 'Afternoon Achiever',
        subtitle: 'You\'re most productive in the afternoon',
      );
    } else if (maxCount == eveningCount && eveningCount > 0) {
      return _ProductivityInsight(
        emoji: '🌙',
        title: 'Night Owl',
        subtitle: 'You\'re most productive in the evening',
      );
    }

    return _ProductivityInsight(
      emoji: '🎯',
      title: 'Consistent Worker',
      subtitle: 'You maintain steady productivity throughout the day',
    );
  }

  String _calculateAverageDuration(List<Task> currentTasks) {
    final completedWithTime = currentTasks.where((t) => 
      t.isCompleted && t.completedAt != null
    ).toList();

    if (completedWithTime.isEmpty) return '--';

    int totalMinutes = 0;
    for (final task in completedWithTime) {
      final duration = task.completedAt!.difference(task.date).inMinutes;
      totalMinutes += duration;
    }

    final avgMinutes = totalMinutes / completedWithTime.length;
    
    if (avgMinutes < 60) {
      return '${avgMinutes.toInt()}m avg.';
    } else {
      final hours = avgMinutes ~/ 60;
      final mins = (avgMinutes % 60).toInt();
      return '${hours}h ${mins}m avg.';
    }
  }

  Widget _buildTaskCard(Task task, TaskProvider provider) {
    final createdTime = DateFormat('h:mm a').format(task.date);
    final completedTime = task.completedAt != null 
        ? DateFormat('h:mm a').format(task.completedAt!) 
        : null;
    
    Duration? duration;
    if (task.completedAt != null) {
      duration = task.completedAt!.difference(task.date);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => FocusScreen(
              taskId: task.id ?? 0,
              taskTitle: task.title,
              isCompleted: true, // historical tasks are always read-only
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: task.isCompleted ? AppTheme.doneBackground : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task.isCompleted ? AppTheme.doneBorder : AppTheme.borderEmpty,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    if (task.isCompleted) {
                      final confirm = await _showUnmarkConfirmationDialog(context);
                      if (confirm == true && mounted) {
                        _showRewardedAdAndToggle(context, provider, task);
                      }
                    } else {
                      final dateString = DateFormat('yyyy-MM-dd').format(widget.date);
                      final now = DateTime.now();
                      final todayString = DateFormat('yyyy-MM-dd').format(now);
                      final isPastDay = dateString.compareTo(todayString) < 0;

                      if (isPastDay) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            AppTheme.customSnackBar(
                              message: 'Cannot complete tasks from previous days.',
                              context: context,
                              icon: Icons.error_outline,
                              leftBarColor: Colors.redAccent,
                            ),
                          );
                        }
                        return;
                      }

                      final confirm = await _showCompleteConfirmationDialog(context, task);
                      if (confirm == true) {
                        provider.toggleTask(task);
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.isCompleted ? AppTheme.success : Colors.transparent,
                        border: Border.all(
                          color: task.isCompleted ? AppTheme.success : AppTheme.mutedText,
                          width: 1.5,
                        ),
                      ),
                      child: task.isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: task.isCompleted ? AppTheme.mutedText : Colors.white,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (task.isExtended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Extended',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTimeRow('Created', createdTime, Icons.add_circle_outline),
            if (completedTime != null) ...[
              const SizedBox(height: 8),
              _buildTimeRow('Completed', completedTime, Icons.check_circle_outline),
            ],
            if (duration != null && task.isCompleted) ...[
              const SizedBox(height: 8),
              _buildTimeRow('Duration', _formatDuration(duration), Icons.timer_outlined),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, String time, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.mutedText),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppTheme.mutedText,
          ),
        ),
        Text(
          time,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  Future<bool?> _showCompleteConfirmationDialog(BuildContext context, Task task) {
    return AppTheme.showPremiumConfirmDialog(
      context: context,
      title: 'Mark as Complete?',
      content: 'This task will be marked as completed. You cannot undo this action directly from Today.\n\nTo unmark this task later, you will need to watch a rewarded ad on the History screen.',
      confirmLabel: 'Confirm',
      headerIcon: Icons.check_circle_outline,
      accentColor: AppTheme.success,
    );
  }

  Future<bool?> _showUnmarkConfirmationDialog(BuildContext context) {
    return AppTheme.showPremiumConfirmDialog(
      context: context,
      title: 'Unmark Completed Task?',
      content: 'To mark this completed task as incomplete, you must watch a short rewarded ad. Do you want to proceed?',
      confirmLabel: 'Watch Ad',
      headerIcon: Icons.play_circle_outline,
      accentColor: AppTheme.accent,
    );
  }

  void _showRewardedAdAndToggle(BuildContext context, TaskProvider provider, Task task) {
    if (!AdService().isRewardedReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.customSnackBar(
          message: 'Ad not ready yet, try again in a moment',
          context: context,
          icon: Icons.info_outline,
          leftBarColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        content: Row(
          children: [
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
            ),
            const SizedBox(width: 16),
            Text('Loading ad...', style: GoogleFonts.dmSans(color: Colors.white)),
          ],
        ),
      ),
    );

    AdService().showRewardedAd(
      onEarned: (amount) {
        if (context.mounted) Navigator.pop(context); // Pop loading dialog
        provider.toggleTask(task);
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.customSnackBar(
            message: 'Task unmarked successfully!',
            context: context,
            icon: Icons.check_circle_outline,
            leftBarColor: AppTheme.success,
          ),
        );
      },
      onAdFailed: () {
        if (context.mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.customSnackBar(
            message: 'Ad failed to load. Please try again.',
            context: context,
            icon: Icons.error_outline,
            leftBarColor: Colors.redAccent,
          ),
        );
      },
    );
  }
}

class _ProductivityInsight {
  final String emoji;
  final String title;
  final String subtitle;

  _ProductivityInsight({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}