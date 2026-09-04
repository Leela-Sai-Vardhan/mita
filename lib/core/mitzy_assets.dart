import 'package:flutter/foundation.dart' show kDebugMode, kProfileMode;
import 'package:flutter/services.dart' show rootBundle;
import '../services/remote_config_service.dart';
import 'winter_arc.dart';

/// Resolves which Mitzy asset should be shown based on season and availability.
///
/// The standard Mitzy banner is `assets/images/mitzy_rate.png`. During the
/// "Winter Arc" season (September 1 through the end of February, configurable
/// via remote config) the app swaps in a cozy Winter Arc variant provided by
/// the design team, and falls back to the standard asset when the seasonal
/// art is missing or the season is off.
class MitzyAssets {
  MitzyAssets._();

  /// Standard (non-winter) Mitzy banner.
  static const String standard = 'assets/images/mitzy_rate.png';

  /// Winter Arc default (primary "Cozy & Hot Cocoa" variant per design spec).
  static const String winterArc = 'assets/images/mitzy_winter_arc_cozy.png';

  /// Winter Arc variants (all three delivered by the design team).
  static const Map<String, String> _winterVariants = {
    'cozy': 'assets/images/mitzy_winter_arc_cozy.png',
    'frosty': 'assets/images/mitzy_winter_arc_frosty.png',
    'scarf': 'assets/images/mitzy_winter_arc_scarf.png',
  };

  /// Ordered keys for the three delivered Winter Arc variants.
  static const List<String> winterVariantKeys = ['cozy', 'frosty', 'scarf'];

  /// Whether [date] falls inside the Winter Arc season (Sep 1 – end of Feb),
  /// or within the config-supplied window when present. Delegates to the
  /// [WinterArc] engine so art and campaign stay in sync.
  static bool isWinterArcSeason(DateTime date) => WinterArc.isArcSeason(date);

  /// Whether Winter Arc should be active for [date], honouring the remote
  /// `winter_arc.enabled` flag and the seasonal window AND the asset existing.
  /// With [forceWinterPreview] enabled (debug/profile default) the seasonal
  /// window is bypassed so the art can be previewed out of season.
  static Future<bool> winterIsAvailable(DateTime date) async {
    final rc = RemoteConfigService.instance;
    if (!rc.winterArcEnabled) return false;
    final inSeason = forceWinterPreview || isWinterArcSeason(date);
    if (!inSeason) return false;
    return _assetExists(resolveVariantPath());
  }

  /// Resolves the asset path to use for [date].
  static Future<String> resolve(DateTime date) async {
    if (await winterIsAvailable(date)) return resolveVariantPath();
    return standard;
  }

  /// Whether the Winter Arc is currently active for UI copy/styling.
  ///
  /// When [forceWinterPreview] is enabled (the debug/profile default), this
  /// returns true regardless of the calendar so the season can be previewed
  /// out of season. Otherwise it falls back to the strict seasonal check.
  static bool isWinterActive(DateTime date) {
    if (!RemoteConfigService.instance.winterArcEnabled) return false;
    if (forceWinterPreview) return true;
    return isWinterArcSeason(date);
  }

  /// When true, [isWinterActive] ignores the calendar so the Winter Arc can be
  /// previewed out of season. Defaults to enabled in debug/profile builds and
  /// disabled in release. Tests disable this to keep seasonal assertions
  /// deterministic.
  static bool forceWinterPreview = kDebugMode || kProfileMode;

  /// The active Winter Arc variant, driven by the remote `mitzy_variant` value
  /// (falls back to the 'cozy' default).
  static String resolveVariantPath() {
    final variant = RemoteConfigService.instance.mitzyVariant;
    return variant != null
        ? (_winterVariants[variant] ?? winterArc)
        : winterArc;
  }

  /// The cosmopolitan splash/CTA copy to show for [isWinter], from remote
  /// config with the standard fallbacks.
  static String splashCopyFor(bool isWinter) {
    final rc = RemoteConfigService.instance;
    if (isWinter) return rc.splashCopy ?? 'Meet Mitzy ❄️';
    return rc.splashCopyDefault ?? 'Meet Mitzy ✨';
  }

  /// Path for a named Winter Arc variant's asset, or [winterArc] when the
  /// variant is not one of the three designed keys.
  static String variantPath(String key) => _winterVariants[key] ?? winterArc;

  static Future<bool> _assetExists(String asset) async {
    try {
      await rootBundle.load(asset);
      return true;
    } catch (_) {
      return false;
    }
  }
}
