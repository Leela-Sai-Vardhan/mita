import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mita/services/remote_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleConfig = {
    'schema_version': 1,
    'updated_at': '2026-08-31T00:00:00Z',
    'config_url': 'https://example.com/mita-config.json',
    'theme': {
      'background': '#0D0D0D',
      'surface': '#1A1A1A',
      'accent': '#FFAA00',
      'success': '#4CAF50',
      'muted_text': '#888888',
    },
    'seasonal': {
      'winter_arc': {
        'enabled': true,
        'start_month': 12,
        'end_month': 2,
        'mitzy_variant': 'scarf',
        'splash_copy': 'Cozy season!',
        'splash_copy_default': 'Meet Mitzy',
      },
    },
    'feature_flags': {
      'ads_enabled': false,
      'show_rate_prompt': true,
      'home_widget': true,
      'telemetry': true,
    },
    'ads': {'rewarded_ad_unit_id': 'ca-app-pub-test/reward'},
    'copy': {'tagline': 'Be productive'},
    'reminders': {'daily': true},
    'upcoming_events': [
      {'id': 'e1', 'title': 'Winter Arc', 'is_campaign': true},
    ],
    'app_update': {
      'latest_version': '2.1.0',
      'latest_build': 12,
      'force_update_from_build': 20,
      'update_title': 'Update available',
      'update_message': 'Please update',
    },
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('fetches and parses remote config', () async {
    final client = MockClient((req) async {
      return http.Response(
        _encode(sampleConfig),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final rc = RemoteConfigService(
      client: client,
      baseUrl: 'https://example.com/config.json',
    );
    await rc.load();

    expect(rc.isLoaded, isTrue);
    expect(rc.loadedFromCache, isFalse);
    // Top-level getters
    expect(rc.rawUpdatedAt, '2026-08-31T00:00:00Z');
    expect(rc.configUrlFromConfig, 'https://example.com/mita-config.json');
    // Theme
    expect(rc.accentColor.toARGB32(), 0xFFFFAA00);
    expect(rc.backgroundColor.toARGB32(), 0xFF0D0D0D);
    // Seasonal
    expect(rc.winterArcEnabled, isTrue);
    expect(rc.mitzyVariant, 'scarf');
    expect(rc.winterStartMonth, 12);
    expect(rc.winterEndMonth, 2);
    expect(rc.splashCopy, 'Cozy season!');
    expect(rc.splashCopyDefault, 'Meet Mitzy');
    // Flags
    expect(rc.featureFlag('ads_enabled', fallback: true), isFalse);
    expect(rc.featureFlag('show_rate_prompt'), isTrue);
    expect(rc.featureFlag('missing_flag'), isTrue);
    // Ads
    expect(rc.rewardedAdUnitId, 'ca-app-pub-test/reward');
    // App update
    expect(rc.latestVersion, '2.1.0');
    expect(rc.latestBuild, 12);
    expect(rc.forceUpdateFromBuild, 20);
    expect(rc.updateTitle, 'Update available');
    // Events
    expect(rc.upcomingEvents.length, 1);
  });

  test('falls back to filtered defaults when fetch fails', () async {
    final client = MockClient((req) async {
      throw http.ClientException('offline');
    });

    SharedPreferences.setMockInitialValues({
      'remote_config_cached_json': _encode(sampleConfig),
    });

    final rc = RemoteConfigService(
      client: client,
      baseUrl: 'https://example.com/config.json',
    );
    await rc.load();

    expect(rc.loadedFromCache, isTrue);
    expect(rc.mitzyVariant, 'scarf');
    expect(rc.accentColor.toARGB32(), 0xFFFFAA00);
  });

  test('fell back to baked-in defaults when no cache and fetch fails', () async {
    final client = MockClient((req) async {
      throw http.ClientException('offline');
    });

    final rc = RemoteConfigService(
      client: client,
      baseUrl: 'https://example.com/config.json',
    );
    await rc.load();

    expect(rc.isLoaded, isFalse);
    // Baked-in defaults
    expect(rc.accentColor.toARGB32(), 0xFFE94560);
    expect(rc.featureFlag('ads_enabled'), isTrue);
  });

  test('refresh returns whether values changed', () async {
    // First call returns one accent, second returns a different one.
    var count = 0;
    final client = MockClient((req) async {
      count++;
      final config = Map<String, dynamic>.from(sampleConfig);
      final theme = Map<String, dynamic>.from(config['theme'] as Map);
      theme['accent'] = count == 1 ? '#FFAA00' : '#CC00FF';
      config['theme'] = theme;
      return http.Response(_encode(config), 200,
          headers: {'content-type': 'application/json'});
    });

    final rc = RemoteConfigService(
      client: client,
      baseUrl: 'https://example.com/config.json',
    );
    await rc.load();
    expect(rc.accentColor.toARGB32(), 0xFFFFAA00);

    final changed = await rc.refresh();
    expect(count, 2);
    expect(changed, isTrue);
    expect(rc.accentColor.toARGB32(), 0xFFCC00FF);

    // Third fetch identical -> not changed.
    final unchanged = await rc.refresh();
    expect(unchanged, isFalse);
  });
}

String _encode(Map<String, dynamic> map) {
  // Avoid importing dart:convert in tests indirectly; use jsonEncode.
  return const JsonEncoder().convert(map);
}
