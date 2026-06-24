import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../core/constants/storage_keys.dart';
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
    const OnboardingPageData(
      icon: _TimerIcon(),
      title: 'Focus Deeply.',
      body:
          'Single-tasking is your superpower.\nDive into your MiTa sessions with built-in\nambient soundscapes. One micro task at a time.',
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
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _pages.length - 1;

  Future<void> _finishOnboarding() async {
    if (_isNavigating) return;
    _isNavigating = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.hasSeenOnboarding, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _skip() => _finishOnboarding();

  void _next() {
    if (_isLastPage) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
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
                final fraction =
                    offset / (_pages.length - 1).clamp(1, 100);
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
                final fraction =
                    offset / (_pages.length - 1).clamp(1, 100);
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
                    onPageChanged: (i) =>
                        setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
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
                        count: _pages.length,
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

class _TimerIcon extends StatelessWidget {
  const _TimerIcon();

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
            painter: _TimerArcPainter(),
          ),
          Text(
            '25:00',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.mutedText,
              letterSpacing: -0.5,
            ),
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

class _TimerArcPainter extends CustomPainter {
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
      ..color = AppTheme.accent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      4.5,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
