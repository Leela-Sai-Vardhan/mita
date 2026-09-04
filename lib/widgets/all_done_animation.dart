import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';

/// Animated celebration card shown when all tasks are completed.
/// Replaces the static "All done — great day!" text with a lively animation.
class AllDoneAnimation extends StatefulWidget {
  final int streak;
  final bool isMilestone;
  final String? milestoneEmoji;
  final String? milestoneTitle;
  final String? milestoneMessage;

  const AllDoneAnimation({
    super.key,
    required this.streak,
    this.isMilestone = false,
    this.milestoneEmoji,
    this.milestoneTitle,
    this.milestoneMessage,
  });

  @override
  State<AllDoneAnimation> createState() => _AllDoneAnimationState();
}

class _AllDoneAnimationState extends State<AllDoneAnimation>
    with TickerProviderStateMixin {
  static const _dismissedKeyPrefix = 'celebration_dismissed_';

  late final AnimationController _mainController;
  late final AnimationController _sparkleController;
  late final AnimationController _glowController;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadDismissedToday();
  }

  /// Loads whether the user already dismissed today's celebration, so
  /// navigating back to Home doesn't re-trigger it. Persisted per-day:
  /// tomorrow's perfect day gets a fresh celebration.
  Future<void> _loadDismissedToday() async {
    final today = DateTime.now();
    final key =
        '$_dismissedKeyPrefix${today.year}-${today.month}-${today.day}';
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(key) ?? false;
    if (dismissed && mounted) {
      setState(() => _dismissed = true);
    }
  }

  /// Hides the celebration until the next perfect day. Persisted for the
  /// day so tab switches and app restarts don't re-show it.
  void _dismiss() {
    _sparkleController.stop();
    _glowController.stop();
    setState(() => _dismissed = true);
    final today = DateTime.now();
    final key =
        '$_dismissedKeyPrefix${today.year}-${today.month}-${today.day}';
    SharedPreferences.getInstance().then((prefs) => prefs.setBool(key, true));
  }

  @override
  void dispose() {
    _mainController.dispose();
    _sparkleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dismissed: render nothing (the whole card goes away) until the next
    // perfect day re-creates this widget fresh.
    if (_dismissed) return const SizedBox.shrink();

    final color = widget.isMilestone
        ? AppTheme.getStreakColor(widget.streak)
        : AppTheme.success;

    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _sparkleController, _glowController]),
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.12 + _glowController.value * 0.06),
                AppTheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12 + _glowController.value * 0.08),
                blurRadius: 20 + _glowController.value * 8,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Sparkle particles
              ...List.generate(8, (i) {
                final angle = (i / 8) * 2 * pi + _sparkleController.value * 2 * pi;
                final distance = 50.0 + (i % 3) * 15.0;
                final sparkleOpacity = (sin(_sparkleController.value * 2 * pi + i) + 1) / 2;
                return Positioned(
                  left: 28 + cos(angle) * distance * _mainController.value,
                  top: 28 + sin(angle) * distance * _mainController.value,
                  child: Opacity(
                    opacity: sparkleOpacity * 0.7 * _mainController.value,
                    child: Container(
                      width: 4 + (i % 2) * 2,
                      height: 4 + (i % 2) * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i % 2 == 0 ? color : AppTheme.streakMilestone,
                      ),
                    ),
                  ),
                );
              }),
              // Dismiss button (top-right).
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: _dismiss,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.background.withValues(alpha: 0.8),
                        border: Border.all(
                          color: AppTheme.mutedText.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  // Celebration animation (Lottie: check + confetti, 2x, plays
                  // once). Rendered in a fixed 60x60 slot via OverflowBox so
                  // the oversized 144px art bursts out of the card without
                  // changing the original layout.
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Transform.scale(
                      scale: Curves.elasticOut.transform(
                        _mainController.value,
                      ),
                      child: OverflowBox(
                        maxWidth: 144,
                        maxHeight: 144,
                        child: widget.isMilestone
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  Lottie.asset(
                                    'assets/animations/all_done_celebration.lottie',
                                    width: 144,
                                    height: 144,
                                    fit: BoxFit.contain,
                                  ),
                                  Text(
                                    widget.milestoneEmoji ?? '🎉',
                                    style: const TextStyle(fontSize: 40),
                                  ),
                                ],
                              )
                            : Lottie.asset(
                                'assets/animations/all_done_celebration.lottie',
                                width: 144,
                                height: 144,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isMilestone
                              ? 'Milestone Achieved!'
                              : 'All done — great day!',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ).animate().fadeIn(
                              delay: 300.ms,
                              duration: 500.ms,
                            ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isMilestone && widget.milestoneTitle != null
                              ? '"${widget.milestoneTitle}" — ${widget.streak} days!'
                              : 'Streak: ${widget.streak} days',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppTheme.mutedText,
                          ),
                        ).animate().fadeIn(
                              delay: 500.ms,
                              duration: 500.ms,
                            ),
                        if (widget.isMilestone && widget.milestoneMessage != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.milestoneMessage!,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: color.withValues(alpha: 0.8),
                              height: 1.3,
                            ),
                          ).animate().fadeIn(
                                delay: 700.ms,
                                duration: 500.ms,
                              ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A small "done" chip badge with a subtle pulse, used in the task card right side.
class DoneBadge extends StatefulWidget {
  const DoneBadge({super.key});

  @override
  State<DoneBadge> createState() => _DoneBadgeState();
}

class _DoneBadgeState extends State<DoneBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.success.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 12, color: AppTheme.success),
            SizedBox(width: 4),
            Text(
              'Done',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppTheme.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
