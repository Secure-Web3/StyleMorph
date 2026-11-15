class AdMobConfig {
  final bool isAdMobEnabled;
  final int interstitialFrequency;
  final int interstitialCooldownSec;
  final int rewardedCoinsPerVideo;
  final int rewardedDailyCap;
  final String rewardedSsvUrl;
  final bool appOpenAdsEnabled;
  final int appOpenColdStartThresholdSec;

  const AdMobConfig({
    this.isAdMobEnabled = true,
    this.interstitialFrequency = 3,
    this.interstitialCooldownSec = 180,
    this.rewardedCoinsPerVideo = 15,
    this.rewardedDailyCap = 5,
    this.rewardedSsvUrl =
        'https://europe-west3-stylemorph-prod.cloudfunctions.net/admobSsvCallback',
    this.appOpenAdsEnabled = true,
    this.appOpenColdStartThresholdSec = 4,
  });

  AdMobConfig copyWith({
    bool? isAdMobEnabled,
    int? interstitialFrequency,
    int? interstitialCooldownSec,
    int? rewardedCoinsPerVideo,
    int? rewardedDailyCap,
    String? rewardedSsvUrl,
    bool? appOpenAdsEnabled,
    int? appOpenColdStartThresholdSec,
  }) {
    return AdMobConfig(
      isAdMobEnabled: isAdMobEnabled ?? this.isAdMobEnabled,
      interstitialFrequency:
          interstitialFrequency ?? this.interstitialFrequency,
      interstitialCooldownSec:
          interstitialCooldownSec ?? this.interstitialCooldownSec,
      rewardedCoinsPerVideo:
          rewardedCoinsPerVideo ?? this.rewardedCoinsPerVideo,
      rewardedDailyCap: rewardedDailyCap ?? this.rewardedDailyCap,
      rewardedSsvUrl: rewardedSsvUrl ?? this.rewardedSsvUrl,
      appOpenAdsEnabled: appOpenAdsEnabled ?? this.appOpenAdsEnabled,
      appOpenColdStartThresholdSec:
          appOpenColdStartThresholdSec ?? this.appOpenColdStartThresholdSec,
    );
  }
}

class AiSponsoringConfig {
  final int stylistRecommendationWeightPct;
  final bool sponsoredWatermarkEnabled;
  final String brandWatermarkText;
  final String brandLogoUrl;
  final int cpcAuctionFloorToman;

  const AiSponsoringConfig({
    this.stylistRecommendationWeightPct = 35,
    this.sponsoredWatermarkEnabled = true,
    this.brandWatermarkText = 'Sponsored by ZAGROS Haute Couture',
    this.brandLogoUrl = 'https://storage.googleapis.com/stylemorph-brands/zagros.webp',
    this.cpcAuctionFloorToman = 1500,
  });

  AiSponsoringConfig copyWith({
    int? stylistRecommendationWeightPct,
    bool? sponsoredWatermarkEnabled,
    String? brandWatermarkText,
    String? brandLogoUrl,
    int? cpcAuctionFloorToman,
  }) {
    return AiSponsoringConfig(
      stylistRecommendationWeightPct:
          stylistRecommendationWeightPct ?? this.stylistRecommendationWeightPct,
      sponsoredWatermarkEnabled:
          sponsoredWatermarkEnabled ?? this.sponsoredWatermarkEnabled,
      brandWatermarkText: brandWatermarkText ?? this.brandWatermarkText,
      brandLogoUrl: brandLogoUrl ?? this.brandLogoUrl,
      cpcAuctionFloorToman: cpcAuctionFloorToman ?? this.cpcAuctionFloorToman,
    );
  }
}

class AdaptiveGenerosityConfig {
  final bool isEnabled;
  final double targetAdToAiRatio;
  final double currentMultiplier;
  final int dynamicDailyFreeCoins;
  final bool permanentWellnessLock;

  const AdaptiveGenerosityConfig({
    this.isEnabled = true,
    this.targetAdToAiRatio = 2.5,
    this.currentMultiplier = 1.25,
    this.dynamicDailyFreeCoins = 50,
    this.permanentWellnessLock = true,
  });

  AdaptiveGenerosityConfig copyWith({
    bool? isEnabled,
    double? targetAdToAiRatio,
    double? currentMultiplier,
    int? dynamicDailyFreeCoins,
    bool? permanentWellnessLock,
  }) {
    return AdaptiveGenerosityConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      targetAdToAiRatio: targetAdToAiRatio ?? this.targetAdToAiRatio,
      currentMultiplier: currentMultiplier ?? this.currentMultiplier,
      dynamicDailyFreeCoins:
          dynamicDailyFreeCoins ?? this.dynamicDailyFreeCoins,
      permanentWellnessLock:
          permanentWellnessLock ?? this.permanentWellnessLock,
    );
  }
}
