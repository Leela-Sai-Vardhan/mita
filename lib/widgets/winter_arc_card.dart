import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/arc_routines.dart';
import '../core/theme.dart';
import '../core/mitzy_assets.dart';
import '../core/winter_arc.dart';
import '../core/quick_picks.dart';
import '../providers/task_provider.dart';
import 'arc_contract_sheet.dart';
import 'mitzy_avatar.dart';
import 'rewarded_add_flow.dart';
import 'snowfall_effect.dart';

/// The flagship Winter Arc campaign card for the Home screen.
///
/// Shows only while the arc is in season (remote-kill via
/// `seasonal.winter_arc.enabled`): day counter, locked-in days, arc
/// progress, a rotating daily motivation line, gentle snowfall, and the
/// floating seasonal Mitzy. Tapping opens a detail sheet with the full
/// arc breakdown.
class WinterArcCard extends StatefulWidget {
  const WinterArcCard({super.key});

  @override
  State<WinterArcCard> createState() => _WinterArcCardState();
}

class _WinterArcCardState extends State<WinterArcCard> {
  bool _isWinter = false;
  bool _expanded = false;
  List<ArcRoutine>? _contract;

  @override
  void initState() {
    super.initState();
    _isWinter = MitzyAssets.isWinterActive(DateTime.now());
    _loadContract();
  }

  Future<void> _loadContract() async {
    final now = DateTime.now();
    final contract = await ArcRoutines.loadContract(now);
    if (!mounted) return;
    setState(() => _contract = contract);
  }

  Future<void> _addRoutineToToday(String title) async {
    final provider = context.read<TaskProvider>();
    // Same gate as the Home screen: tasks 4-5 require the rewarded ad.
    final added = await addTaskWithRewardedGate(context, provider, title);
    if (added) await _loadContract();
  }

  @override
  Widget build(BuildContext context) {
    // Hidden entirely out of season, or when the campaign is disabled.
    if (!WinterArc.enabled) return const SizedBox.shrink();
    if (!_isWinter) return const SizedBox.shrink();

    final now = DateTime.now();
    final provider = context.watch<TaskProvider>();
    // Pure recompute on every provider change so today's adherence is live.
    final contractToday = ArcRoutines.contractToday(
      _contract,
      provider.todayTasks
          .where((t) => t.isCompleted)
          .map((t) => t.title)
          .toList(),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: GestureDetector(
        // Tap opens the arc detail sheet; the chevron expands the card.
        onTap: () => _showArcSheet(context, now, provider),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Card background with frost gradient.
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF16222E).withValues(alpha: 0.9),
                      AppTheme.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF80D8FF).withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(now, provider),
                    const SizedBox(height: 10),
                    _buildProgress(now, provider),
                    if (_expanded) ...[
                      if (_contract != null && _contract!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildContractRow(provider, contractToday),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        WinterArc.dailyMessage(now),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          height: 1.45,
                          color: AppTheme.mutedText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Gentle snowfall drifting over the card.
              const Positioned.fill(
                child: IgnorePointer(
                  child: SnowfallEffect(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The contract row: each non-negotiable with its today-state. Tapping a
  /// pending one adds it as today's task (within the 5/day budget);
  /// tapping the header opens the contract picker.
  Widget _buildContractRow(TaskProvider provider, ArcContractToday today) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              today.allDone ? Icons.task_alt : Icons.lock_outline,
              size: 14,
              color: today.allDone
                  ? AppTheme.success
                  : const Color(0xFF80D8FF),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                today.allDone
                    ? 'Contract locked in today ✓'
                    : 'Contract ${today.doneCount}/${today.totalCount} today',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: today.allDone ? AppTheme.success : Colors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _editContract(),
              child: Text(
                'Edit',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF80D8FF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final routine in today.routines)
              GestureDetector(
                onTap: today.isDone(routine)
                    ? null
                    : () => _addRoutineToToday(routine.title),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: today.isDone(routine)
                        ? AppTheme.success.withValues(alpha: 0.12)
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: today.isDone(routine)
                          ? AppTheme.success.withValues(alpha: 0.4)
                          : const Color(0xFF80D8FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        today.isDone(routine)
                            ? Icons.check
                            : Icons.add,
                        size: 12,
                        color: today.isDone(routine)
                            ? AppTheme.success
                            : const Color(0xFF80D8FF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        routine.title,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color:
                              today.isDone(routine) ? Colors.white : AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _editContract() async {
    final initial = _contract?.map((r) => r.title).toList();
    final result = await ArcContractSheet.show(context, initialSelection: initial);
    if (result != null) await _loadContract();
  }

  Widget _buildHeader(DateTime now, TaskProvider provider) {
    final phase = WinterArc.phase(now);
    return Row(
      children: [
        const MitzyAvatar(width: 44, height: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.ac_unit,
                    size: 14,
                    color: Color(0xFF80D8FF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'WINTER ARC',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: const Color(0xFF80D8FF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF80D8FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      WinterArc.phaseLabel(phase),
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF80D8FF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Day ${WinterArc.dayOfArc(now)} of ${WinterArc.totalDays(now)}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Chevron: expands the compact card in place (rotates when open).
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(
                Icons.expand_more,
                size: 22,
                color: Color(0xFF80D8FF),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgress(DateTime now, TaskProvider provider) {
    final lockedIn = WinterArc.lockedInDays(provider.streakHistory, now);
    final nextMilestone = WinterArc.nextLockInMilestone(lockedIn);
    final progress = lockedIn > 0 && nextMilestone != null
        ? (lockedIn / nextMilestone).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock,
                  size: 14,
                  color: Color(0xFF80D8FF),
                ),
                const SizedBox(width: 4),
                Text(
                  '$lockedIn days locked in',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Text(
              nextMilestone != null
                  ? '${nextMilestone - lockedIn} to next badge'
                  : 'Arc complete 🏆',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF80D8FF), Color(0xFF69F0AE)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showArcSheet(BuildContext context, DateTime now, TaskProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _WinterArcSheet(now: now, provider: provider),
    ).then((_) {
      // The contract may have been created/edited inside the sheet —
      // reload it so the card's contract row reflects it immediately.
      if (mounted) _loadContract();
    });
  }
}

/// Full-arc breakdown bottom sheet.
class _WinterArcSheet extends StatefulWidget {
  const _WinterArcSheet({required this.now, required this.provider});

  final DateTime now;
  final TaskProvider provider;

  @override
  State<_WinterArcSheet> createState() => _WinterArcSheetState();
}

class _WinterArcSheetState extends State<_WinterArcSheet> {
  Future<List<ArcRoutine>?>? _contractFuture;

  @override
  void initState() {
    super.initState();
    _contractFuture = ArcRoutines.loadContract(widget.now);
  }

  /// Reloads the contract after it changes (picker closed with a save).
  void _refreshContract() {
    setState(() {
      _contractFuture = ArcRoutines.loadContract(widget.now);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.now;
    final provider = widget.provider;
    final lockedIn = WinterArc.lockedInDays(provider.streakHistory, now);
    final total = WinterArc.totalDays(now);
    final remaining = WinterArc.daysRemaining(now);
    final day = WinterArc.dayOfArc(now);
    final nextMilestone = WinterArc.nextLockInMilestone(lockedIn);
    final phase = WinterArc.phase(now);
    final currentStreak = provider.streak;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  const MitzyAvatar(width: 64, height: 64),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.ac_unit,
                              size: 18,
                              color: Color(0xFF80D8FF),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Winter Arc ${now.year}-${(now.year + 1) % 100}',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${WinterArc.phaseLabel(phase)} · Day $day of $total · $remaining days left',
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
              const SizedBox(height: 20),
              _buildStatGrid(
                lockedIn: lockedIn,
                total: total,
                remaining: remaining,
                currentStreak: currentStreak,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.military_tech,
                          size: 16,
                          color: Color(0xFF69F0AE),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Your Winter Arc contract',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Three tasks. One day. No zero days.\n'
                      'Finish every day between September and February, '
                      'and arrive in spring ahead of everyone who waited '
                      'for January.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppTheme.mutedText,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildContractSection(context),
              if (nextMilestone != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 14,
                      color: Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        lockedIn == 0
                            ? 'First locked-in day unlocks the 7-day badge.'
                            : 'Next badge at $nextMilestone locked-in days — '
                                '${nextMilestone - lockedIn} to go.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFF80D8FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Contract + suggestions block for the arc sheet. The contract loads
  /// async (SharedPreferences), suggestions depend on the user's goals.
  Widget _buildContractSection(BuildContext context) {
    final now = widget.now;
    return FutureBuilder<List<ArcRoutine>?>(
      future: _contractFuture,
      builder: (context, contractSnap) {
        final contract = contractSnap.data;
        final today = ArcRoutines.contractToday(
          contract,
          widget.provider.todayTasks
              .where((t) => t.isCompleted)
              .map((t) => t.title)
              .toList(),
        );
        return FutureBuilder<List<String>>(
          future: QuickPicks.getGoalKeys(),
          builder: (context, goalsSnap) {
            final suggestions = ArcRoutines.suggestions(
              contract: contract,
              todayTitles:
                  widget.provider.todayTasks.map((t) => t.title).toList(),
              goalKeys: goalsSnap.data ?? const [],
              now: now,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock,
                      size: 16,
                      color: Color(0xFF80D8FF),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        contract == null || contract.isEmpty
                            ? 'Pick your non-negotiables'
                            : 'Your non-negotiables · ${today.doneCount}/${today.totalCount} today',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ArcContractSheet.show(
                        context,
                        initialSelection:
                            contract?.map((r) => r.title).toList(),
                      ).then((saved) {
                        // Saved (non-null): reload so this section and the
                        // Home card behind both reflect the new contract.
                        if (saved != null) _refreshContract();
                      }),
                      child: Text(
                        contract == null || contract.isEmpty
                            ? 'Choose'
                            : 'Edit',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF80D8FF),
                        ),
                      ),
                    ),
                  ],
                ),
                if (contract != null && contract.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final r in contract)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: today.isDone(r)
                                ? AppTheme.success.withValues(alpha: 0.12)
                                : AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: today.isDone(r)
                                  ? AppTheme.success.withValues(alpha: 0.4)
                                  : AppTheme.borderEmpty,
                            ),
                          ),
                          child: Text(
                            '${today.isDone(r) ? '✓ ' : ''}${r.title}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: today.isDone(r)
                                  ? Colors.white
                                  : AppTheme.mutedText,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Suggested for ${ArcRoutines.currentBucket(now)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final r in suggestions)
                        GestureDetector(
                          onTap: () {
                            if (widget.provider.canAddTask) {
                              addTaskWithRewardedGate(
                                context,
                                widget.provider,
                                r.title,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF80D8FF)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add,
                                  size: 12,
                                  color: Color(0xFF80D8FF),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  r.title,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppTheme.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatGrid({
    required int lockedIn,
    required int total,
    required int remaining,
    required int currentStreak,
  }) {
    Widget stat(String label, String value, Color color, IconData icon) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: stat(
            'Days locked in',
            '$lockedIn',
            const Color(0xFF80D8FF),
            Icons.lock,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: stat(
            'Current streak',
            '$currentStreak',
            AppTheme.accent,
            Icons.local_fire_department_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: stat(
            'Arc completion',
            '${((lockedIn / total) * 100).toStringAsFixed(0)}%',
            AppTheme.success,
            Icons.emoji_events_outlined,
          ),
        ),
      ],
    );
  }
}
