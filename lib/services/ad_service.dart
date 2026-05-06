// AdService — stub kept for future monetization.
// google_mobile_ads is not active. Re-add the package and
// uncomment the implementation when ready to monetize.

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool get isInterstitialReady => false;
  bool get isRewardedReady => false;

  Future<void> initialize() async {}
  Future<void> loadInterstitial({void Function()? onClosed}) async {}
  Future<void> showInterstitial() async {}
  Future<void> loadRewardedAd({
    void Function()? onEarned,
    void Function()? onClosed,
  }) async {}
  Future<void> showRewardedAd({void Function()? onEarned}) async {}
}