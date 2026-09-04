import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/mitzy_assets.dart';
import '../core/winter_arc.dart';
import '../providers/task_provider.dart';
import 'mitzy_avatar.dart';

/// The flagship Winter Arc campaign card for the Home screen.
///
/// Shows only while the arc is in season (remote-kill via
/// `seasonal.winter_arc.enabled`): day counter, locked-in days, arc
/// progress, a rotating daily motivation line, and the floating seasonal
/// Mitzy. Tapping opens a detail sheet with the full arc breakdown.
class WinterArcCard extends StatefulWidget {
  const WinterArcCard({super.key});

  @override
  State<WinterArcCard> createState() => _WinterArcCardState();
}

class _WinterArcCardState extends State<WinterArcCard> {
  bool _isWinter = false;

  @override
  void initState() {
    super.initState();
    _isWinter = MitzyAssets.isWinterActive(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    // Hidden entirely out of season, or when the campaign is disabled.
    if (!WinterArc.enabled) return const SizedBox.shrink();
    if (!_isWinter) return const SizedBox.shrink();

    final now = DateTime.now();
    final provider = context.watch<TaskProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: GestureDetector(
        onTap: () => _showArcSheet(context, now, provider),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF16222E).withValues(alpha: 0.85),
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
              _buildHeader(now),
              const SizedBox(height: 10),
              _buildProgress(now, provider),
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
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DateTime now) {
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
            Text(
              '$lockedIn days locked in 🔒',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
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
    );
  }
}

/// Full-arc breakdown bottom sheet.
class _WinterArcSheet extends StatelessWidget {
  const _WinterArcSheet({required this.now, required this.provider});

  final DateTime now;
  final TaskProvider provider;

  @override
  Widget build(BuildContext context) {
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
                        Text(
                          'Winter Arc ${now.year}-${(now.year + 1) % 100}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
                    Text(
                      'Your Winter Arc contract',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
              if (nextMilestone != null) ...[
                const SizedBox(height: 12),
                Text(
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatGrid({
    required int lockedIn,
    required int total,
    required int remaining,
    required int currentStreak,
  }) {
    Widget stat(String label, String value, Color color) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
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
          child: stat('Days locked in', '$lockedIn', const Color(0xFF80D8FF)),
        ),
        const SizedBox(width: 10),
        Expanded(child: stat('Current streak', '$currentStreak', AppTheme.accent)),
        const SizedBox(width: 10),
        Expanded(
          child: stat(
            'Arc completion',
            '${((lockedIn / total) * 100).toStringAsFixed(0)}%',
            AppTheme.success,
          ),
        ),
      ],
    );
  }
}
