import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme.dart';

class OnboardingPage extends StatelessWidget {
  final Widget icon;
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final String body;
  final Widget? extraContent;
  final int index;

  const OnboardingPage({
    super.key,
    required this.icon,
    this.title,
    this.titleWidget,
    this.subtitle,
    required this.body,
    this.extraContent,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Hero(
            tag: index == 0 ? 'app_logo_hero' : 'onboarding_icon_$index',
            child: icon,
          ).animate().fadeIn(
            duration: 600.ms,
            delay: 100.ms,
          ),
          const SizedBox(height: 32),
          if (titleWidget != null)
            titleWidget!
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic)
          else ...[
            if (title != null)
              Text(
                title!,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ).animate().fadeIn(
                duration: 500.ms,
                delay: 200.ms,
              ).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppTheme.mutedText,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(
              duration: 400.ms,
              delay: 500.ms,
            ).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          ],
          const SizedBox(height: 20),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppTheme.mutedText,
              height: 1.6,
            ),
          ).animate().fadeIn(
            duration: 500.ms,
            delay: 350.ms,
          ).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
          if (extraContent != null) ...[
            const SizedBox(height: 24),
            extraContent!,
          ],
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
