import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import 'remote_config_service.dart';

/// Remote-driven "update available" / force-update dialogs.
///
/// Compares the bundled build number (parsed from [AppTheme.appVersion],
/// e.g. "2.0.0+11" -> build 11) against the Vercel config's
/// `app_update.latest_build` and `app_update.force_update_from_build`.
///
/// A force update (bundled build < `force_update_from_build`) is
/// non-dismissable: the user must update to continue.
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._();
  factory AppUpdateService() => _instance;
  AppUpdateService._();

  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.dreamstarx.mita';

  /// The build number bundled with this app (parsed from AppTheme.appVersion).
  int get currentBuild {
    final plus = AppTheme.appVersion.lastIndexOf('+');
    if (plus < 0) return 0;
    return int.tryParse(AppTheme.appVersion.substring(plus + 1)) ?? 0;
  }

  /// True when the config declares a newer build than the installed one.
  bool get isUpdateAvailable {
    final latest = RemoteConfigService.instance.latestBuild;
    return latest != null && latest > currentBuild;
  }

  /// True when this build is below the config's force-update threshold.
  bool get isForceUpdateRequired => forceUpdateRequired(
        currentBuild: currentBuild,
        latestBuild: RemoteConfigService.instance.latestBuild,
        forceFrom: RemoteConfigService.instance.forceUpdateFromBuild,
      );

  /// Pure force-update decision so the guard can be unit-tested.
  ///
  /// Force applies only when all of:
  /// - `forceFrom` is a real build number (> 0; 0 disables forcing),
  /// - a newer build actually exists (`latestBuild > currentBuild`),
  /// - the installed build is below the threshold.
  ///
  /// This keeps a misconfigured sentinel (e.g. 999999) or a stale
  /// `latest_build` from trapping users in a non-dismissable dialog that
  /// points at a version that does not exist yet.
  @visibleForTesting
  static bool forceUpdateRequired({
    required int currentBuild,
    int? latestBuild,
    int? forceFrom,
  }) {
    if (forceFrom == null || forceFrom <= 0) return false;
    if (latestBuild == null || latestBuild <= currentBuild) return false;
    return currentBuild < forceFrom;
  }

  /// Returns a promise that resolves true once any pending update is shown.
  /// Returns false when there is nothing to show.
  Future<bool> showIfNeeded(BuildContext context) async {
    if (!isUpdateAvailable && !isForceUpdateRequired) return false;
    if (!context.mounted) return false;
    await _showDialog(context, force: isForceUpdateRequired);
    return true;
  }

  Future<void> _showDialog(BuildContext context, {required bool force}) async {
    final rc = RemoteConfigService.instance;
    final title = rc.updateTitle ?? 'Update available';
    final message = rc.updateMessage ??
        'A new version of Mita is available. Update to get the latest '
            'features and fixes.';

    await showDialog<void>(
      context: context,
      barrierDismissible: !force,
      builder: (ctx) => PopScope(
        canPop: !force,
        child: AlertDialog(
          backgroundColor: AppTheme.surface,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.system_update_alt, color: AppTheme.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppTheme.mutedText,
              height: 1.5,
            ),
          ),
          actions: force
              ? [
                  ElevatedButton(
                    onPressed: _openPlayStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                    ),
                    child: Text(
                      'Update now',
                      style:
                          GoogleFonts.dmSans(color: Colors.white),
                    ),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Later',
                      style: GoogleFonts.dmSans(color: AppTheme.mutedText),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openPlayStore();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                    ),
                    child: Text(
                      'Update',
                      style: GoogleFonts.dmSans(color: Colors.white),
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
