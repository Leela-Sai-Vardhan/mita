import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _isShowing = false;
  bool _initialized = false;

  static const String _rewardedAdUnitId = 'ca-app-pub-1658916437389658/2675524551';

  bool get isRewardedReady => _rewardedAd != null && !_isLoading && !_isShowing;

  Future<void> initialize() async {
    if (_initialized) return;
    MobileAds.instance.initialize();
    _initialized = true;
    await _loadRewardedAd();
  }

  Future<void> _loadRewardedAd() async {
    if (_isLoading || _isShowing) return;
    _isLoading = true;

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isShowing = false;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
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
          _rewardedAd = null;
          _isLoading = false;
          Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
        },
      ),
    );
  }

  Future<void> showRewardedAd({
    required void Function(int rewardAmount) onEarned,
    VoidCallback? onAdFailed,
  }) async {
    if (!isRewardedReady) {
      onAdFailed?.call();
      return;
    }

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onEarned(reward.amount as int);
      },
    );
  }
}