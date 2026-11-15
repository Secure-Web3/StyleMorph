class ModuleConfig {
  final String id;
  final String titleFa;
  final String descriptionFa;
  final bool isEnabled;
  final bool isMaintenance;
  final String maintenanceNotice;
  final bool aiAutoTagging;
  final int dailyFreeQuota;
  final int maxItemLimit;
  final bool allowGuestAccess;
  final bool require2FA;

  const ModuleConfig({
    required this.id,
    required this.titleFa,
    required this.descriptionFa,
    this.isEnabled = true,
    this.isMaintenance = false,
    this.maintenanceNotice = 'این بخش موقتاً جهت به‌روزرسانی در دسترس نمی‌باشد.',
    this.aiAutoTagging = true,
    this.dailyFreeQuota = 5,
    this.maxItemLimit = 200,
    this.allowGuestAccess = false,
    this.require2FA = false,
  });

  ModuleConfig copyWith({
    String? id,
    String? titleFa,
    String? descriptionFa,
    bool? isEnabled,
    bool? isMaintenance,
    String? maintenanceNotice,
    bool? aiAutoTagging,
    int? dailyFreeQuota,
    int? maxItemLimit,
    bool? allowGuestAccess,
    bool? require2FA,
  }) {
    return ModuleConfig(
      id: id ?? this.id,
      titleFa: titleFa ?? this.titleFa,
      descriptionFa: descriptionFa ?? this.descriptionFa,
      isEnabled: isEnabled ?? this.isEnabled,
      isMaintenance: isMaintenance ?? this.isMaintenance,
      maintenanceNotice: maintenanceNotice ?? this.maintenanceNotice,
      aiAutoTagging: aiAutoTagging ?? this.aiAutoTagging,
      dailyFreeQuota: dailyFreeQuota ?? this.dailyFreeQuota,
      maxItemLimit: maxItemLimit ?? this.maxItemLimit,
      allowGuestAccess: allowGuestAccess ?? this.allowGuestAccess,
      require2FA: require2FA ?? this.require2FA,
    );
  }
}
