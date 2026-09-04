import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/task_provider.dart';
import '../data/models/task_model.dart';
import '../services/ad_service.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<DateTime, List<Task>> _groupedTasks = {};
  bool _isLoading = true;
  bool _rewardedFlowActive = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<TaskProvider>(context, listen: false);
    await provider.loadData();
    final unlockedDays = await provider.getUnlockedHistoryDays();
    final grouped = await provider.getGroupedTasks(days: unlockedDays);
    setState(() {
      _groupedTasks = grouped;
      _isLoading = false;
    });
  }

  /// Unlocks 7 more days of history after watching a rewarded ad.
  /// Mirrors the extra-task flow on the Home screen: the unlock is only
  /// granted when the reward is actually earned.
  Future<void> _unlockMoreHistory() async {
    if (_rewardedFlowActive) return;
    final provider = Provider.of<TaskProvider>(context, listen: false);

    if (AdService.disabled) {
      // Ads remotely off: unlock for free so the feature never dead-ends.
      await provider.unlockMoreHistory(7);
      await _loadHistory();
      return;
    }

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

    _rewardedFlowActive = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(width: 16),
            Text('Loading ad...',
                style: GoogleFonts.dmSans(color: Colors.white)),
          ],
        ),
      ),
    );

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Build the result snackbars up front (customSnackBar is pure) so no
    // BuildContext is touched after the async ad gap.
    final successBar = AppTheme.customSnackBar(
      message: 'Unlocked 7 more days of history!',
      context: context,
      icon: Icons.check_circle_outline,
      leftBarColor: AppTheme.success,
    );
    final failureBar = AppTheme.customSnackBar(
      message: 'Ad closed before completing. History not unlocked.',
      context: context,
      icon: Icons.info_outline,
      leftBarColor: Colors.orangeAccent,
    );

    final earned = await AdService().showRewardedAd();
    navigator.pop();
    _rewardedFlowActive = false;

    if (earned) {
      await provider.unlockMoreHistory(7);
      await _loadHistory();
    }
    if (mounted) messenger.showSnackBar(earned ? successBar : failureBar);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'History',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _groupedTasks.isEmpty
                      ? _buildEmptyState()
                      : _buildHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.history, size: 36, color: AppTheme.mutedText),
          ),
          const SizedBox(height: 20),
          Text(
            'No history yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your 3 daily tasks and watch\nyour history grow day by day.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppTheme.mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final sortedDates = _groupedTasks.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView.builder(
      itemCount: sortedDates.length + 1,
      itemBuilder: (context, index) {
        if (index == sortedDates.length) {
          return _buildLoadMore();
        }
        final date = sortedDates[index];
        final tasks = _groupedTasks[date] ?? [];
        return _buildHistoryCard(date, tasks);
      },
    );
  }

  Widget _buildHistoryCard(DateTime date, List<Task> tasks) {
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final totalCount = tasks.length;
    final isPerfect = totalCount >= 3 && completedCount == 3 && totalCount <= 3;

    final dateStr = DateFormat('EEEE, d MMM').format(date);
    final score = isPerfect ? '$completedCount/$totalCount ✓' : '$completedCount/$totalCount';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryDetailScreen(
              date: date,
              tasks: tasks,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      score,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isPerfect ? AppTheme.success : AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.mutedText,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...tasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      task.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: task.isCompleted ? AppTheme.mutedText : Colors.white,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLockCard() {
    final adReady = !AdService.disabled && AdService().isRewardedReady;
    return GestureDetector(
      onTap: _unlockMoreHistory,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: adReady ? Colors.orange : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: adReady
                ? Colors.orange.withValues(alpha: 0.4)
                : AppTheme.borderEmpty,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              adReady ? Icons.play_circle_outline : Icons.lock_open,
              color: adReady ? Colors.white : AppTheme.accent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                AdService.disabled
                    ? 'Tap to unlock 7 more days'
                    : adReady
                        ? 'Watch ad to unlock 7 more days'
                        : 'Preparing ad...',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: adReady ? Colors.white : AppTheme.mutedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMore() {
    return _buildLockCard();
  }
}