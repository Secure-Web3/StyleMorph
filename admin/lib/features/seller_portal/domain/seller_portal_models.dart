class SellerProductItem {
  final String id;
  final String title;
  final String category;
  final int priceToman;
  final String redirectUrl;
  final bool isActive;
  final int viewsCount;
  final int clicksCount;
  final int tryOnCount;
  final String approvalStatus;

  const SellerProductItem({
    required this.id,
    required this.title,
    required this.category,
    required this.priceToman,
    required this.redirectUrl,
    required this.isActive,
    required this.viewsCount,
    required this.clicksCount,
    required this.tryOnCount,
    this.approvalStatus = 'APPROVED',
  });

  SellerProductItem copyWith({
    String? id,
    String? title,
    String? category,
    int? priceToman,
    String? redirectUrl,
    bool? isActive,
    int? viewsCount,
    int? clicksCount,
    int? tryOnCount,
    String? approvalStatus,
  }) {
    return SellerProductItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      priceToman: priceToman ?? this.priceToman,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      isActive: isActive ?? this.isActive,
      viewsCount: viewsCount ?? this.viewsCount,
      clicksCount: clicksCount ?? this.clicksCount,
      tryOnCount: tryOnCount ?? this.tryOnCount,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }
}

class SellerCampaignItem {
  final String id;
  final String title;
  final int dailyBudgetToman;
  final int spentBudgetToman;
  final int cpcBidToman;
  final String targetModule;
  final bool isActive;

  const SellerCampaignItem({
    required this.id,
    required this.title,
    required this.dailyBudgetToman,
    required this.spentBudgetToman,
    required this.cpcBidToman,
    required this.targetModule,
    required this.isActive,
  });

  SellerCampaignItem copyWith({
    String? id,
    String? title,
    int? dailyBudgetToman,
    int? spentBudgetToman,
    int? cpcBidToman,
    String? targetModule,
    bool? isActive,
  }) {
    return SellerCampaignItem(
      id: id ?? this.id,
      title: title ?? this.title,
      dailyBudgetToman: dailyBudgetToman ?? this.dailyBudgetToman,
      spentBudgetToman: spentBudgetToman ?? this.spentBudgetToman,
      cpcBidToman: cpcBidToman ?? this.cpcBidToman,
      targetModule: targetModule ?? this.targetModule,
      isActive: isActive ?? this.isActive,
    );
  }
}
