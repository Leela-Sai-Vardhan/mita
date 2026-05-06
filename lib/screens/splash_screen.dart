import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderEmpty, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '⊙',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
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