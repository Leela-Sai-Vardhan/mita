import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';

class RatePromptService {
  static const _hasRatedKey = 'rate_has_rated';
  static const _dismissCountKey = 'rate_dismiss_count';
  static const _lastPromptedKey = 'rate_last_prompted';
  static const _taskCompletedCountKey = 'rate_task_completed_count';

  static final RatePromptService _instance = RatePromptService._();
  factory RatePromptService() => _instance;
  RatePromptService._();

  Future<int> get taskCompletedCount async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_taskCompletedCountKey) ?? 0;
  }

  Future<void> incrementTasksCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _taskCompletedCountKey,
      (prefs.getInt(_taskCompletedCountKey) ?? 0) + 1,
    );
  }

  Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(_hasRatedKey) ?? false) return false;

    final dismisses = prefs.getInt(_dismissCountKey) ?? 0;
    if (dismisses >= 3) return false;

    final lastPrompted = prefs.getInt(_lastPromptedKey) ?? 0;
    if (lastPrompted > 0) {
      final daysSince = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastPrompted))
          .inDays;
      if (daysSince < 7) return false;
    }

    final completed = prefs.getInt(_taskCompletedCountKey) ?? 0;
    if (completed < 3) return false;

    return true;
  }

  Future<void> markRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasRatedKey, true);
  }

  Future<void> markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _dismissCountKey,
      (prefs.getInt(_dismissCountKey) ?? 0) + 1,
    );
    await prefs.setInt(
      _lastPromptedKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  void show(BuildContext context) {
    if (!context.mounted) return;
    _showRateDialog(context);
  }

  Future<void> tryShowIfNeeded(BuildContext context) async {
    if (!await shouldShow()) return;
    if (!context.mounted) return;
    _showRateDialog(context);
  }

  void _showRateDialog(BuildContext context) {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/mitzy_rate.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Enjoying Mita?',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "I'm a student developer building this alone. "
              'A quick rating on the Play Store would mean the world to me — '
              'it helps me stay motivated and keep improving Mita for you.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.mutedText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  markRated();
                  final uri = Uri.parse(
                    'https://play.google.com/store/apps/details?'
                    'id=com.dreamstarx.mita&hl=en_IN',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                icon: const Icon(Icons.star, color: Colors.black87, size: 18),
                label: Text(
                  'Rate on Play Store',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  markDismissed();
                  Navigator.pop(ctx);
                },
                child: Text(
                  'Maybe later',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.mutedText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
