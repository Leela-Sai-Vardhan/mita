import 'dart:math' show pi;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/pomodoro_provider.dart';
import '../services/ambient_sound_service.dart';
import 'pomodoro_ambient_toggle.dart';

class PomodoroOverlay extends StatefulWidget {
  final int taskId;
  final String taskTitle;
  const PomodoroOverlay({super.key, required this.taskId, required this.taskTitle});

  @override
  State<PomodoroOverlay> createState() => _PomodoroOverlayState();
}

class _PomodoroOverlayState extends State<PomodoroOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PomodoroProvider>().start(
        durationSec: 1500,
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.glassBackground,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppTheme.glassBorder),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0x1AFFFFFF),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () {
                              provider.stop();
                              AmbientSoundService().stop();
                              Navigator.pop(context);
                            },
                          ),
                          Text(
                            'Focus',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                          const PomodoroAmbientToggle(),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    Text(
                      widget.taskTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),

                    GestureDetector(
                      onTap: () {
                          if (provider.isRunning) {
                            provider.pause();
                          } else if (provider.isPaused) {
                            provider.resume();
                          }
                      },
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulse = provider.isRunning
                              ? 1.0 + (_pulseController.value * 0.02)
                              : 1.0;
                          return Transform.scale(
                            scale: pulse,
                            child: SizedBox(
                              width: 260,
                              height: 260,
                              child: CustomPaint(
                                painter: _TimerArcPainter(
                                  progress: provider.timer.progress,
                                  isRunning: provider.isRunning,
                                  isPaused: provider.isPaused,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        provider.timer.formattedTime,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 52,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        provider.isPaused ? 'PAUSED' : 'FOCUS',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          letterSpacing: 4,
                                          color: provider.isPaused
                                              ? Colors.orange
                                              : AppTheme.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const Spacer(flex: 1),

                    if (provider.isBreak)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.glassBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.celebration, color: AppTheme.success, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              'Pomodoro Complete!',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.success,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Take a short break. You earned it.',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                provider.skipBreak();
                                AmbientSoundService().stop();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Continue',
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimerArcPainter extends CustomPainter {
  final double progress;
  final bool isRunning;
  final bool isPaused;

  _TimerArcPainter({required this.progress, required this.isRunning, required this.isPaused});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    paint.color = AppTheme.glassBorder;
    canvas.drawCircle(center, radius, paint);

    paint.color = isPaused ? Colors.orange : AppTheme.accent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );

    if (isRunning) {
      paint.color = AppTheme.accent.withValues(alpha: 0.3);
      paint.strokeWidth = 12;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerArcPainter old) => old.progress != progress;
}
