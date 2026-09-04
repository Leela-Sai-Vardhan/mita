import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/streak_milestones.dart';
import '../providers/task_provider.dart';
import '../providers/pomodoro_provider.dart';
import '../data/models/task_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/ad_service.dart';
import '../widgets/streak_indicator_widget.dart';
import '../widgets/streak_dashboard.dart';
import '../widgets/wisdom_banner.dart';
import '../core/wisdom_messages.dart';
import '../core/quick_picks.dart';
import '../data/database_helper.dart';
import '../widgets/goal_select_sheet.dart';
import '../widgets/all_done_animation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'focus_screen.dart';
import '../services/rate_prompt_service.dart';
import '../widgets/upcoming_events_banner.dart';
import '../widgets/winter_arc_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _picks = const [];
  bool _quickPicksHidden = false;
  bool _goalPromptShown = false;

  DateTime? _quickPicksDate;
  List<String>? _cachedPastTitles;
  bool _rewardedFlowActive = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TaskProvider>(context, listen: false);
    provider.addListener(_onProviderChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingMilestone());
    _loadQuickPicks();
    _maybePromptGoals();
  }

  @override
  void dispose() {
    Provider.of<TaskProvider>(context, listen: false).removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    if (provider.pendingMilestoneCelebration != null && mounted) {
      // Defer until after the current build frame: this listener can fire
      // synchronously while the tree is building, and calling showDialog /
      // setState mid-build throws "setState() called during build".
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleMilestone(provider));
    }
  }

  void _handleMilestone(TaskProvider provider) {
    if (!mounted) return;
    final days = provider.pendingMilestoneCelebration;
    if (days == null) return;
    provider.clearMilestoneCelebration();
    _showMilestoneCelebration(days);
  }

  void _checkPendingMilestone() {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    if (provider.pendingMilestoneCelebration != null && mounted) {
      final days = provider.pendingMilestoneCelebration!;
      provider.clearMilestoneCelebration();
      _showMilestoneCelebration(days);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final dateStr = DateFormat('EEEE, d MMM').format(now);

        final (wisdomParts, isPerfectToday) = WisdomMessages.getMessage(
          streak: provider.streak,
          completedCount: provider.completedCount,
          todayTotal: provider.todayTasks.length,
          isPerfectDay: provider.isPerfectDay,
        );
        final daysToNext = StreakMilestones.getDaysToNextMilestone(provider.streak);
        final showBanner = provider.isPerfectDay ||
            (daysToNext != null && daysToNext > 0 && daysToNext <= 3);
        final accent = AppTheme.getStreakColor(provider.streak);

        return SafeArea(
          child: Column(
            children: [
              _buildTopBar(provider, dateStr, context),
              _buildDayProgressCard(provider),
              const WinterArcCard(),
              const UpcomingEventsBanner(),
              if (showBanner && wisdomParts != null)
                WisdomBanner(
                  accent: accent,
                  parts: wisdomParts,
                  isPerfectDay: isPerfectToday,
                ),
              Expanded(child: _buildTaskList(provider, context)),
              _buildAddButton(provider, context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(TaskProvider provider, String dateStr, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.isPerfectDay ? 'Perfect Day ✓' : 'Today',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: provider.isPerfectDay ? AppTheme.success : AppTheme.accent,
                ),
              ),
              Text(
                dateStr,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
          StreakIndicator(
            streak: provider.streak,
            isFrozen: provider.isStreakFrozen,
            onTap: () => _showStreakDashboard(context, provider),
          )
        ],
      ),
    );
  }

  Widget _buildDayProgressCard(TaskProvider provider) {
    final progress = provider.todayTasks.isEmpty
        ? 0.0
        : provider.completedCount / provider.todayTasks.length;

    final percent = provider.timeRemainingPercent;
    final isWrappingUp = percent <= 0.25;
    final hoursLeft = provider.secondsRemainingToday ~/ 3600;
    final minutesLeft = (provider.secondsRemainingToday % 3600) ~/ 60;
    final timeText = hoursLeft > 0
        ? '${hoursLeft}h ${minutesLeft}m left'
        : '${minutesLeft}m left';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderEmpty),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.isPerfectDay
                      ? '${provider.completedCount} of ${provider.todayTasks.length} complete!'
                      : '${provider.completedCount} of ${provider.todayTasks.length} tasks done',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: provider.isPerfectDay ? AppTheme.success : AppTheme.mutedText,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: isWrappingUp ? Colors.orange : AppTheme.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeText,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isWrappingUp ? Colors.orange : AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                provider.isPerfectDay ? AppTheme.success : AppTheme.accent,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(TaskProvider provider, BuildContext context) {
    final visiblePicks =
        _shouldShowQuickPicks(provider) ? _visiblePicks(provider) : const <String>[];
    final picksWidget =
        visiblePicks.isNotEmpty ? _buildQuickPicks(provider, visiblePicks) : null;

    if (provider.todayTasks.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          if (picksWidget != null) picksWidget,
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderEmpty),
            ),
            child: Column(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.edit_note, color: AppTheme.accent, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  'What will you accomplish today?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set 3 tasks. Stay focused.\nBuild your streak one day at a time.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppTheme.mutedText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, duration: 600.ms),
          const SizedBox(height: 12),
          _buildEmptySlot(0, context, provider),
        ],
      );
    }
    final baseCount = provider.todayTasks.length + (provider.canAddTask ? 1 : 0);
    final itemCount = baseCount + (picksWidget != null ? 1 : 0);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (picksWidget != null && index == 0) return picksWidget;
        final taskIndex = picksWidget != null ? index - 1 : index;
        if (taskIndex < provider.todayTasks.length) {
          return _buildTaskCard(provider.todayTasks[taskIndex], provider).animate().fadeIn().slideX();
        } else {
          return _buildEmptySlot(taskIndex, context, provider);
        }
      },
    );
  }

  Future<void> _maybePromptGoals() async {
    if (_goalPromptShown) return;
    _goalPromptShown = true;
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!await QuickPicks.isGoalSelectionDone()) {
        if (!mounted || !context.mounted) return;
        final result = await GoalSelectSheet.show(context);
        if (result != null) {
          await QuickPicks.saveGoals(result);
        }
        await QuickPicks.markGoalSelectionDone();
        if (mounted) _loadQuickPicks(forceRefresh: true);
      }
    } catch (e) {
      debugPrint('[Home] Goal prompt failed: $e');
    }
  }

  Future<void> _loadQuickPicks({bool forceRefresh = false}) async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (prefs.getString('quick_picks_hidden') == todayKey) return;

      final goalKeys = await QuickPicks.getGoalKeys();

      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);

      if (forceRefresh ||
          _cachedPastTitles == null ||
          _quickPicksDate != todayDate) {
        final allTasks = await DatabaseHelper.instance.getAllTasks();
        _cachedPastTitles =
            allTasks.where((t) => t.isCompleted).map((t) => t.title).toList();
        _quickPicksDate = todayDate;
      }

      final picks = QuickPicks.suggest(
        todayTitles: provider.todayTasks.map((t) => t.title).toList(),
        pastTitles: _cachedPastTitles!,
        goalKeys: goalKeys,
      );
      if (mounted && picks.isNotEmpty) {
        setState(() => _picks = picks);
      }
    } catch (e) {
      debugPrint('[Home] Load quick picks failed: $e');
    }
  }

  bool _shouldShowQuickPicks(TaskProvider provider) {
    if (_quickPicksHidden) return false;
    if (provider.todayTasks.length >= 3) return false;
    return _picks.isNotEmpty;
  }

  List<String> _visiblePicks(TaskProvider provider) {
    final today = provider.todayTasks
        .map((t) => t.title.trim().toLowerCase())
        .toSet();
    return _picks
        .where((p) => !today.contains(p.trim().toLowerCase()))
        .toList();
  }

  Widget _buildQuickPicks(TaskProvider provider, List<String> picks) {
    final isAtRisk = provider.isStreakFrozen && provider.todayTasks.isEmpty;
    final accent = isAtRisk ? AppTheme.streakFreeze : AppTheme.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAtRisk ? accent.withValues(alpha: 0.4) : AppTheme.borderEmpty,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAtRisk ? Icons.warning_amber_rounded : Icons.auto_awesome,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isAtRisk
                      ? 'Save your streak — quick pick'
                      : 'Quick picks · ${QuickPicks.timeBucketLabel()}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _dismissQuickPicks,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: AppTheme.mutedText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final title in picks)
                GestureDetector(
                  onTap: () => _addQuickPick(provider, title),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isAtRisk && title == picks.first
                          ? accent.withValues(alpha: 0.15)
                          : AppTheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAtRisk && title == picks.first
                            ? accent.withValues(alpha: 0.6)
                            : AppTheme.borderEmpty,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 14, color: AppTheme.accent),
                        const SizedBox(width: 4),
                        Text(
                          title,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addQuickPick(TaskProvider provider, String title) async {
    HapticFeedback.selectionClick();
    await provider.addTask(title);
    if (!mounted) return;
    setState(() => _picks = _picks.where((p) => p != title).toList());
  }

  Future<void> _dismissQuickPicks() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('quick_picks_hidden', todayKey);
    if (!mounted) return;
    setState(() {
      _quickPicksHidden = true;
      _picks = const [];
    });
  }

  Widget _buildTaskCard(Task task, TaskProvider provider) {
    return Dismissible(
      key: Key('task_${task.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (task.isCompleted) {
            _showUnmarkHint(context);
          } else {
            await _completeTaskWithUndo(context, provider, task);
          }
          return false;
        }
        return true;
      },
      onDismissed: (direction) {
        final tTitle = task.title;
        final tExtended = task.isExtended;
        final tCompleted = task.isCompleted;
        final tCompletedAt = task.completedAt;

        // Capture messenger BEFORE deleteTask triggers a rebuild
        final messenger = ScaffoldMessenger.of(context);

        provider.deleteTask(task);

        // Clear any old SnackBars first
        messenger.clearSnackBars();

        bool undoPressed = false;
        messenger.showSnackBar(
          AppTheme.customSnackBar(
            context: context,
            message: 'Task deleted',
            icon: Icons.delete_outline,
            leftBarColor: Colors.redAccent,
            duration: const Duration(days: 365),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppTheme.accent,
              onPressed: () {
                undoPressed = true;
                provider.addTask(
                  tTitle,
                  isExtended: tExtended,
                  preCompleted: tCompleted,
                  preCompletedAt: tCompletedAt,
                );
              },
            ),
          ),
        );

        // Force-dismiss after 4 seconds using a real dart Timer
        Timer(const Duration(seconds: 4), () {
          if (!undoPressed) {
            try {
              messenger.removeCurrentSnackBar();
            } catch (_) {}
          }
        });
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.success,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () => _navigateToFocus(context, task),

        child: Consumer<PomodoroProvider>(
          builder: (context, pomo, _) {
            final isFocusing = pomo.taskId == task.id && pomo.hasActiveSession;
            final remaining = pomo.timer.remaining;
            final total = pomo.timer.totalDuration;
            final progress = total > 0 ? remaining / total : 0.0;
            final mins = remaining ~/ 60;
            final secs = remaining % 60;
            final timeStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? AppTheme.doneBackground
                    : (isFocusing
                        ? AppTheme.accent.withValues(alpha: 0.08)
                        : (task.isExtended ? const Color(0xFF1E1A10) : AppTheme.surface)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: task.isCompleted
                      ? AppTheme.doneBorder
                      : (isFocusing
                          ? AppTheme.accent.withValues(alpha: 0.5)
                          : (task.isExtended ? Colors.orange.withValues(alpha: 0.3) : AppTheme.borderEmpty)),
                  width: isFocusing ? 2.0 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (task.isCompleted) {
                        _showUnmarkHint(context);
                      } else {
                        _completeTaskWithUndo(context, provider, task);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                      child: AnimatedScale(
                        scale: task.isCompleted ? 1.0 : 0.92,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: task.isCompleted ? AppTheme.success : Colors.transparent,
                            border: Border.all(
                              color: task.isCompleted
                                  ? AppTheme.success
                                  : (task.isExtended ? Colors.orange : AppTheme.mutedText),
                              width: 1.5,
                            ),
                          ),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(end: task.isCompleted ? 1.0 : 0.0),
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              // easeOutBack overshoots beyond [0,1]; clamp so
                              // Opacity's assertion (0..1) is never violated.
                              final a = value.clamp(0.0, 1.0);
                              return Opacity(
                                opacity: a,
                                child: Transform.scale(scale: value, child: child),
                              );
                            },
                            child: const Icon(Icons.check, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            color: task.isCompleted ? AppTheme.mutedText : Colors.white,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (isFocusing)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: pomo.isPaused ? Colors.orange : AppTheme.accent,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  pomo.isPaused ? 'PAUSED' : 'FOCUSING',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: pomo.isPaused ? Colors.orange : AppTheme.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!isFocusing && task.isExtended && !task.isCompleted)
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 12, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                _getRemainingTime(task),
                                style: GoogleFonts.dmSans(fontSize: 11, color: Colors.orange),
                              ),
                            ],
                          ),
                        if (task.recurrence != TaskRecurrence.none && !task.isCompleted)
                          Row(
                            children: [
                              const Icon(Icons.repeat, size: 12, color: AppTheme.accent),
                              const SizedBox(width: 4),
                              Text(
                                _getRecurrenceLabel(task.recurrence),
                                style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.accent),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (isFocusing)
                    GestureDetector(
                      onTap: () => _navigateToFocus(context, task),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 2.5,
                                  backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation(
                                    pomo.isPaused ? Colors.orange : AppTheme.accent,
                                  ),
                                ),
                              ),
                              Icon(
                                pomo.isPaused ? Icons.pause : Icons.fiber_manual_record,
                                size: 10,
                                color: pomo.isPaused ? Colors.orange : AppTheme.accent,
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: pomo.isPaused ? Colors.orange : AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 16, color: AppTheme.mutedText),
                        ],
                      ),
                    )
                  else if (task.isCompleted)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.success.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 12, color: AppTheme.success),
                              const SizedBox(width: 4),
                              Text(
                                'Done',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, size: 16, color: AppTheme.mutedText),
                      ],
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.timer_outlined, color: AppTheme.mutedText, size: 20),
                      onPressed: () => _navigateToFocus(context, task),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptySlot(int index, BuildContext context, TaskProvider provider) {
    final isExtendedSlot = index >= 3;
    return GestureDetector(
      onTap: () => isExtendedSlot && provider.canExtendTask
          ? _showRewardedAdForExtension(context, provider)
          : _showAddTaskDialog(context, provider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExtendedSlot ? Colors.orange.withValues(alpha: 0.2) : AppTheme.borderEmpty,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isExtendedSlot ? Colors.orange.withValues(alpha: 0.3) : AppTheme.borderEmpty,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isExtendedSlot ? 'Add an extra task...' : 'What matters today?',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: isExtendedSlot ? Colors.orange.withValues(alpha: 0.5) : AppTheme.placeholderText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to focus screen, with confirmation if another task has an active timer.
  Future<void> _navigateToFocus(BuildContext context, Task task) async {
    final taskId = task.id ?? 0;
    final pomo = Provider.of<PomodoroProvider>(context, listen: false);

    // If there's an active session on a DIFFERENT task, ask before switching
    if (pomo.hasActiveSession && pomo.taskId != taskId) {
      final shouldSwitch = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Switch focus?',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          content: Text(
            'You\'re focusing on "${pomo.taskTitle}". Stop that timer and switch to "${task.title}"?',
            style: GoogleFonts.dmSans(color: AppTheme.mutedText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Switch', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (shouldSwitch != true || !context.mounted) return;
      await pomo.stopAndSwitch(taskId, task.title);
    } else if (!pomo.hasActiveSession || pomo.taskId != taskId) {
      await pomo.configure(taskId, task.title);
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FocusScreen(
          taskId: taskId,
          taskTitle: task.title,
          isCompleted: task.isCompleted,
        ),
      ),
    );
  }

  Widget _buildAddButton(TaskProvider provider, BuildContext context) {
    List<Widget> children = [];

    if (provider.isPerfectDay) {
      final milestone = StreakMilestones.getMilestoneForDays(provider.streak);
      final isMilestone = provider.streak >= 3 && StreakMilestones.isMilestoneDay(provider.streak);
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AllDoneAnimation(
            streak: provider.streak,
            isMilestone: isMilestone,
            milestoneEmoji: milestone?.emoji,
            milestoneTitle: milestone?.title,
            milestoneMessage: milestone?.message,
          ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
        ),
      );
    }

    if (!provider.canAddTask) {
      children.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderEmpty),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 18, color: AppTheme.mutedText),
              const SizedBox(width: 8),
              Text('Daily limit reached (5 tasks)', style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
            ],
          ),
        ),
      );
    } else if (provider.canExtendTask && provider.todayTasks.length >= 3) {
      final adReady = AdService().isRewardedReady;
      children.add(
        GestureDetector(
          onTap: () => _showRewardedAdForExtension(context, provider),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: adReady ? Colors.orange : AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(adReady ? Icons.play_circle_outline : Icons.hourglass_empty, size: 18, color: adReady ? Colors.white : AppTheme.mutedText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    adReady ? 'Watch ad to add extra task (${2 - provider.todayExtensionUsed} left)' : 'Preparing ad...',
                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: adReady ? Colors.white : AppTheme.mutedText),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final remainingRegular = 3 - provider.todayTasks.where((t) => !t.isExtended).length;
      final isFirstTask = provider.todayTasks.isEmpty;
      
      children.add(
        GestureDetector(
          onTap: () => _showAddTaskDialog(context, provider),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  isFirstTask ? 'Add your first task' : (remainingRegular > 0 ? 'Add Task ($remainingRegular left)' : 'Add Task'),
                  style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  void _showStreakDashboard(BuildContext context, TaskProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StreakDashboard(
        provider: provider,
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showMilestoneCelebration(int days) {
    final milestone = StreakMilestones.getExactMilestone(days);
    if (milestone == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(milestone.emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Milestone Reached!',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$days-Day Streak',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getStreakColor(days),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  milestone.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppTheme.mutedText,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"${milestone.title}"',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.getStreakColor(days).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.getStreakColor(days).withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Keep Going!',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getStreakColor(days),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRewardedAdForExtension(BuildContext context, TaskProvider provider) {
    if (_rewardedFlowActive) return;
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
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
            ),
            const SizedBox(width: 16),
            Text('Loading ad...', style: GoogleFonts.dmSans(color: Colors.white)),
          ],
        ),
      ),
    );

    AdService().showRewardedAd().then((earned) async {
      if (_rewardedFlowActive && context.mounted) Navigator.pop(context);
      _rewardedFlowActive = false;
      if (!context.mounted) return;

      if (earned) {
        provider.grantExtensionSlot();
        _showAddTaskDialog(context, provider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.customSnackBar(
            message: 'Ad closed before completing. Extra task not granted.',
            context: context,
            icon: Icons.info_outline,
            leftBarColor: Colors.orangeAccent,
          ),
        );
      }
    });
  }

  static const _counterStyle = TextStyle(fontSize: 12, color: AppTheme.mutedText);
  static const _counterWarnStyle = TextStyle(fontSize: 12, color: Colors.orange);

  void _showAddTaskDialog(BuildContext context, TaskProvider provider) {
    final isExtension = provider.todayTasks.length >= 3;
    final controller = TextEditingController();
    TaskRecurrence selectedRecurrence = TaskRecurrence.none;
    List<int> selectedDays = [];
    bool showSpecificDays = false;

    final accentColor = isExtension ? Colors.orange : AppTheme.accent;

    final focusNode = FocusNode();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (focusNode.context != null) {
            focusNode.requestFocus();
          }
        });
        return StatefulBuilder(
          builder: (ctx, setDialogState) => Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              bottom: bottomInset + 24,
              left: 24, right: 24, top: 16,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
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
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isExtension ? Icons.timer_outlined : Icons.edit_note,
                          color: accentColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        isExtension ? 'Extra Task' : 'New Task',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isExtension) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Deadline: end of today. Extended tasks are for overflow, not replacement.',
                              style: GoogleFonts.dmSans(fontSize: 13, color: Colors.orange, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  TextField(
                    focusNode: focusNode,
                    controller: controller,
                    style: GoogleFonts.dmSans(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'What do you need to do?',
                      hintStyle: GoogleFonts.dmSans(color: AppTheme.placeholderText, fontSize: 16),
                      filled: true,
                      fillColor: AppTheme.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: accentColor, width: 1.5),
                      ),
                    ),
                    maxLength: 120,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) => Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$currentLength/$maxLength',
                        style: currentLength > 100 ? _counterWarnStyle : _counterStyle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Repeat', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.mutedText)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildRecurrenceChip(ctx, TaskRecurrence.none, 'None', selectedRecurrence, (v) {
                        setDialogState(() {
                          selectedRecurrence = v;
                          showSpecificDays = false;
                        });
                      }, isExtension),
                      _buildRecurrenceChip(ctx, TaskRecurrence.daily, 'Daily', selectedRecurrence, (v) {
                        setDialogState(() {
                          selectedRecurrence = v;
                          showSpecificDays = false;
                        });
                      }, isExtension),
                      _buildRecurrenceChip(ctx, TaskRecurrence.weekdays, 'Weekdays', selectedRecurrence, (v) {
                        setDialogState(() {
                          selectedRecurrence = v;
                          showSpecificDays = false;
                        });
                      }, isExtension),
                      _buildRecurrenceChip(ctx, TaskRecurrence.weekends, 'Weekends', selectedRecurrence, (v) {
                        setDialogState(() {
                          selectedRecurrence = v;
                          showSpecificDays = false;
                        });
                      }, isExtension),
                      _buildRecurrenceChip(ctx, TaskRecurrence.specificDays, 'Custom', selectedRecurrence, (v) {
                        setDialogState(() {
                          selectedRecurrence = v;
                          showSpecificDays = true;
                        });
                      }, isExtension),
                    ],
                  ),
                  if (showSpecificDays) ...[
                    const SizedBox(height: 16),
                    Text('Which days?', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.mutedText)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: List.generate(7, (index) {
                        final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final sel = selectedDays.contains(index + 1);
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              if (sel) {
                                selectedDays.remove(index + 1);
                              } else {
                                selectedDays.add(index + 1);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: sel ? accentColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sel ? accentColor : AppTheme.borderEmpty,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                dayLabels[index],
                                style: GoogleFonts.dmSans(
                                  color: sel ? Colors.white : AppTheme.mutedText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          provider.addTask(
                            controller.text.trim(),
                            isExtended: isExtension,
                            recurrence: selectedRecurrence,
                            recurrenceDays: selectedRecurrence == TaskRecurrence.specificDays ? selectedDays : null,
                          );
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        isExtension ? 'Add Extra Task' : 'Add Task',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecurrenceChip(BuildContext context, TaskRecurrence value, String label,
      TaskRecurrence selected, void Function(TaskRecurrence) onSelected, bool isExtension) {
    final active = selected == value;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? (isExtension ? Colors.orange.withValues(alpha: 0.2) : AppTheme.accent.withValues(alpha: 0.2))
              : AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? (isExtension ? Colors.orange : AppTheme.accent)
                : AppTheme.borderEmpty,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: active ? (isExtension ? Colors.orange : AppTheme.accent) : AppTheme.mutedText,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _getRecurrenceLabel(TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.daily:
        return 'Daily';
      case TaskRecurrence.weekdays:
        return 'Weekdays';
      case TaskRecurrence.weekends:
        return 'Weekends';
      case TaskRecurrence.specificDays:
        return 'Custom';
      default:
        return '';
    }
  }

  String _getRemainingTime(Task task) {
    if (task.deadline == null) return 'End of today';
    final diff = task.deadline!.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m left';
    }
    return '${diff.inMinutes}m left';
  }

  Future<void> _completeTaskWithUndo(BuildContext context, TaskProvider provider, Task task) async {
    if (task.isCompleted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    await provider.toggleTask(task);
    if (!mounted || !context.mounted) return;
    HapticFeedback.mediumImpact();

    messenger.showSnackBar(
      AppTheme.customSnackBar(
        context: context,
        message: 'Task complete ✓',
        icon: Icons.check_circle,
        leftBarColor: AppTheme.success,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppTheme.accent,
          onPressed: () {
            messenger.clearSnackBars();
            provider.toggleTask(task);
          },
        ),
      ),
    );

    if (context.mounted) {
      await RatePromptService().tryShowIfNeeded(context);
    }
  }

  void _showUnmarkHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppTheme.customSnackBar(
        message: 'To unmark a completed task, go to History.',
        context: context,
        icon: Icons.history,
        leftBarColor: Colors.orangeAccent,
      ),
    );
  }
}