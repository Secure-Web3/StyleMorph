class OtaStringItem {
  final String key;
  final String defaultFa;
  final String ar;
  final String en;

  const OtaStringItem({
    required this.key,
    required this.defaultFa,
    required this.ar,
    required this.en,
  });

  OtaStringItem copyWith({
    String? key,
    String? defaultFa,
    String? ar,
    String? en,
  }) {
    return OtaStringItem(
      key: key ?? this.key,
      defaultFa: defaultFa ?? this.defaultFa,
      ar: ar ?? this.ar,
      en: en ?? this.en,
    );
  }
}

class StoreReviewerShieldConfig {
  final bool isShieldActive;
  final String underReviewBuildNumbers;
  final bool promoBannerEnabled;
  final String promoBannerText;

  const StoreReviewerShieldConfig({
    this.isShieldActive = false,
    this.underReviewBuildNumbers = '108, 109',
    this.promoBannerEnabled = true,
    this.promoBannerText = 'جشنواره بهاره: ۵۰٪ سکه رایگان در اولین شارژ کیف پول StyleCoin',
  });

  StoreReviewerShieldConfig copyWith({
    bool? isShieldActive,
    String? underReviewBuildNumbers,
    bool? promoBannerEnabled,
    String? promoBannerText,
  }) {
    return StoreReviewerShieldConfig(
      isShieldActive: isShieldActive ?? this.isShieldActive,
      underReviewBuildNumbers:
          underReviewBuildNumbers ?? this.underReviewBuildNumbers,
      promoBannerEnabled: promoBannerEnabled ?? this.promoBannerEnabled,
      promoBannerText: promoBannerText ?? this.promoBannerText,
    );
  }
}

class UserRbacItem {
  final String uid;
  final String displayName;
  final String phone;
  final String deviceModel;
  final String osVersion;
  final String ipAddress;
  final String activeSessionId;
  final String role;
  final bool isSessionRevoked;

  const UserRbacItem({
    required this.uid,
    required this.displayName,
    required this.phone,
    required this.deviceModel,
    required this.osVersion,
    required this.ipAddress,
    required this.activeSessionId,
    required this.role,
    this.isSessionRevoked = false,
  });

  UserRbacItem copyWith({
    String? uid,
    String? displayName,
    String? phone,
    String? deviceModel,
    String? osVersion,
    String? ipAddress,
    String? activeSessionId,
    String? role,
    bool? isSessionRevoked,
  }) {
    return UserRbacItem(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      ipAddress: ipAddress ?? this.ipAddress,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      role: role ?? this.role,
      isSessionRevoked: isSessionRevoked ?? this.isSessionRevoked,
    );
  }
}

class SubAdminModel {
  final String id;
  final String name;
  final String email;
  final String roleTitle;
  final List<String> permissions;

  const SubAdminModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roleTitle,
    required this.permissions,
  });
}

class BotWebhookItem {
  final String id;
  final String platform;
  final String name;
  final String url;
  final bool isOperational;
  final bool isActive;
  final DateTime lastPing;

  const BotWebhookItem({
    required this.id,
    required this.platform,
    required this.name,
    required this.url,
    required this.isOperational,
    required this.isActive,
    required this.lastPing,
  });

  BotWebhookItem copyWith({
    String? id,
    String? platform,
    String? name,
    String? url,
    bool? isOperational,
    bool? isActive,
    DateTime? lastPing,
  }) {
    return BotWebhookItem(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      name: name ?? this.name,
      url: url ?? this.url,
      isOperational: isOperational ?? this.isOperational,
      isActive: isActive ?? this.isActive,
      lastPing: lastPing ?? this.lastPing,
    );
  }
}

class AuditLogItem {
  final String logId;
  final DateTime timestamp;
  final String adminId;
  final String adminName;
  final String actionType;
  final String targetEntity;
  final String ipAddress;
  final String sha256Hash;

  const AuditLogItem({
    required this.logId,
    required this.timestamp,
    required this.adminId,
    required this.adminName,
    required this.actionType,
    required this.targetEntity,
    required this.ipAddress,
    required this.sha256Hash,
  });
}
