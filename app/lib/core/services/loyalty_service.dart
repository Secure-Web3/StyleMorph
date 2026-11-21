import 'package:flutter/material.dart';
import '../localization/app_strings.dart';

/// 4 Progressive Loyalty Ranks based on StylePoints.
enum LoyaltyRank { bronze, silver, gold, diamond }

extension LoyaltyRankExtension on LoyaltyRank {
  String get nameCapitalized {
    switch (this) {
      case LoyaltyRank.bronze:
        return 'Bronze';
      case LoyaltyRank.silver:
        return 'Silver';
      case LoyaltyRank.gold:
        return 'Gold';
      case LoyaltyRank.diamond:
        return 'Diamond';
    }
  }

  Color get color {
    switch (this) {
      case LoyaltyRank.bronze:
        return const Color(0xFFCD7F32); // Bronze
      case LoyaltyRank.silver:
        return const Color(0xFF94A3B8); // Slate Silver
      case LoyaltyRank.gold:
        return const Color(0xFFF59E0B); // Amber / Gold
      case LoyaltyRank.diamond:
        return const Color(0xFF06B6D4); // Cyan / Diamond
    }
  }

  int get minPoints {
    switch (this) {
      case LoyaltyRank.bronze:
        return 0;
      case LoyaltyRank.silver:
        return 500;
      case LoyaltyRank.gold:
        return 1500;
      case LoyaltyRank.diamond:
        return 4000;
    }
  }

  int get maxPoints {
    switch (this) {
      case LoyaltyRank.bronze:
        return 499;
      case LoyaltyRank.silver:
        return 1499;
      case LoyaltyRank.gold:
        return 3999;
      case LoyaltyRank.diamond:
        return 999999;
    }
  }

  int? get nextRankThreshold {
    switch (this) {
      case LoyaltyRank.bronze:
        return 500;
      case LoyaltyRank.silver:
        return 1500;
      case LoyaltyRank.gold:
        return 4000;
      case LoyaltyRank.diamond:
        return null;
    }
  }

  LoyaltyRank? get nextRank {
    switch (this) {
      case LoyaltyRank.bronze:
        return LoyaltyRank.silver;
      case LoyaltyRank.silver:
        return LoyaltyRank.gold;
      case LoyaltyRank.gold:
        return LoyaltyRank.diamond;
      case LoyaltyRank.diamond:
        return null;
    }
  }

  String getLocalizedName(AppStrings strings) {
    switch (this) {
      case LoyaltyRank.bronze:
        return strings.rankBronze;
      case LoyaltyRank.silver:
        return strings.rankSilver;
      case LoyaltyRank.gold:
        return strings.rankGold;
      case LoyaltyRank.diamond:
        return strings.rankDiamond;
    }
  }

  String getLocalizedPerk(AppStrings strings) {
    switch (this) {
      case LoyaltyRank.bronze:
        return strings.perkBronze;
      case LoyaltyRank.silver:
        return strings.perkSilver;
      case LoyaltyRank.gold:
        return strings.perkGold;
      case LoyaltyRank.diamond:
        return strings.perkDiamond;
    }
  }

  static LoyaltyRank fromString(String? raw) {
    if (raw == null) return LoyaltyRank.bronze;
    switch (raw.toLowerCase()) {
      case 'diamond':
        return LoyaltyRank.diamond;
      case 'gold':
        return LoyaltyRank.gold;
      case 'silver':
        return LoyaltyRank.silver;
      case 'bronze':
      default:
        return LoyaltyRank.bronze;
    }
  }
}

class LoyaltyService {
  LoyaltyService._();

  /// Calculates real StylePoints from transparent user activity.
  static int calculateStylePoints({
    required double profileProgress,
    required bool isEmailVerified,
    int referralCount = 0,
    int aiUsageCount = 0,
    int coinActivity = 0,
  }) {
    final profilePts = (profileProgress.clamp(0.0, 1.0) * 300).round();
    final emailPts = isEmailVerified ? 100 : 0;
    final referralPts = (referralCount.clamp(0, 999999)) * 150;
    final aiPts = (aiUsageCount.clamp(0, 999999)) * 10;
    final coinPts = (coinActivity.clamp(0, 99999999)) ~/ 10;
    return profilePts + emailPts + referralPts + aiPts + coinPts;
  }

  /// Maps StylePoints to progressive Loyalty Rank.
  static LoyaltyRank getRank(int points) {
    if (points >= 4000) return LoyaltyRank.diamond;
    if (points >= 1500) return LoyaltyRank.gold;
    if (points >= 500) return LoyaltyRank.silver;
    return LoyaltyRank.bronze;
  }

  /// Calculates progress (0.0 - 1.0) towards the next rank.
  static double calculateProgressToNextRank(int points) {
    final rank = getRank(points);
    final nextThreshold = rank.nextRankThreshold;
    if (nextThreshold == null) return 1.0;
    final currentTierMin = rank.minPoints;
    final totalRange = nextThreshold - currentTierMin;
    if (totalRange <= 0) return 1.0;
    final progress = (points - currentTierMin) / totalRange;
    return progress.clamp(0.0, 1.0);
  }
}
