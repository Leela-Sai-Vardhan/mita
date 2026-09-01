import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Swiggy-style remote configuration served from a Vercel-hosted JSON file.
///
/// The app fetches the config at startup, caches it, and falls back to the
/// cached copy (then baked-in defaults) when offline so it always works.
///
/// Usage:
///   await RemoteConfigService().load();          // on startup
///   RemoteConfigService().featureFlag('ads_enabled');
///   RemoteConfigService().accentColor;
///
/// Extends [ChangeNotifier] so an in-app "Check for updates" can re-fetch and
/// notify listeners to trigger a live re-theme.
class RemoteConfigService extends ChangeNotifier {
  RemoteConfigService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? defaultConfigUrl;

  final http.Client _client;
  final String _baseUrl;

  static const String defaultConfigUrl =
      'https://mita-android.vercel.app/mita-config.json';
  static const String _cacheKey = 'remote_config_cached_json';
  static const Duration _fetchTimeout = Duration(seconds: 8);

  Map<String, dynamic> _config = const {};
  bool _isLoading = false;
  DateTime? _lastUpdated;
  bool _loadedFromCache = false;

  static final RemoteConfigService _instance = RemoteConfigService();
  static RemoteConfigService get instance => _instance;

  bool get isLoading => _isLoading;
  bool get isLoaded => _config.isNotEmpty;
  bool get loadedFromCache => _loadedFromCache;
  DateTime? get lastUpdated => _lastUpdated;

  /// Fetches fresh config from Vercel. Never throws — on any failure it keeps
  /// the current (cached/default) config so the app is unaffected.
  Future<void> load() async {
    _isLoading = true;
    var fetched = false;
    try {
      final resp = await _client
          .get(Uri.parse(_baseUrl))
          .timeout(_fetchTimeout);
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map<String, dynamic>) {
          _config = decoded;
          _lastUpdated = DateTime.now();
          _loadedFromCache = false;
          fetched = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, resp.body);
        }
      }
    } catch (e) {
      debugPrint('[RemoteConfig] fetch failed, using cached/default: $e');
    } finally {
      _isLoading = false;
    }

    if (!fetched && _config.isEmpty) {
      await _loadCache();
    }
    notifyListeners();
  }

  /// Re-fetches config (used by the in-app "Check for updates" action) and
  /// returns true if new values were applied. Change detection is based on the
  /// canonical JSON serialization (Dart [Map] equality is identity-based).
  Future<bool> refresh() async {
    final before = jsonEncode(_config);
    await load();
    return jsonEncode(_config) != before;
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final decoded = jsonDecode(cached);
        if (decoded is Map<String, dynamic>) {
          _config = decoded;
          _loadedFromCache = true;
        }
      }
    } catch (e) {
      debugPrint('[RemoteConfig] cache read failed: $e');
    }
  }

  // ---- Typed accessors ------------------------------------------------

  Map<String, dynamic> _section(String key) {
    final v = _config[key];
    return v is Map<String, dynamic> ? v : const {};
  }

  bool sectionFlag(String section, String key, {bool fallback = true}) {
    final v = _section(section)[key];
    return v is bool ? v : fallback;
  }

  bool featureFlag(String key, {bool fallback = true}) =>
      sectionFlag('feature_flags', key, fallback: fallback);

  bool reminderEnabled(String key, {bool fallback = true}) =>
      sectionFlag('reminders', key, fallback: fallback);

  String? stringValue(String section, String key) {
    final v = _section(section)[key];
    return v is String ? v : null;
  }

  int? intValue(String section, String key) {
    final v = _section(section)[key];
    return v is int ? v : null;
  }

  // Theme colors with baked-in defaults matching AppTheme.
  Color get backgroundColor =>
      _colorFromHex(stringValue('theme', 'background'), '#0D0D0D');
  Color get surfaceColor =>
      _colorFromHex(stringValue('theme', 'surface'), '#1A1A1A');
  Color get accentColor =>
      _colorFromHex(stringValue('theme', 'accent'), '#E94560');
  Color get successColor =>
      _colorFromHex(stringValue('theme', 'success'), '#4CAF50');
  Color get mutedTextColor =>
      _colorFromHex(stringValue('theme', 'muted_text'), '#888888');

  // Seasonal / Mitzy.
  bool get winterArcEnabled =>
      _section('seasonal')['winter_arc'] is Map<String, dynamic>
          ? (_section('seasonal')['winter_arc'] as Map<String, dynamic>)
                  ['enabled'] as bool? ??
              true
          : true;
  String? get mitzyVariant =>
      _section('seasonal')['winter_arc'] is Map<String, dynamic>
          ? (_section('seasonal')['winter_arc'] as Map<String, dynamic>)
                  ['mitzy_variant'] as String?
          : null;
  int? get winterStartMonth =>
      _section('seasonal')['winter_arc'] is Map<String, dynamic>
          ? (_section('seasonal')['winter_arc'] as Map<String, dynamic>)
                  ['start_month'] as int?
          : null;
  int? get winterEndMonth =>
      _section('seasonal')['winter_arc'] is Map<String, dynamic>
          ? (_section('seasonal')['winter_arc'] as Map<String, dynamic>)
                  ['end_month'] as int?
          : null;
  String? get splashCopy =>
      _section('seasonal')['winter_arc'] is Map<String, dynamic>
          ? (_section('seasonal')['winter_arc'] as Map<String, dynamic>)
                  ['splash_copy'] as String?
          : null;
  String? get splashCopyDefault =>
      _section('seasonal')['winter_arc'] is Map<String, dynamic>
          ? (_section('seasonal')['winter_arc'] as Map<String, dynamic>)
                  ['splash_copy_default'] as String?
          : null;

  // Ads.
  String? get rewardedAdUnitId => stringValue('ads', 'rewarded_ad_unit_id');
  String? get bannerAdUnitId => stringValue('ads', 'banner_ad_unit_id');

  // Copy.
  String? get tagline => stringValue('copy', 'tagline');
  String? get subTagline => stringValue('copy', 'sub_tagline');
  String? get rateDialogTitle => stringValue('copy', 'rate_dialog_title');
  String? get rateDialogBody => stringValue('copy', 'rate_dialog_body');

  // Upcoming events.
  List<Map<String, dynamic>> get upcomingEvents {
    final v = _config['upcoming_events'];
    if (v is List) {
      return v.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  // App update.
  String? get latestVersion => stringValue('app_update', 'latest_version');
  int? get latestBuild => intValue('app_update', 'latest_build');
  int? get forceUpdateFromBuild =>
      intValue('app_update', 'force_update_from_build');
  String? get updateTitle => stringValue('app_update', 'update_title');
  String? get updateMessage => stringValue('app_update', 'update_message');
  String? get rawUpdatedAt {
    final v = _config['updated_at'];
    return v is String ? v : null;
  }

  String? get configUrlFromConfig {
    final v = _config['config_url'];
    return v is String ? v : null;
  }

  static Color _colorFromHex(String? hex, String fallback) {
    var h = hex ?? fallback;
    h = h.replaceFirst('#', '');
    if (h.length == 6) {
      final v = int.tryParse(h, radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    return Color(int.tryParse(fallback.replaceFirst('#', ''), radix: 16)!
        | 0xFF000000);
  }
}
