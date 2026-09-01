import 'dart:async';
import 'dart:math' show pi;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../data/database_helper.dart';
import '../data/models/focus_session_model.dart';
import '../providers/pomodoro_provider.dart';
import '../services/pomodoro_timer_service.dart';
import '../services/ambient_sound_service.dart';
import '../services/rate_prompt_service.dart';

class FocusScreen extends StatefulWidget {
  final int taskId;
  final String taskTitle;
  final bool isCompleted;

  const FocusScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
    this.isCompleted = false,
  });

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final AmbientSoundService _ambient = AmbientSoundService();
  bool _hapticsEnabled = true;
  int _selectedDuration = 1500;
  StreamSubscription<int>? _tickSubscription;
  StreamSubscription<TimerState>? _stateSubscription;
  List<FocusSession> _recentSessions = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSessionHistory();
      final provider = context.read<PomodoroProvider>();

      // Subscribe to tick stream for haptic feedback
      _tickSubscription = provider.timer.tickStream.listen((tick) {
        if (_hapticsEnabled && provider.isRunning) {
          HapticFeedback.selectionClick();
        }
      });

      // Subscribe to state changes for session completion vibration
      _stateSubscription = provider.timer.stateStream.listen((state) {
        if (state == TimerState.breakMode) {
          HapticFeedback.vibrate();
          Future.delayed(const Duration(milliseconds: 300), () {
            HapticFeedback.vibrate();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tickSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSessionHistory() async {
    final provider = context.read<PomodoroProvider>();
    final sessions = await DatabaseHelper.instance.getFocusSessions(
      taskId: provider.taskId,
      limit: 10,
    );
    if (mounted) {
      setState(() => _recentSessions = sessions);
    }
  }

  String _formatSessionDuration(int sec) {
    if (sec >= 3600) {
      return '${sec ~/ 3600}h ${(sec % 3600) ~/ 60}m';
    }
    return '${sec ~/ 60}m ${sec % 60}s';
  }

  Widget _buildSessionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PAST SESSIONS',
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: AppTheme.mutedText,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 160),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _recentSessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final session = _recentSessions[index];
              final dateStr = '${session.startedAt.month}/${session.startedAt.day} '
                  '${session.startedAt.hour.toString().padLeft(2, '0')}:${session.startedAt.minute.toString().padLeft(2, '0')}';
              final duration = _formatSessionDuration(session.elapsedSec);
              final isCompleted = session.completed;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? AppTheme.success : AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      dateStr,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      duration,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCompleted ? '✓' : '–',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: isCompleted ? AppTheme.success : AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _changeTrack(AmbientTrack track) {
    if (track == AmbientTrack.none) {
      _ambient.stop();
    } else {
      _ambient.play(track);
    }
    setState(() {});
  }

  Widget _buildDurationChip(int seconds, String label) {
    final active = _selectedDuration == seconds;
    return GestureDetector(
      onTap: widget.isCompleted ? null : () {
        final provider = context.read<PomodoroProvider>();
        setState(() {
          _selectedDuration = seconds;
        });
        if (provider.timer.state != TimerState.idle) {
          provider.timer.start(taskId: provider.taskId, durationSec: seconds);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.accent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppTheme.accent : AppTheme.borderEmpty,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: active ? AppTheme.accent : AppTheme.mutedText,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, _) {
        final isReady = provider.isReady;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF14070B),
                        Color(0xFF070D14),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -100,
                left: -100,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isReady
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppTheme.accent.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _buildHeader(provider),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          switchInCurve: Curves.easeOut,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: isReady
                              ? _buildReadyContent(provider)
                              : _buildRunningContent(provider),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(PomodoroProvider provider) {
    final isReady = provider.isReady;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
            onPressed: () async {
              if (!isReady) {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Leave Focus?',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    content: Text(
                      'Your session is still running. It will be saved as incomplete.',
                      style: GoogleFonts.dmSans(
                        color: AppTheme.mutedText,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'Stay',
                          style: GoogleFonts.dmSans(color: AppTheme.mutedText),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Leave',
                          style: GoogleFonts.dmSans(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                await provider.stop();
                await _loadSessionHistory();
              }
              _ambient.stop();
              if (mounted) Navigator.pop(context);
            },
          ),
          Text(
            'DEEP FOCUS',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildReadyContent(PomodoroProvider provider) {
    return Column(
      key: const ValueKey('ready'),
      children: [
        const Spacer(flex: 1),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Focus #${provider.sessionCount + 1}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDurationChip(900, '15 min'),
            const SizedBox(width: 8),
            _buildDurationChip(1500, '25 min'),
            const SizedBox(width: 8),
            _buildDurationChip(2700, '45 min'),
          ],
        ),
        const SizedBox(height: 24),

        Text(
          provider.taskTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Set your duration, choose a soundscape, and begin when ready.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: AppTheme.mutedText,
            height: 1.4,
          ),
        ),

        const Spacer(flex: 2),

        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: _FocusTimerArcPainter(
              progress: 0,
              isRunning: false,
              isPaused: false,
            ),
            child: Center(
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(_selectedDuration ~/ 60).toString().padLeft(2, '0')}:00',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: Colors.white54,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'READY',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const Spacer(flex: 2),

        _buildAmbientSection(),

        const SizedBox(height: 20),

        if (widget.isCompleted)
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.success.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'TASK COMPLETED',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulse = _pulseController.value;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.08 + pulse * 0.15),
                      blurRadius: 6 + pulse * 14,
                      spreadRadius: pulse * 2,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  provider.start(durationSec: _selectedDuration);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'START FOCUS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),

        GestureDetector(
          onTap: () {
            setState(() {
              _hapticsEnabled = !_hapticsEnabled;
            });
            HapticFeedback.mediumImpact();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _hapticsEnabled
                  ? AppTheme.accent.withValues(alpha: 0.08)
                  : AppTheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hapticsEnabled ? AppTheme.accent.withValues(alpha: 0.4) : AppTheme.borderEmpty,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _hapticsEnabled ? Icons.vibration : Icons.portable_wifi_off_outlined,
                  size: 16,
                  color: _hapticsEnabled ? AppTheme.accent : AppTheme.mutedText,
                ),
                const SizedBox(width: 8),
                Text(
                  'Haptic Ticks',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _hapticsEnabled ? Colors.white : AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_recentSessions.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildSessionHistory(),
        ],
        const Spacer(flex: 1),
      ],
    );
  }

  Widget _buildRunningContent(PomodoroProvider provider) {
    return Column(
      key: const ValueKey('running'),
      children: [
        const Spacer(),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Focus #${provider.sessionCount}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDurationChip(900, '15 min'),
            const SizedBox(width: 8),
            _buildDurationChip(1500, '25 min'),
            const SizedBox(width: 8),
            _buildDurationChip(2700, '45 min'),
          ],
        ),
        const SizedBox(height: 20),

        Text(
          'FOCUSING ON',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            letterSpacing: 1.5,
            color: AppTheme.mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          provider.taskTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const Spacer(),

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
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (provider.isRunning)
                        BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _FocusTimerArcPainter(
                      progress: provider.timer.progress,
                      isRunning: provider.isRunning,
                      isPaused: provider.isPaused,
                    ),
                    child: Center(
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.03),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  provider.timer.formattedTime,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: provider.isPaused
                                        ? Colors.orange.withValues(alpha: 0.1)
                                        : (provider.isRunning
                                            ? AppTheme.accent.withValues(alpha: 0.1)
                                            : Colors.white10),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    provider.isPaused
                                        ? 'PAUSED'
                                        : (provider.isRunning ? 'FOCUS' : 'READY'),
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.0,
                                      color: provider.isPaused
                                          ? Colors.orange
                                          : (provider.isRunning
                                              ? AppTheme.accent
                                              : Colors.white70),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const Spacer(),

        _buildAmbientSection(),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _hapticsEnabled = !_hapticsEnabled;
                });
                HapticFeedback.mediumImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _hapticsEnabled
                      ? AppTheme.accent.withValues(alpha: 0.08)
                      : AppTheme.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _hapticsEnabled ? AppTheme.accent.withValues(alpha: 0.4) : AppTheme.borderEmpty,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _hapticsEnabled ? Icons.vibration : Icons.portable_wifi_off_outlined,
                      size: 16,
                      color: _hapticsEnabled ? AppTheme.accent : AppTheme.mutedText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Haptic Ticks',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _hapticsEnabled ? Colors.white : AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            GestureDetector(
              onTap: () async {
                await provider.resetToReady();
                _ambient.stop();
                await _loadSessionHistory();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0x1AFF5252),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x33FF5252)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stop_rounded, size: 16, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Stop Timer',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const Spacer(),

        if (provider.isBreak) ...[
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.celebration, color: AppTheme.success, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'POMODORO COMPLETE!',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Take a short break. You earned it!',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        provider.skipBreak();
                        _ambient.stop();
                        if (mounted) {
                          await RatePromptService().tryShowIfNeeded(context);
                        }
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Continue to Tasks',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
        ]
      ],
    );
  }

  Widget _buildAmbientSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderEmpty),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AMBIENT SOUNDSCAPE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppTheme.mutedText,
                ),
              ),
              if (_ambient.isPlaying)
                Text(
                  '${(_ambient.volume * 100).toInt()}% vol',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppTheme.mutedText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSoundButton(
                track: AmbientTrack.none,
                icon: Icons.music_off_outlined,
                label: 'Mute',
              ),
              _buildSoundButton(
                track: AmbientTrack.rain,
                icon: Icons.water_drop_outlined,
                label: 'Rain',
              ),
              _buildSoundButton(
                track: AmbientTrack.forest,
                icon: Icons.park_outlined,
                label: 'Forest',
              ),
              _buildSoundButton(
                track: AmbientTrack.whiteNoise,
                icon: Icons.waves_rounded,
                label: 'Noise',
              ),
            ],
          ),
          if (_ambient.isPlaying) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.volume_down, size: 16, color: AppTheme.mutedText),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.accent,
                      inactiveTrackColor: AppTheme.borderEmpty,
                      thumbColor: Colors.white,
                      trackHeight: 3.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: _ambient.volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) {
                        _ambient.setVolume(val);
                        setState(() {});
                      },
                    ),
                  ),
                ),
                const Icon(Icons.volume_up, size: 16, color: AppTheme.mutedText),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSoundButton({
    required AmbientTrack track,
    required IconData icon,
    required String label,
  }) {
    final isActive = _ambient.currentTrack == track;
    return GestureDetector(
      onTap: () => _changeTrack(track),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.accent.withValues(alpha: 0.5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.accent : Colors.white54,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusTimerArcPainter extends CustomPainter {
  final double progress;
  final bool isRunning;
  final bool isPaused;

  _FocusTimerArcPainter({
    required this.progress,
    required this.isRunning,
    required this.isPaused,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, backgroundPaint);

    final foregroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = isPaused ? Colors.orange : AppTheme.accent;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      foregroundPaint,
    );

    if (isRunning) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = AppTheme.accent.withValues(alpha: 0.1)
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FocusTimerArcPainter old) {
    return old.progress != progress || old.isRunning != isRunning || old.isPaused != isPaused;
  }
}
