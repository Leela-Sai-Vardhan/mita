import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/task_provider.dart';
import '../data/models/task_model.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<DateTime, List<Task>> _groupedTasks = {};
  bool _isLoading = true;

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

  void _unlockMoreHistory() async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    await provider.unlockMoreHistory(7);
    await _loadHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unlocked 7 more days of history!', style: GoogleFonts.dmSans()),
          backgroundColor: AppTheme.success,
        ),
      );
    }
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
          const Icon(Icons.history, size: 48, color: AppTheme.mutedText),
          const SizedBox(height: 16),
          Text(
            'No history yet',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete tasks to see your history',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppTheme.placeholderText,
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
    return GestureDetector(
      onTap: _unlockMoreHistory,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderEmpty, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_open, color: AppTheme.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              'Tap to unlock older history',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppTheme.mutedText,
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