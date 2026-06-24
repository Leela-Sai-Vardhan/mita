import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/streak_milestones.dart';
import '../providers/task_provider.dart';
import '../widgets/streak_ring_painter.dart';
import '../widgets/streak_calendar.dart';
import '../widgets/milestone_badge.dart';
import '../widgets/dashed_circle_painter.dart';

class StreakJourneyScreen extends StatefulWidget {
  final TaskProvider provider;

  const StreakJourneyScreen({super.key, required this.provider});

  @override
  State<StreakJourneyScreen> createState() => _StreakJourneyScreenState();
}

class _StreakJourneyScreenState extends State<StreakJourneyScreen> {
  final ScrollController _trophyScrollController = ScrollController();
  DateTime _lastHapticTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _trophyScrollController.addListener(_onTrophyScroll);
  }

  @override
  void dispose() {
    _trophyScrollController.removeListener(_onTrophyScroll);
    _trophyScrollController.dispose();
    super.dispose();
  }

  void _onTrophyScroll() {
    final now = DateTime.now();
    if (now.difference(_lastHapticTime).inMilliseconds > 150) {
      HapticFeedback.selectionClick();
      _lastHapticTime = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.provider,
      child: Consumer<TaskProvider>(
        builder: (context, provider, _) {
          final streak = provider.streak;
          final bestStreak = provider.bestStreak;
          final isFrozen = provider.isStreakFrozen;
          final currentMilestone = StreakMilestones.getMilestoneForDays(streak);
          final nextMilestone = StreakMilestones.getNextMilestone(streak);
          final progress = StreakMilestones.getProgressToNextMilestone(streak);
          final streakColor = isFrozen
              ? AppTheme.streakFreeze
              : AppTheme.getStreakColor(streak);
          const allMilestones = StreakMilestones.milestones;
          final window = _getMilestoneWindow(streak, allMilestones);
          final earnedMilestoneList = StreakMilestones.getEarnedMilestones(
            provider.earnedMilestones,
          );
          final ringSize = MediaQuery.sizeOf(context).width * 0.22;

          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              backgroundColor: AppTheme.surface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Streak Journey',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
            ),
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildHeroSection(
                          streak,
                          bestStreak,
                          isFrozen,
                          currentMilestone,
                          nextMilestone,
                          progress,
                          streakColor,
                          ringSize,
                        ),
                        const SizedBox(height: 24),
                        _buildMilestoneTimeline(
                          streak,
                          window,
                          currentMilestone,
                          nextMilestone,
                          streakColor,
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        _buildRecentActivity(provider, streak),
                        const SizedBox(height: 28),
                        _buildTrophyRoom(earnedMilestoneList),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(
    int streak,
    int bestStreak,
    bool isFrozen,
    Milestone? currentMilestone,
    Milestone? nextMilestone,
    double progress,
    Color streakColor,
    double ringSize,
  ) {
    final emoji = isFrozen ? '⏳' : '🔥';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: streakColor.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return CustomPaint(
                    painter: StatsRingPainter(
                      progress: value,
                      color: streakColor,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            emoji,
                            style: TextStyle(fontSize: ringSize * 0.28),
                          ),
                          Text(
                            streak.toString(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: ringSize * 0.28,
                              fontWeight: FontWeight.bold,
                              color: streakColor,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentMilestone?.title ?? 'Current Streak',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isFrozen
                        ? 'Complete all 3 tasks today or your streak resets!'
                        : (streak < 3
                            ? 'Complete all 3 tasks for a perfect day'
                            : (currentMilestone?.message ?? '')),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.mutedText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (nextMilestone != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: streakColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(streakColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${nextMilestone.days - streak}d',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: streakColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${nextMilestone.days - streak} more days to "${nextMilestone.title}"',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.emoji_events,
                size: 14, color: AppTheme.streakMilestone),
            const SizedBox(width: 4),
            Text(
              'Best: $bestStreak days',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppTheme.streakMilestone,
              ),
            ),
            if (bestStreak > streak) ...[
              const SizedBox(width: 6),
              Text(
                '(${bestStreak - streak} behind)',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
            const Spacer(),
            if (isFrozen)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_bottom,
                      size: 14, color: AppTheme.streakFreeze),
                  const SizedBox(width: 4),
                  Text(
                    'At Risk',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.streakFreeze,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMilestoneTimeline(
    int streak,
    List<Milestone> window,
    Milestone? currentMilestone,
    Milestone? nextMilestone,
    Color streakColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MILESTONE JOURNEY',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.mutedText,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.white,
                Colors.white.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.8, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: Column(
            children: List.generate(window.length, (i) {
              final m = window[i];
              final isEarned = streak >= m.days &&
                  (currentMilestone == null ||
                      m.days != currentMilestone.days);
              final isCurrent =
                  currentMilestone != null && m.days == currentMilestone.days;
              final isNext =
                  nextMilestone != null && m.days == nextMilestone.days;
              return _buildMilestoneNode(
                milestone: m,
                isEarned: isEarned,
                isCurrent: isCurrent,
                isNext: isNext,
                isLast: i == window.length - 1,
                streak: streak,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(TaskProvider provider, int streak) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LAST 14 DAYS',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedText,
          ),
        ),
        const SizedBox(height: 10),
        StreakCalendar(
          streak: streak,
          perfectDayDates: provider.streakHistory,
          daysToShow: 14,
        ),
      ],
    );
  }

  Widget _buildTrophyRoom(List<Milestone> earned) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EARNED',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.mutedText,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        if (earned.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.borderEmpty.withValues(alpha: 0.5),
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Your display case is waiting.',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.mutedText,
                ),
              ),
            ),
          )
        else
          SingleChildScrollView(
            controller: _trophyScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: earned
                  .map((m) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: MilestoneBadge(
                          milestone: m,
                          earned: true,
                          size: 44,
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  List<Milestone> _getMilestoneWindow(
      int streak, List<Milestone> all) {
    if (streak < 3) {
      return all.take(6).toList();
    }
    final currentIdx = all.lastIndexWhere((m) => streak >= m.days);
    if (currentIdx < 0) return all.take(6).toList();
    final start = (currentIdx - 2).clamp(0, all.length - 1);
    final end = (currentIdx + 5).clamp(start, all.length - 1);
    return all.sublist(start, end + 1);
  }

  Widget _buildMilestoneNode({
    required Milestone milestone,
    required bool isEarned,
    required bool isCurrent,
    required bool isNext,
    required bool isLast,
    required int streak,
  }) {
    final Color nodeColor;
    final Color textColor;

    if (isCurrent) {
      nodeColor = AppTheme.getStreakColor(streak);
      textColor = Colors.white;
    } else if (isEarned) {
      nodeColor = AppTheme.success;
      textColor = Colors.white.withValues(alpha: 0.8);
    } else if (isNext) {
      nodeColor = AppTheme.accent;
      textColor = Colors.white;
    } else {
      nodeColor = AppTheme.mutedText.withValues(alpha: 0.3);
      textColor = AppTheme.mutedText.withValues(alpha: 0.5);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (isCurrent || isEarned || isNext)
                  Container(
                    width: isCurrent ? 14 : 10,
                    height: isCurrent ? 14 : 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent ? nodeColor : null,
                      border: isCurrent
                          ? Border.all(color: nodeColor, width: 2)
                          : Border.all(color: nodeColor, width: 1.5),
                    ),
                  )
                else
                  CustomPaint(
                    size: const Size(10, 10),
                    painter: DashedCirclePainter(
                      color: nodeColor,
                      strokeWidth: 1.5,
                    ),
                  ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: nodeColor.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Row(
                children: [
                  Text(milestone.emoji,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                milestone.title,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: isCurrent || isNext
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: nodeColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'YOU',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: nodeColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (isNext)
                          Text(
                            '${milestone.days - streak} days to go',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: AppTheme.accent.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${milestone.days}d',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textColor.withValues(
                          alpha: isCurrent || isNext ? 1.0 : 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
