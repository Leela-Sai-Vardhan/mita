import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late final AnimationController _mainController;
  late final AnimationController _sparkleController;
  late final AnimationController _glowController;

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
              Row(
                children: [
                  // Animated checkmark circle
                  Transform.scale(
                    scale: Curves.elasticOut.transform(
                      _mainController.value,
                    ),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.15),
                        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.2 * _mainController.value),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: widget.isMilestone
                          ? Center(
                              child: Text(
                                widget.milestoneEmoji ?? '🎉',
                                style: const TextStyle(fontSize: 28),
                              ),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  size: 30,
                                  color: color,
                                ),
                                // Pulsing ring
                                Transform.scale(
                                  scale: 1.0 + _glowController.value * 0.15,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: color.withValues(
                                          alpha: 0.3 * (1 - _glowController.value),
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
