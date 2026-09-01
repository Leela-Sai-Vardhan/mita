import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/goals.dart';
import '../../core/quick_picks.dart';
import '../../providers/task_provider.dart';
import '../../services/notification_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'data/onboarding_model.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/expanding_dots.dart';
import 'widgets/pulsing_cta.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final List<TextEditingController> _taskControllers =
      List.generate(3, (_) => TextEditingController());
  final ValueNotifier<int> _filledCount = ValueNotifier(0);
  final ValueNotifier<bool> _showHint = ValueNotifier(false);
  final Set<String> _selectedGoals = {};
  int _currentPage = 0;
  bool _isNavigating = false;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      icon: const _LogoIcon(),
      titleWidget: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Mi',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
            TextSpan(
              text: 'Ta',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppTheme.mutedText,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
      subtitle: '(Micro Tasks)',
      body:
          'We limit you to three tasks per day.\nNot a constraint \u2014 a liberation.\nComplete all three for a Perfect Day.',
      extraContent: const _WireframeCircles(),
    ),
    const OnboardingPageData(
      icon: _StreakIcon(),
      title: 'Micro Tasks. Macro Results.',
      body:
          'Big ambitions are won through small, daily rituals.\nComplete your three micro tasks to protect your streak.\nYour consistency becomes your trophy.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _taskControllers) {
      c.dispose();
    }
    _filledCount.dispose();
    _showHint.dispose();
    super.dispose();
  }

  int get _totalPages => _pages.length + 2;

  bool get _isLastPage => _currentPage == _pages.length + 1;

  Future<void> _finishOnboarding() async {
    if (_isNavigating) return;
    _isNavigating = true;

    final provider = Provider.of<TaskProvider>(context, listen: false);

    await QuickPicks.saveGoals(_selectedGoals.toList());
    await QuickPicks.markGoalSelectionDone();

    for (final c in _taskControllers) {
      final t = c.text.trim();
      if (t.isNotEmpty) {
        await provider.addTask(t);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.hasSeenOnboarding, true);
    if (!mounted || !context.mounted) return;

    // Show notification permission dialog before going to home
    await _showNotificationDialog();
  }

  Future<void> _showNotificationDialog() async {
    if (!mounted || !context.mounted) return;
    final notificationService = NotificationService();
    final alreadyGranted = notificationService.isPermissionGranted;

    if (alreadyGranted) {
      // Permission already granted — just navigate
      if (!mounted || !context.mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    final enable = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: AppTheme.accent,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Stay on track',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Get a gentle reminder each evening to finish your 3 tasks before the day ends.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppTheme.mutedText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Enable Reminders',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Not now',
                style: GoogleFonts.dmSans(
                  color: AppTheme.mutedText,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (enable == true) {
      try {
        await NotificationService().requestPermission();
      } catch (e) {
        debugPrint('[Onboarding] Notification permission error: $e');
      }
    }

    if (!mounted || !context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _skip() => _finishOnboarding();

  void _next() {
    if (_isLastPage) {
      if (_filledCount.value > 0) {
        HapticFeedback.mediumImpact();
        _finishOnboarding();
      } else {
        HapticFeedback.lightImpact();
        _showHint.value = true;
      }
    } else {
      // Dismiss any open keyboard before advancing so the next page isn't
      // squeezed by the shrinking viewport (which caused overflow artifacts).
      FocusManager.instance.primaryFocus?.unfocus();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onTasksChanged(int count) {
    _filledCount.value = count;
    if (count > 0) _showHint.value = false;
  }

  void _onGoalToggled(String key) {
    setState(() {
      if (_selectedGoals.contains(key)) {
        _selectedGoals.remove(key);
      } else if (_selectedGoals.length < 3) {
        _selectedGoals.add(key);
        HapticFeedback.selectionClick();
      }
    });
  }

  List<String> _goalPool() {
    final pool = <String>[];
    for (final key in _selectedGoals) {
      final g = Goals.getByKey(key);
      if (g != null) pool.addAll(g.tasks);
    }
    return pool;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (context, _) {
                final offset = _pageController.hasClients
                    ? _pageController.page ?? 0
                    : 0.0;
                final fraction = offset / (_totalPages - 1).clamp(1, 100);
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(
                          const Color(0xFF14070B),
                          const Color(0xFF0B1414),
                          fraction,
                        )!,
                        const Color(0xFF070D14),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (context, _) {
                final offset = _pageController.hasClients
                    ? _pageController.page ?? 0
                    : 0.0;
                final fraction = offset / (_totalPages - 1).clamp(1, 100);
                return ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(
                        AppTheme.accent.withValues(alpha: 0.12),
                        Colors.amber.withValues(alpha: 0.08),
                        fraction,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!_isLastPage)
                        GestureDetector(
                          onTap: _skip,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Skip',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.mutedText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const ClampingScrollPhysics(),
                    onPageChanged: (i) {
                      // Leaving the "Name your tasks" page: dismiss any open
                      // keyboard so it doesn't linger over the next page.
                      if (i >= _pages.length + 1) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      }
                      setState(() => _currentPage = i);
                    },
                    itemCount: _totalPages,
                    itemBuilder: (context, index) {
                      if (index == _pages.length) {
                        return _NameTasksPage(
                          controllers: _taskControllers,
                          showHint: _showHint,
                          onCountChanged: _onTasksChanged,
                          pools: _goalPool(),
                        );
                      }
                      if (index == _pages.length + 1) {
                        return _GoalSelectPage(
                          selected: _selectedGoals,
                          onToggle: _onGoalToggled,
                          onSkip: _finishOnboarding,
                        );
                      }
                      final page = _pages[index];
                      return OnboardingPage(
                        icon: page.icon,
                        title: page.title,
                        titleWidget: page.titleWidget,
                        subtitle: page.subtitle,
                        body: page.body,
                        extraContent: page.extraContent,
                        index: index,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: Column(
                    children: [
                      ExpandingDots(
                        count: _totalPages,
                        activeIndex: _currentPage,
                      ),
                      const SizedBox(height: 32),
                      if (_isLastPage)
                        PulsingCta(
                          label: 'Start Your Journey',
                          onPressed: _next,
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _next();
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
                              'Next',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalSelectPage extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onSkip;

  const _GoalSelectPage({
    required this.selected,
    required this.onToggle,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(32, 0, 32, bottomInset + 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: IntrinsicHeight(
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.borderEmpty, width: 1.5),
                ),
                child: const Icon(Icons.track_changes, color: AppTheme.accent, size: 34),
              ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
              const SizedBox(height: 28),
              Text(
                'What matters to you?',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
              const SizedBox(height: 8),
              Text(
                '(Pick up to 3)',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppTheme.mutedText,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              const SizedBox(height: 20),
              Text(
                'Your picks shape the tasks Mita suggests.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppTheme.mutedText,
                  height: 1.6,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final goal in Goals.all)
                    _GoalChip(
                      goal: goal,
                      isSelected: selected.contains(goal.key),
                      onTap: () => onToggle(goal.key),
                    ),
                ],
              ),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip goals',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final Goal goal;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalChip({
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withValues(alpha: 0.15)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.accent
                : AppTheme.borderEmpty,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              goal.icon,
              size: 18,
              color: isSelected ? AppTheme.accent : AppTheme.mutedText,
            ),
            const SizedBox(width: 8),
            Text(
              goal.label,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameTasksPage extends StatefulWidget {
  final List<TextEditingController> controllers;
  final ValueNotifier<bool> showHint;
  final ValueChanged<int> onCountChanged;
  final List<String> pools;

  const _NameTasksPage({
    required this.controllers,
    required this.showHint,
    required this.onCountChanged,
    this.pools = const [],
  });

  @override
  State<_NameTasksPage> createState() => _NameTasksPageState();
}

class _NameTasksPageState extends State<_NameTasksPage> {
  int _countFilled() =>
      widget.controllers.where((c) => c.text.trim().isNotEmpty).length;

  void _handleChanged() {
    setState(() {});
    widget.onCountChanged(_countFilled());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(32, 0, 32, bottomInset + 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: IntrinsicHeight(
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.borderEmpty, width: 1.5),
                ),
                child: const Icon(Icons.edit_note, color: AppTheme.accent, size: 34),
              ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
              const SizedBox(height: 28),
              Text(
                'Name your 3 tasks',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
              const SizedBox(height: 8),
              Text(
                '(Today\u2019s first win)',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppTheme.mutedText,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              const SizedBox(height: 20),
              Text(
                'Start small. \u201cDrink water\u201d beats \u201cdrink 8 glasses\u201d.\nComplete all three for your first Perfect Day.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppTheme.mutedText,
                  height: 1.6,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
              const SizedBox(height: 28),
              Column(
                children: [
                  for (int i = 0; i < 3; i++)
                    if (i == 0 ||
                        widget.controllers[i - 1].text.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TaskInputRow(
                          index: i,
                          controller: widget.controllers[i],
                          filled:
                              widget.controllers[i].text.trim().isNotEmpty,
                          onChanged: _handleChanged,
                          pools: widget.pools,
                        ),
                      ),
                ],
              ),
              ValueListenableBuilder<bool>(
                valueListenable: widget.showHint,
                builder: (context, show, _) {
                  return AnimatedOpacity(
                    opacity: show ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      'Add at least one task, or tap Skip above.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskInputRow extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final bool filled;
  final VoidCallback onChanged;
  final List<String> pools;

  const _TaskInputRow({
    required this.index,
    required this.controller,
    required this.filled,
    required this.onChanged,
    this.pools = const [],
  });

  String _exampleHint() {
    if (pools.isNotEmpty) {
      return 'e.g. ${pools[index % pools.length]}';
    }
    return switch (index) {
      0 => 'e.g. Drink water',
      1 => 'e.g. 20 min walk',
      _ => 'e.g. Read 10 pages',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppTheme.success : Colors.transparent,
            border: Border.all(
              color: filled ? AppTheme.success : AppTheme.borderEmpty,
              width: 1.5,
            ),
          ),
          child: Text(
            '${index + 1}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : AppTheme.mutedText,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: filled
                    ? AppTheme.success.withValues(alpha: 0.4)
                    : AppTheme.borderEmpty,
              ),
            ),
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              maxLength: 120,
              style: GoogleFonts.dmSans(fontSize: 15, color: Colors.white),
              cursorColor: AppTheme.accent,
              textInputAction:
                  index < 2 ? TextInputAction.next : TextInputAction.done,
              decoration: InputDecoration(
                hintText: _exampleHint(),
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: AppTheme.placeholderText,
                ),
                counterText: '',
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoIcon extends StatelessWidget {
  const _LogoIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderEmpty, width: 1.5),
      ),
      child: Center(
        child: Text(
          '\u2299',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppTheme.accent,
          ),
        ),
      ),
    );
  }
}

class _WireframeCircles extends StatefulWidget {
  const _WireframeCircles();

  @override
  State<_WireframeCircles> createState() => _WireframeCirclesState();
}

class _WireframeCirclesState extends State<_WireframeCircles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i * 0.15;
            final value =
                (_controller.value + delay) % 1.0;
            final pulse = 0.4 + (value * 0.6);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: pulse * 0.3),
                    width: 1.5,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _StreakIcon extends StatelessWidget {
  const _StreakIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(100, 100),
            painter: _StreakRingPainter(),
          ),
          Text(
            '\u{1F525}',
            style: GoogleFonts.dmSans(fontSize: 36),
          ),
        ],
      ),
    );
  }
}

class _StreakRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.streakFire;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5,
      2.5,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
