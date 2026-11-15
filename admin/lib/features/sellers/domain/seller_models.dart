enum MerchantStatus {
  pending(label: 'در انتظار تأیید', color: 0xFFD97706),
  approved(label: 'تأیید شده و فعال', color: 0xFF16A34A),
  rejected(label: 'رد شده', color: 0xFFDC2626);

  final String label;
  final int color;
  const MerchantStatus({required this.label, required this.color});
}

class MerchantModel {
  final String id;
  final String storeName;
  final String ownerName;
  final String phone;
  final String nationalId;
  final String city;
  final MerchantStatus status;
  final DateTime registrationDate;
  final int catalogCount;
  final int walletBalanceToman;
  final String rejectionReason;

  const MerchantModel({
    required this.id,
    required this.storeName,
    required this.ownerName,
    required this.phone,
    required this.nationalId,
    required this.city,
    required this.status,
    required this.registrationDate,
    required this.catalogCount,
    required this.walletBalanceToman,
    this.rejectionReason = '',
  });

  MerchantModel copyWith({
    String? id,
    String? storeName,
    String? ownerName,
    String? phone,
    String? nationalId,
    String? city,
    MerchantStatus? status,
    DateTime? registrationDate,
    int? catalogCount,
    int? walletBalanceToman,
    String? rejectionReason,
  }) {
    return MerchantModel(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      nationalId: nationalId ?? this.nationalId,
      city: city ?? this.city,
      status: status ?? this.status,
      registrationDate: registrationDate ?? this.registrationDate,
      catalogCount: catalogCount ?? this.catalogCount,
      walletBalanceToman: walletBalanceToman ?? this.walletBalanceToman,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

class ProductApprovalModel {
  final String id;
  final String merchantId;
  final String merchantName;
  final String title;
  final String category;
  final int priceToman;
  final String redirectUrl;
  final MerchantStatus status;
  final DateTime submittedDate;
  final String rejectionReason;

  const ProductApprovalModel({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.title,
    required this.category,
    required this.priceToman,
    required this.redirectUrl,
    required this.status,
    required this.submittedDate,
    this.rejectionReason = '',
  });

  ProductApprovalModel copyWith({
    String? id,
    String? merchantId,
    String? merchantName,
    String? title,
    String? category,
    int? priceToman,
    String? redirectUrl,
    MerchantStatus? status,
    DateTime? submittedDate,
    String? rejectionReason,
  }) {
    return ProductApprovalModel(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      title: title ?? this.title,
      category: category ?? this.category,
      priceToman: priceToman ?? this.priceToman,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      status: status ?? this.status,
      submittedDate: submittedDate ?? this.submittedDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

class SellerFinancialRules {
  final int cpcBaseRateToman;
  final int cpmBaseRateToman;
  final int commissionTierStandard;
  final int commissionTierPremium;
  final int costPerTryOnCoins;

  const SellerFinancialRules({
    this.cpcBaseRateToman = 1500,
    this.cpmBaseRateToman = 25000,
    this.commissionTierStandard = 12,
    this.commissionTierPremium = 8,
    this.costPerTryOnCoins = 40,
  });

  SellerFinancialRules copyWith({
    int? cpcBaseRateToman,
    int? cpmBaseRateToman,
    int? commissionTierStandard,
    int? commissionTierPremium,
    int? costPerTryOnCoins,
  }) {
    return SellerFinancialRules(
      cpcBaseRateToman: cpcBaseRateToman ?? this.cpcBaseRateToman,
      cpmBaseRateToman: cpmBaseRateToman ?? this.cpmBaseRateToman,
      commissionTierStandard:
          commissionTierStandard ?? this.commissionTierStandard,
      commissionTierPremium:
          commissionTierPremium ?? this.commissionTierPremium,
      costPerTryOnCoins: costPerTryOnCoins ?? this.costPerTryOnCoins,
    );
  }
}
