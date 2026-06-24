import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/constants/storage_keys.dart';
import 'onboarding/onboarding_screen.dart';
import 'navigation_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final prefsFuture = SharedPreferences.getInstance();
    await Future.delayed(const Duration(seconds: 2));
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
            const SizedBox(height: 2),
            Text(
              'Three tasks. One day.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


