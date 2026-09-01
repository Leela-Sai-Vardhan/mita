import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/constants/storage_keys.dart';
import '../core/mitzy_assets.dart';
import 'onboarding/onboarding_screen.dart';
import 'navigation_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _mitzyController;
  late final Animation<double> _mitzyAnimation;
  String _mitzyAsset = MitzyAssets.standard;
  bool _isWinter = false;

  @override
  void initState() {
    super.initState();
    _mitzyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _mitzyAnimation = CurvedAnimation(
      parent: _mitzyController,
      curve: Curves.easeOutCubic,
    );
    _resolveMitzy();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _mitzyController.forward();
    });
    _navigate();
  }

  Future<void> _resolveMitzy() async {
    final now = DateTime.now();
    final asset = await MitzyAssets.resolve(now);
    final isWinter = MitzyAssets.isWinterActive(now);
    if (!mounted) return;
    setState(() {
      _mitzyAsset = asset;
      _isWinter = isWinter;
    });
  }

  @override
  void dispose() {
    _mitzyController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    final prefsFuture = SharedPreferences.getInstance();
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    final prefs = await prefsFuture;
    final hasSeen = prefs.getBool(StorageKeys.hasSeenOnboarding) ?? false;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) =>
            hasSeen ? const MainNavigation() : const OnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'app_logo_hero',
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: AppTheme.borderEmpty, width: 1.5),
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
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mita',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Focus on what matters',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppTheme.mutedText,
              ),
            ),
            Text(
              'Three tasks. One day.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _mitzyAnimation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.0)
                    .animate(_mitzyAnimation),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      _mitzyAsset,
                      width: 56,
                      height: 56,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        MitzyAssets.splashCopyFor(_isWinter),
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
