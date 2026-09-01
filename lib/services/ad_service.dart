import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'remote_config_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _isShowing = false;
  bool _initialized = false;
  Completer<bool>? _showCompleter;
  bool _lastEarned = false;

  // Use Google's official test unit in debug/profile builds;
  // real unit in release builds (overridable via remote config).
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _releaseAdUnitId =
      'ca-app-pub-1658916437389658/2675524551';

  String get _adUnitId {
    // Remote config can override the release ad unit id.
    final remote = RemoteConfigService.instance.rewardedAdUnitId;
    if (remote != null && remote.isNotEmpty) return remote;
    return kDebugMode ? _testAdUnitId : _releaseAdUnitId;
  }

  bool get isRewardedReady =>
      AdService.disabled || _rewardedAd != null && !_isLoading && !_isShowing;

  /// Whether ads are globally disabled via remote config.
  static bool get disabled => !RemoteConfigService.instance
      .featureFlag('ads_enabled', fallback: true);

  Future<void> initialize() async {
    if (_initialized) return;
    // Respect remote "ads_enabled" feature flag.
    if (AdService.disabled) {
      _initialized = true;
      debugPrint('[Ads] Disabled by remote config.');
      return;
    }
    MobileAds.instance.initialize();
    _initialized = true;
    await _loadRewardedAd();
  }

  Future<void> _loadRewardedAd() async {
    if (_isLoading || _isShowing) return;
    _isLoading = true;

    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _completeShow();
              ad.dispose();
              _rewardedAd = null;
              _isShowing = false;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[Ads] Failed to show rewarded ad: $error');
              _completeShow();
              ad.dispose();
              _rewardedAd = null;
              _isShowing = false;
              _loadRewardedAd();
            },
            onAdShowedFullScreenContent: (_) {
              _isShowing = true;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('[Ads] Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _isLoading = false;
          Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
        },
      ),
    );
  }

  void _completeShow() {
    final earned = _lastEarned;
    _lastEarned = false;
    _showCompleter?.complete(earned);
    _showCompleter = null;
  }

  /// Shows the rewarded ad. Resolves `true` if the reward was earned,
  /// `false` if the user closed it early, it failed to show, or no ad was ready.
  Future<bool> showRewardedAd() async {
    if (AdService.disabled || _rewardedAd == null || _isLoading || _isShowing) {
      return false;
    }
    final ad = _rewardedAd!;

    if (_showCompleter != null) {
      return _showCompleter!.future;
    }

    final completer = Completer<bool>();
    _showCompleter = completer;

    ad.show(
      onUserEarnedReward: (ad, reward) {
        _lastEarned = true;
      },
    );

    final earned = await completer.future;
    return earned;
  }
}