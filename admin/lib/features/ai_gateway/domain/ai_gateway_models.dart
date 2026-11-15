enum KeyStatus {
  active(label: 'فعال و سالم', color: 0xFF16A34A),
  degraded(label: 'تأخیر بالا / هشدار', color: 0xFFD97706),
  quarantined(label: 'قرنطینه شده', color: 0xFFDC2626);

  final String label;
  final int color;
  const KeyStatus({required this.label, required this.color});
}

class GcpApiKeyItem {
  final String keyId;
  final String alias;
  final String maskedKey;
  final String gcpProjectId;
  final String region;
  final double officialBilledCost;
  final double billedLimit;
  final double liveUnbilledCost;
  final int latencyMs;
  final KeyStatus status;
  final bool autoDisableEnabled;

  const GcpApiKeyItem({
    required this.keyId,
    required this.alias,
    required this.maskedKey,
    required this.gcpProjectId,
    required this.region,
    required this.officialBilledCost,
    required this.billedLimit,
    required this.liveUnbilledCost,
    required this.latencyMs,
    required this.status,
    required this.autoDisableEnabled,
  });

  GcpApiKeyItem copyWith({
    String? keyId,
    String? alias,
    String? maskedKey,
    String? gcpProjectId,
    String? region,
    double? officialBilledCost,
    double? billedLimit,
    double? liveUnbilledCost,
    int? latencyMs,
    KeyStatus? status,
    bool? autoDisableEnabled,
  }) {
    return GcpApiKeyItem(
      keyId: keyId ?? this.keyId,
      alias: alias ?? this.alias,
      maskedKey: maskedKey ?? this.maskedKey,
      gcpProjectId: gcpProjectId ?? this.gcpProjectId,
      region: region ?? this.region,
      officialBilledCost: officialBilledCost ?? this.officialBilledCost,
      billedLimit: billedLimit ?? this.billedLimit,
      liveUnbilledCost: liveUnbilledCost ?? this.liveUnbilledCost,
      latencyMs: latencyMs ?? this.latencyMs,
      status: status ?? this.status,
      autoDisableEnabled: autoDisableEnabled ?? this.autoDisableEnabled,
    );
  }
}

class ServiceRoutingConfig {
  final String serviceId;
  final String serviceTitleFa;
  final String serviceDescriptionFa;
  final String primaryModel;
  final String fallbackModel;
  final int maxTokens;
  final double costPerCall;

  const ServiceRoutingConfig({
    required this.serviceId,
    required this.serviceTitleFa,
    required this.serviceDescriptionFa,
    required this.primaryModel,
    required this.fallbackModel,
    required this.maxTokens,
    required this.costPerCall,
  });

  ServiceRoutingConfig copyWith({
    String? serviceId,
    String? serviceTitleFa,
    String? serviceDescriptionFa,
    String? primaryModel,
    String? fallbackModel,
    int? maxTokens,
    double? costPerCall,
  }) {
    return ServiceRoutingConfig(
      serviceId: serviceId ?? this.serviceId,
      serviceTitleFa: serviceTitleFa ?? this.serviceTitleFa,
      serviceDescriptionFa: serviceDescriptionFa ?? this.serviceDescriptionFa,
      primaryModel: primaryModel ?? this.primaryModel,
      fallbackModel: fallbackModel ?? this.fallbackModel,
      maxTokens: maxTokens ?? this.maxTokens,
      costPerCall: costPerCall ?? this.costPerCall,
    );
  }
}

class VisualQaConfig {
  final bool anatomicalCorrectionEnabled;
  final double anatomicalConfidenceThreshold;
  final bool watermarkEnabled;
  final String watermarkText;
  final bool useMockAi;
  final bool logAllPrompts;

  const VisualQaConfig({
    this.anatomicalCorrectionEnabled = true,
    this.anatomicalConfidenceThreshold = 0.95,
    this.watermarkEnabled = true,
    this.watermarkText = 'StyleMorph AI Preview',
    this.useMockAi = false,
    this.logAllPrompts = false,
  });

  VisualQaConfig copyWith({
    bool? anatomicalCorrectionEnabled,
    double? anatomicalConfidenceThreshold,
    bool? watermarkEnabled,
    String? watermarkText,
    bool? useMockAi,
    bool? logAllPrompts,
  }) {
    return VisualQaConfig(
      anatomicalCorrectionEnabled:
          anatomicalCorrectionEnabled ?? this.anatomicalCorrectionEnabled,
      anatomicalConfidenceThreshold:
          anatomicalConfidenceThreshold ?? this.anatomicalConfidenceThreshold,
      watermarkEnabled: watermarkEnabled ?? this.watermarkEnabled,
      watermarkText: watermarkText ?? this.watermarkText,
      useMockAi: useMockAi ?? this.useMockAi,
      logAllPrompts: logAllPrompts ?? this.logAllPrompts,
    );
  }
}
