import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/remote_config_service.dart';

class AppTheme {
  static const String appVersion = '2.0.0+11';
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color accent = Color(0xFFE94560);
  static const Color success = Color(0xFF4CAF50);
  static const Color mutedText = Color(0xFF888888);
  
  static const Color borderEmpty = Color(0xFF2A2A2A);
  static const Color placeholderText = Color(0xFF3A3A3A);
  
  static const Color doneBackground = Color(0xFF0F200F);
  static const Color doneBorder = Color(0xFF1E3A1E);

  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);
  static const Color glassHighlight = Color(0x0DFFFFFF);

  static const Color streakFire = Color(0xFFFF6B35);
  static const Color streakFreeze = Color(0xFFF5A623);
  static const Color streakMilestone = Color(0xFFFFD700);
  static const Color streakGreen = Color(0xFF4CAF50);
  static const Color streakOrange = Color(0xFFFF9800);
  static const Color streakRed = Color(0xFFE94560);
  static const Color streakPurple = Color(0xFF9C27B0);

  static Color getStreakColor(int streak) {
    if (streak >= 100) return streakPurple;
    if (streak >= 50) return streakMilestone;
    if (streak >= 30) return streakOrange;
    if (streak >= 14) return streakFire;
    if (streak >= 7) return streakOrange;
    if (streak >= 3) return streakFire;
    return AppTheme.accent;
  }

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: accent,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      surface: surface,
      secondary: success,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: GoogleFonts.dmSans(
        color: Colors.white,
      ),
      bodyMedium: GoogleFonts.dmSans(
        color: Colors.white,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.down,
    ),
  );

  /// Builds the app [ThemeData] from remote configuration, falling back to
  /// the baked-in defaults when config is unavailable. Call this on startup
  /// and again whenever the remote config refreshes (live re-theme).
  static ThemeData buildTheme({RemoteConfigService? config}) {
    final rc = config ?? RemoteConfigService.instance;
    final bg = rc.backgroundColor;
    final surface = rc.surfaceColor;
    final accent = rc.accentColor;
    final success = rc.successColor;
    final muted = rc.mutedTextColor;

    final colorScheme = ColorScheme.dark(
      primary: accent,
      surface: surface,
      secondary: success,
      onPrimary: Colors.white,
      onSurface: Colors.white,
      onSecondary: Colors.black87,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: accent,
      colorScheme: colorScheme,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.dmSans(
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.dmSans(
          color: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.down,
      ),
      // Pass remote colors into the widget tree via the theme so screens that
      // read `Theme.of(context)` can honour live re-theme.
      extensions: [
        RemoteThemeColors(
          background: bg,
          surface: surface,
          accent: accent,
          success: success,
          mutedText: muted,
        ),
      ],
    );
  }

  static Future<bool?> showPremiumConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmLabel,
    required IconData headerIcon,
    required Color accentColor,
    String cancelLabel = 'Cancel',
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: AlertDialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: borderEmpty, width: 1.5),
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Icon(headerIcon, color: accentColor, size: 28),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: mutedText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          cancelLabel,
                          style: GoogleFonts.dmSans(
                            color: mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          confirmLabel,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static SnackBar customSnackBar({
    required String message,
    required BuildContext context,
    IconData? icon,
    Color? iconColor,
    Color? leftBarColor,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderEmpty, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (leftBarColor != null) ...[
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: leftBarColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? leftBarColor ?? Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  action.onPressed();
                },
                child: Text(
                  action.label,
                  style: GoogleFonts.dmSans(
                    color: action.textColor ?? accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Provides the remote-config theme colors to descendants via
/// `Theme.of(context).extension<RemoteThemeColors>()`. This lets widgets honor
/// live re-theme without refactoring the static [AppTheme] constants.
@immutable
class RemoteThemeColors extends ThemeExtension<RemoteThemeColors> {
  const RemoteThemeColors({
    required this.background,
    required this.surface,
    required this.accent,
    required this.success,
    required this.mutedText,
  });

  final Color background;
  final Color surface;
  final Color accent;
  final Color success;
  final Color mutedText;

  @override
  RemoteThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? accent,
    Color? success,
    Color? mutedText,
  }) {
    return RemoteThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      mutedText: mutedText ?? this.mutedText,
    );
  }

  @override
  RemoteThemeColors lerp(RemoteThemeColors? other, double t) {
    if (other == null) return this;
    return RemoteThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
    );
  }
}
