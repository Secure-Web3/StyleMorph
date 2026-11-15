import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/finance/domain/transaction_model.dart';
import '../../features/modules/domain/module_config.dart';
import '../../features/ai_gateway/domain/ai_gateway_models.dart';
import '../../features/sellers/domain/seller_models.dart';
import '../../features/settings/domain/settings_models.dart';
import '../../features/ads/domain/ads_models.dart';
import '../../features/support/domain/support_models.dart';
import '../../features/seller_portal/domain/seller_portal_models.dart';

enum AuthGateRole {
  landing,
  admin,
  seller,
  consumerWebapp,
}

// ---------------------------------------------------------------------------
// 1. Auth & Portal State
// ---------------------------------------------------------------------------
final authRoleProvider =
    StateNotifierProvider<AuthRoleNotifier, AuthGateRole>((ref) {
  return AuthRoleNotifier();
});

class AuthRoleNotifier extends StateNotifier<AuthGateRole> {
  AuthRoleNotifier() : super(AuthGateRole.landing);

  void selectRole(AuthGateRole role) {
    state = role;
  }

  void logout() {
    state = AuthGateRole.landing;
  }
}

// ---------------------------------------------------------------------------
// 2. Navigation State
// ---------------------------------------------------------------------------
final selectedSectionIndexProvider = StateProvider<int>((ref) => 0);
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// 3. Finance & Ledger State
// ---------------------------------------------------------------------------
final ledgerSearchProvider = StateProvider<String>((ref) => '');
final ledgerGatewayFilterProvider =
    StateProvider<PaymentGatewayType>((ref) => PaymentGatewayType.all);
final ledgerStatusFilterProvider = StateProvider<TxStatus?>((ref) => null);
final ledgerCurrentPageProvider = StateProvider<int>((ref) => 1);
final ledgerRowsPerPageProvider = StateProvider<int>((ref) => 10);

final ledgerTransactionsProvider =
    StateNotifierProvider<LedgerNotifier, List<TransactionRecord>>((ref) {
  return LedgerNotifier();
});

class LedgerNotifier extends StateNotifier<List<TransactionRecord>> {
  LedgerNotifier() : super(_generateInitialLedger());

  void reverseTransaction(String txId, String reason) {
    state = [
      for (final tx in state)
        if (tx.txId == txId)
          tx.copyWith(
            status: TxStatus.refunded,
            notes: 'استرداد آنی توسط مدیریت: $reason',
          )
        else
          tx,
    ];
  }

  void issueDirectRefund({
    required String userId,
    required String userName,
    required int amountCoins,
    required double amountUsd,
    required String reason,
  }) {
    final now = DateTime.now();
    final newTx = TransactionRecord(
      txId: 'TX-REFUND-${now.millisecondsSinceEpoch.toString().substring(7)}',
      idempotencyKey: 'refund-${now.microsecondsSinceEpoch}',
      operationType: TxOperationType.refund,
      userId: userId,
      userDisplayName: userName,
      gateway: PaymentGatewayType.wallet,
      amountCoins: amountCoins,
      amountUsd: amountUsd,
      cloudAiCost: 0.0,
      status: TxStatus.refunded,
      timestamp: now,
      notes: 'استرداد از طریق تیکت پشتیبانی: $reason',
    );
    state = [newTx, ...state];
  }

  static List<TransactionRecord> _generateInitialLedger() {
    final now = DateTime.now();
    return [
      TransactionRecord(
        txId: 'TX-2026-98401',
        idempotencyKey: '7c9e6679-7425-40de-944b-e07fc1f90ae7',
        operationType: TxOperationType.capture,
        userId: 'usr_88190',
        userDisplayName: 'سارا رضایی',
        gateway: PaymentGatewayType.stripe,
        amountCoins: 350,
        amountUsd: 6.99,
        cloudAiCost: 0.052,
        status: TxStatus.settled,
        timestamp: now.subtract(const Duration(minutes: 14)),
        notes: 'تولید پکیج پرتره استودیویی آتلیه',
      ),
      TransactionRecord(
        txId: 'TX-2026-98402',
        idempotencyKey: '3a1f94d0-1b55-4673-9a36-398246f48123',
        operationType: TxOperationType.topUp,
        userId: 'usr_77120',
        userDisplayName: 'امیرحسین پارسا',
        gateway: PaymentGatewayType.iap,
        amountCoins: 1200,
        amountUsd: 19.99,
        cloudAiCost: 0.000,
        status: TxStatus.settled,
        timestamp: now.subtract(const Duration(minutes: 32)),
        notes: 'بسته طلایی سکه StyleCoin از طریق کافه‌بازار',
      ),
      TransactionRecord(
        txId: 'TX-2026-98403',
        idempotencyKey: 'fd02c48b-ea7a-426c-8438-cb58d56b4df9',
        operationType: TxOperationType.hold,
        userId: 'usr_99341',
        userDisplayName: 'مهسا نوری',
        gateway: PaymentGatewayType.wallet,
        amountCoins: 120,
        amountUsd: 2.40,
        cloudAiCost: 0.021,
        status: TxStatus.held,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 5)),
        notes: 'پردازش در صف پرو مجازی لباس ماکسی',
      ),
      TransactionRecord(
        txId: 'TX-2026-98404',
        idempotencyKey: '23ac8500-b6f7-497b-9993-9c84e1b8b72e',
        operationType: TxOperationType.capture,
        userId: 'usr_44102',
        userDisplayName: 'کیان رستمی',
        gateway: PaymentGatewayType.crypto,
        amountCoins: 2500,
        amountUsd: 45.00,
        cloudAiCost: 0.000,
        status: TxStatus.settled,
        timestamp: now.subtract(const Duration(hours: 2, minutes: 18)),
        notes: 'شارژ تتر روی شبکه TON',
      ),
      TransactionRecord(
        txId: 'TX-2026-98405',
        idempotencyKey: 'ee8b2496-512a-4ad9-bf0c-d49242967268',
        operationType: TxOperationType.release,
        userId: 'usr_12903',
        userDisplayName: 'آیدا کریمی',
        gateway: PaymentGatewayType.wallet,
        amountCoins: 80,
        amountUsd: 1.60,
        cloudAiCost: 0.000,
        status: TxStatus.released,
        timestamp: now.subtract(const Duration(hours: 3, minutes: 40)),
        notes: 'آزادسازی سکه به دلیل انصراف پیش از پردازش',
      ),
      TransactionRecord(
        txId: 'TX-2026-98406',
        idempotencyKey: '603c4f74-3e91-4cf5-b1a7-196d445fb5bb',
        operationType: TxOperationType.capture,
        userId: 'usr_66311',
        userDisplayName: 'نیلوفر زمانی',
        gateway: PaymentGatewayType.iap,
        amountCoins: 600,
        amountUsd: 9.99,
        cloudAiCost: 0.048,
        status: TxStatus.settled,
        timestamp: now.subtract(const Duration(hours: 5, minutes: 12)),
        notes: 'اسکن کامل پوست و مشاوره روتین زیبایی',
      ),
      TransactionRecord(
        txId: 'TX-2026-98407',
        idempotencyKey: '8e27c0fa-2384-48e0-bb15-5853c8ea7b75',
        operationType: TxOperationType.refund,
        userId: 'usr_33019',
        userDisplayName: 'فرزاد اکبری',
        gateway: PaymentGatewayType.stripe,
        amountCoins: 150,
        amountUsd: 3.00,
        cloudAiCost: 0.035,
        status: TxStatus.refunded,
        timestamp: now.subtract(const Duration(hours: 6, minutes: 55)),
        notes: 'مرجوعی به دلیل خطای زمان‌بندی مدل Imagen',
      ),
      TransactionRecord(
        txId: 'TX-2026-98408',
        idempotencyKey: '0bb24e68-cb06-4444-a15f-6c174ecf1a92',
        operationType: TxOperationType.adjustment,
        userId: 'usr_88190',
        userDisplayName: 'سارا رضایی',
        gateway: PaymentGatewayType.wallet,
        amountCoins: 50,
        amountUsd: 1.00,
        cloudAiCost: 0.000,
        status: TxStatus.settled,
        timestamp: now.subtract(const Duration(hours: 9, minutes: 20)),
        notes: 'پاداش تکمیل دعوت دوستان (Referral Bonus)',
      ),
      TransactionRecord(
        txId: 'TX-2026-98409',
        idempotencyKey: '59a58434-601e-4501-9a99-9ea2cf4b971a',
        operationType: TxOperationType.capture,
        userId: 'usr_55029',
        userDisplayName: 'پویا طاهری',
        gateway: PaymentGatewayType.stripe,
        amountCoins: 180,
        amountUsd: 3.50,
        cloudAiCost: 0.024,
        status: TxStatus.settled,
        timestamp: now.subtract(const Duration(hours: 11, minutes: 4)),
        notes: 'جلسه تعاملی چت صوتی با استایلیست شخصی',
      ),
      TransactionRecord(
        txId: 'TX-2026-98410',
        idempotencyKey: 'a36e84d1-c244-48ea-aa87-0b5c16b60e6e',
        operationType: TxOperationType.topUp,
        userId: 'usr_99812',
        userDisplayName: 'مریم احمدی',
        gateway: PaymentGatewayType.crypto,
        amountCoins: 5000,
        amountUsd: 85.00,
        cloudAiCost: 0.000,
        status: TxStatus.settled,
        timestamp: now.subtract(const Duration(hours: 14, minutes: 30)),
        notes: 'خرید سازمانی بسته پرمیوم آتلیه مد',
      ),
      TransactionRecord(
        txId: 'TX-2026-98411',
        idempotencyKey: '44e26219-cba8-4c8e-a611-37fae4293f77',
        operationType: TxOperationType.capture,
        userId: 'usr_22019',
        userDisplayName: 'داوود صادقی',
        gateway: PaymentGatewayType.wallet,
        amountCoins: 90,
        amountUsd: 1.80,
        cloudAiCost: 0.019,
        status: TxStatus.settled,
        timestamp: now.subtract(const Duration(hours: 17, minutes: 10)),
        notes: 'تولید ویدیو کوتاه مدلینگ کت‌واک',
      ),
      TransactionRecord(
        txId: 'TX-2026-98412',
        idempotencyKey: 'c80cb1aa-850d-400d-959d-64eb683e8fa5',
        operationType: TxOperationType.hold,
        userId: 'usr_77410',
        userDisplayName: 'زهرا موسوی',
        gateway: PaymentGatewayType.wallet,
        amountCoins: 110,
        amountUsd: 2.20,
        cloudAiCost: 0.015,
        status: TxStatus.held,
        timestamp: now.subtract(const Duration(hours: 20, minutes: 45)),
        notes: 'پردازش پیشرفته کمد و برچسب‌گذاری هوشمند',
      ),
      TransactionRecord(
        txId: 'TX-2026-98413',
        idempotencyKey: 'e492f25b-aee9-43c1-b0be-3a479ffce344',
        operationType: TxOperationType.capture,
        userId: 'usr_10294',
        userDisplayName: 'علی شجاعی',
        gateway: PaymentGatewayType.iap,
        amountCoins: 350,
        amountUsd: 6.99,
        cloudAiCost: 0.041,
        status: TxStatus.settled,
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        notes: 'پرو مجازی کفش ورزشی و ست لباس فرم',
      ),
      TransactionRecord(
        txId: 'TX-2026-98414',
        idempotencyKey: 'bb9a8e03-75a7-4780-9284-5f1ea6650be0',
        operationType: TxOperationType.adjustment,
        userId: 'usr_44102',
        userDisplayName: 'کیان رستمی',
        gateway: PaymentGatewayType.wallet,
        amountCoins: 100,
        amountUsd: 2.00,
        cloudAiCost: 0.000,
        status: TxStatus.settled,
        timestamp: now.subtract(const Duration(days: 1, hours: 5)),
        notes: 'تسویه بستانکاری ارجاع خرید فروشگاهی',
      ),
      TransactionRecord(
        txId: 'TX-2026-98415',
        idempotencyKey: '11fe4682-8b9a-4c91-9aa2-4cbe90ee1c18',
        operationType: TxOperationType.capture,
        userId: 'usr_33190',
        userDisplayName: 'نگار ابراهیمی',
        gateway: PaymentGatewayType.stripe,
        amountCoins: 220,
        amountUsd: 4.50,
        cloudAiCost: 0.033,
        status: TxStatus.settled,
        timestamp: now.subtract(const Duration(days: 1, hours: 9)),
        notes: 'طراحی ست اکسسوری و عینک با هوش مصنوعی',
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// 4. Mobile App Modules Manager State
// ---------------------------------------------------------------------------
final modulesConfigProvider =
    StateNotifierProvider<ModulesConfigNotifier, List<ModuleConfig>>((ref) {
  return ModulesConfigNotifier();
});

class ModulesConfigNotifier extends StateNotifier<List<ModuleConfig>> {
  ModulesConfigNotifier() : super(_initialModules());

  void updateModule(String id, ModuleConfig Function(ModuleConfig old) update) {
    state = [
      for (final mod in state)
        if (mod.id == id) update(mod) else mod,
    ];
  }

  static List<ModuleConfig> _initialModules() {
    return const [
      ModuleConfig(
        id: 'profile',
        titleFa: 'پروفایل و هویت (Profile)',
        descriptionFa:
            'مدیریت شناسنامه، همگام‌سازی AI DNA، کیف پول و حریم خصوصی آناتومی.',
        isEnabled: true,
        isMaintenance: false,
        dailyFreeQuota: 10,
        maxItemLimit: 50,
        allowGuestAccess: true,
        require2FA: true,
      ),
      ModuleConfig(
        id: 'wardrobe',
        titleFa: 'کمد مجازی (Virtual Wardrobe)',
        descriptionFa:
            'آرشیو هوشمند البسه، استخراج خودکار تگ‌ها با Vision و کش هش تصاویر.',
        isEnabled: true,
        isMaintenance: false,
        aiAutoTagging: true,
        dailyFreeQuota: 15,
        maxItemLimit: 300,
        allowGuestAccess: false,
        require2FA: false,
      ),
      ModuleConfig(
        id: 'shop',
        titleFa: 'فروشگاه و بنچمارک قیمت (Shop)',
        descriptionFa:
            'پیشنهاد کالاهای فروشندگان، هدایت افیلیت و مزایده تبلیغات پروموت‌شده.',
        isEnabled: true,
        isMaintenance: false,
        dailyFreeQuota: 50,
        maxItemLimit: 1000,
        allowGuestAccess: true,
        require2FA: false,
      ),
      ModuleConfig(
        id: 'stylist',
        titleFa: 'دستیار استایلیست و اتاق پرو (AI Stylist)',
        descriptionFa:
            'اتاق چت تعاملی، ست لباس و پرو مجازی با مدل‌های چندوجهی هوش مصنوعی.',
        isEnabled: true,
        isMaintenance: false,
        aiAutoTagging: true,
        dailyFreeQuota: 5,
        maxItemLimit: 50,
        allowGuestAccess: false,
        require2FA: false,
      ),
      ModuleConfig(
        id: 'atelier',
        titleFa: 'آتلیه مجازی (Virtual Atelier)',
        descriptionFa:
            'تولید پرتره مد با کیفیت بالا، عکاسی استودیویی و کلیپ‌های کوتاه مدلینگ.',
        isEnabled: true,
        isMaintenance: false,
        aiAutoTagging: false,
        dailyFreeQuota: 3,
        maxItemLimit: 100,
        allowGuestAccess: false,
        require2FA: false,
      ),
      ModuleConfig(
        id: 'wellness',
        titleFa: 'تندرستی و زیبایی (Wellness & Beauty)',
        descriptionFa:
            'تحلیل پوست، فرم چهره، تناسب اندام و ارائه روتین‌های روزانه مراقبت شخصی.',
        isEnabled: true,
        isMaintenance: false,
        aiAutoTagging: true,
        dailyFreeQuota: 3,
        maxItemLimit: 20,
        allowGuestAccess: false,
        require2FA: true,
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// 5. AI Gateway & Pricing State
// ---------------------------------------------------------------------------
final gcpKeyPoolProvider =
    StateNotifierProvider<GcpKeyPoolNotifier, List<GcpApiKeyItem>>((ref) {
  return GcpKeyPoolNotifier();
});

class GcpKeyPoolNotifier extends StateNotifier<List<GcpApiKeyItem>> {
  GcpKeyPoolNotifier() : super(_initialKeys());

  void toggleAutoDisable(String keyId) {
    state = [
      for (final k in state)
        if (k.keyId == keyId)
          k.copyWith(autoDisableEnabled: !k.autoDisableEnabled)
        else
          k,
    ];
  }

  void rotateKey(String keyId) {
    state = [
      for (final k in state)
        if (k.keyId == keyId)
          k.copyWith(
            status: KeyStatus.active,
            latencyMs: 42,
            maskedKey: 'AIzaSy...${DateTime.now().millisecond}',
          )
        else
          k,
    ];
  }

  static List<GcpApiKeyItem> _initialKeys() {
    return const [
      GcpApiKeyItem(
        keyId: 'key-gcp-eu-01',
        alias: 'سرور اصلی اروپا (Prod Frankfurt)',
        maskedKey: 'AIzaSyC74e...8f91',
        gcpProjectId: 'stylemorph-prod-eu',
        region: 'europe-west3',
        officialBilledCost: 412.30,
        billedLimit: 500.00,
        liveUnbilledCost: 28.45,
        latencyMs: 46,
        status: KeyStatus.active,
        autoDisableEnabled: true,
      ),
      GcpApiKeyItem(
        keyId: 'key-gcp-eu-02',
        alias: 'پشتیبان بلژیک (Prod Belgium)',
        maskedKey: 'AIzaSyB12x...44d9',
        gcpProjectId: 'stylemorph-prod-eu2',
        region: 'europe-west1',
        officialBilledCost: 289.10,
        billedLimit: 500.00,
        liveUnbilledCost: 14.20,
        latencyMs: 58,
        status: KeyStatus.active,
        autoDisableEnabled: true,
      ),
      GcpApiKeyItem(
        keyId: 'key-gcp-us-03',
        alias: 'بالانسر آمریکا (Prod Iowa)',
        maskedKey: 'AIzaSyA90q...11a2',
        gcpProjectId: 'stylemorph-prod-us',
        region: 'us-central1',
        officialBilledCost: 610.80,
        billedLimit: 800.00,
        liveUnbilledCost: 44.90,
        latencyMs: 114,
        status: KeyStatus.degraded,
        autoDisableEnabled: true,
      ),
      GcpApiKeyItem(
        keyId: 'key-gcp-dev-04',
        alias: 'محیط آزمایشی (Dev Sandbox)',
        maskedKey: 'AIzaSyD55k...77e8',
        gcpProjectId: 'stylemorph-dev',
        region: 'europe-west3',
        officialBilledCost: 48.60,
        billedLimit: 100.00,
        liveUnbilledCost: 3.10,
        latencyMs: 52,
        status: KeyStatus.active,
        autoDisableEnabled: false,
      ),
      GcpApiKeyItem(
        keyId: 'key-gcp-backup-05',
        alias: 'رزرو اضطراری (Failover Key)',
        maskedKey: 'AIzaSyZ01m...99c0',
        gcpProjectId: 'stylemorph-emergency',
        region: 'europe-west4',
        officialBilledCost: 0.00,
        billedLimit: 300.00,
        liveUnbilledCost: 0.00,
        latencyMs: 0,
        status: KeyStatus.quarantined,
        autoDisableEnabled: true,
      ),
    ];
  }
}

final serviceRoutingProvider = StateNotifierProvider<ServiceRoutingNotifier,
    List<ServiceRoutingConfig>>((ref) {
  return ServiceRoutingNotifier();
});

class ServiceRoutingNotifier extends StateNotifier<List<ServiceRoutingConfig>> {
  ServiceRoutingNotifier() : super(_initialRouting());

  void updateRouting(String serviceId, String primary, String fallback) {
    state = [
      for (final r in state)
        if (r.serviceId == serviceId)
          r.copyWith(primaryModel: primary, fallbackModel: fallback)
        else
          r,
    ];
  }

  static List<ServiceRoutingConfig> _initialRouting() {
    return const [
      ServiceRoutingConfig(
        serviceId: 'stylist_chat',
        serviceTitleFa: 'دستیار استایلیست متنی و گفتگوی صوتی',
        serviceDescriptionFa:
            'پاسخگویی به سوالات مد، تولید استایل و هماهنگی ست لباس',
        primaryModel: 'gemini-2.0-flash',
        fallbackModel: 'gemini-1.5-pro',
        maxTokens: 2048,
        costPerCall: 0.0015,
      ),
      ServiceRoutingConfig(
        serviceId: 'wardrobe_vision',
        serviceTitleFa: 'پردازش ویژگی‌های کمد و بینایی ماشین',
        serviceDescriptionFa:
            'شناسایی رنگ، متریال، فرم یقه و استخراج تگ‌های کمد لباس',
        primaryModel: 'gemini-2.0-flash',
        fallbackModel: 'gemini-1.5-flash',
        maxTokens: 1024,
        costPerCall: 0.0022,
      ),
      ServiceRoutingConfig(
        serviceId: 'virtual_try_on',
        serviceTitleFa: 'پرو مجازی لباس و انطباق بدنی',
        serviceDescriptionFa:
            'پرو دقیق لباس روی تصویر کاربر با حفظ آناتومی و بافت پارچه',
        primaryModel: 'flux-1.1-pro',
        fallbackModel: 'imagen-3-ultra',
        maxTokens: 4096,
        costPerCall: 0.0380,
      ),
      ServiceRoutingConfig(
        serviceId: 'atelier_portraits',
        serviceTitleFa: 'آتلیه عکس پرتره و فوتورئالیسم',
        serviceDescriptionFa:
            'خلق پرتره‌های استودیویی با نورپردازی و تم‌های مد روز',
        primaryModel: 'imagen-3-ultra',
        fallbackModel: 'flux-1.1-pro',
        maxTokens: 4096,
        costPerCall: 0.0400,
      ),
      ServiceRoutingConfig(
        serviceId: 'wellness_analysis',
        serviceTitleFa: 'تحلیل سلامت، پوست و فرم صورت',
        serviceDescriptionFa:
            'شناسایی نوع پوست، تناسب اندام و ارائه برنامه مراقبتی',
        primaryModel: 'gemini-2.0-flash',
        fallbackModel: 'gemini-1.5-pro',
        maxTokens: 3000,
        costPerCall: 0.0035,
      ),
    ];
  }
}

final visualQaConfigProvider =
    StateNotifierProvider<VisualQaNotifier, VisualQaConfig>((ref) {
  return VisualQaNotifier();
});

class VisualQaNotifier extends StateNotifier<VisualQaConfig> {
  VisualQaNotifier() : super(const VisualQaConfig());

  void toggleUseMockAi(bool val) {
    state = state.copyWith(useMockAi: val);
  }

  void toggleAnatomicalCorrection(bool val) {
    state = state.copyWith(anatomicalCorrectionEnabled: val);
  }

  void setAnatomicalThreshold(double val) {
    state = state.copyWith(anatomicalConfidenceThreshold: val);
  }

  void toggleWatermark(bool val) {
    state = state.copyWith(watermarkEnabled: val);
  }

  void setWatermarkText(String text) {
    state = state.copyWith(watermarkText: text);
  }

  void toggleLogAllPrompts(bool val) {
    state = state.copyWith(logAllPrompts: val);
  }
}

// ---------------------------------------------------------------------------
// 6. Section 5: Seller Governance State
// ---------------------------------------------------------------------------
final merchantsQueueProvider =
    StateNotifierProvider<MerchantsQueueNotifier, List<MerchantModel>>((ref) {
  return MerchantsQueueNotifier();
});

class MerchantsQueueNotifier extends StateNotifier<List<MerchantModel>> {
  MerchantsQueueNotifier() : super(_initialMerchants());

  void approveMerchant(String id) {
    state = [
      for (final m in state)
        if (m.id == id)
          m.copyWith(status: MerchantStatus.approved, rejectionReason: '')
        else
          m,
    ];
  }

  void rejectMerchant(String id, String reason) {
    state = [
      for (final m in state)
        if (m.id == id)
          m.copyWith(status: MerchantStatus.rejected, rejectionReason: reason)
        else
          m,
    ];
  }

  static List<MerchantModel> _initialMerchants() {
    final now = DateTime.now();
    return [
      MerchantModel(
        id: 'shop_zagros_01',
        storeName: 'بوتیک پوشاک زنانه زاگرس',
        ownerName: 'حمیدرضا کمالی',
        phone: '۰۹۱۲۱۱۱۴۵۶۷',
        nationalId: '۰۰۷۶۵۴۳۲۱۰',
        city: 'تهران - سعادت‌آباد',
        status: MerchantStatus.pending,
        registrationDate: now.subtract(const Duration(hours: 3)),
        catalogCount: 24,
        walletBalanceToman: 2500000,
      ),
      MerchantModel(
        id: 'shop_denim_02',
        storeName: 'استودیو طراحی جین الیت',
        ownerName: 'سپیده اسدی',
        phone: '۰۹۳۵۲۲۲۸۸۹۹',
        nationalId: '۰۴۵۱۱۲۲۳۳۴',
        city: 'اصفهان - چهارباغ',
        status: MerchantStatus.pending,
        registrationDate: now.subtract(const Duration(hours: 7)),
        catalogCount: 16,
        walletBalanceToman: 1800000,
      ),
      MerchantModel(
        id: 'shop_leather_03',
        storeName: 'چرم دست‌دوز مارال',
        ownerName: 'فرهاد نصیری',
        phone: '۰۹۱۴۳۳۳۵۵۴۴',
        nationalId: '۱۳۷۸۸۹۹۰۰۱',
        city: 'تبریز - بازار بزرگ',
        status: MerchantStatus.approved,
        registrationDate: now.subtract(const Duration(days: 4)),
        catalogCount: 42,
        walletBalanceToman: 8500000,
      ),
      MerchantModel(
        id: 'shop_scarf_04',
        storeName: 'روسری و شال ابریشم دیبا',
        ownerName: 'نگین حیدری',
        phone: '۰۹۱۹۴۴۴۷۷۲۲',
        nationalId: '۰۰۲۹۹۸۸۷۷۶',
        city: 'مشهد - احمدآباد',
        status: MerchantStatus.approved,
        registrationDate: now.subtract(const Duration(days: 8)),
        catalogCount: 31,
        walletBalanceToman: 3200000,
      ),
    ];
  }
}

final productsQueueProvider =
    StateNotifierProvider<ProductsQueueNotifier, List<ProductApprovalModel>>(
        (ref) {
  return ProductsQueueNotifier();
});

class ProductsQueueNotifier extends StateNotifier<List<ProductApprovalModel>> {
  ProductsQueueNotifier() : super(_initialProducts());

  void approveProduct(String id) {
    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(status: MerchantStatus.approved, rejectionReason: '')
        else
          p,
    ];
  }

  void rejectProduct(String id, String reason) {
    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(status: MerchantStatus.rejected, rejectionReason: reason)
        else
          p,
    ];
  }

  static List<ProductApprovalModel> _initialProducts() {
    final now = DateTime.now();
    return [
      ProductApprovalModel(
        id: 'prod_901',
        merchantId: 'shop_zagros_01',
        merchantName: 'بوتیک زاگرس',
        title: 'پالتو فوتر بلند زمستانه مدل ونیز',
        category: 'پالتو و بارانی',
        priceToman: 3850000,
        redirectUrl: 'https://zagros-boutique.ir/products/venice-coat',
        status: MerchantStatus.pending,
        submittedDate: now.subtract(const Duration(hours: 2)),
      ),
      ProductApprovalModel(
        id: 'prod_902',
        merchantId: 'shop_denim_02',
        merchantName: 'جین الیت',
        title: 'شلوار واید لگ زغالی اسلیم فیت',
        category: 'شلوار و دامن',
        priceToman: 1450000,
        redirectUrl: 'https://elite-denim.com/wide-leg-charcoal',
        status: MerchantStatus.pending,
        submittedDate: now.subtract(const Duration(hours: 5)),
      ),
      ProductApprovalModel(
        id: 'prod_903',
        merchantId: 'shop_leather_03',
        merchantName: 'چرم مارال',
        title: 'کیف دوشی چرم طبیعی ایتالیایی',
        category: 'کیف و کفش',
        priceToman: 4200000,
        redirectUrl: 'https://maral-leather.ir/bag-it-2026',
        status: MerchantStatus.approved,
        submittedDate: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}

final sellerFinancialRulesProvider = StateNotifierProvider<
    SellerFinancialRulesNotifier, SellerFinancialRules>((ref) {
  return SellerFinancialRulesNotifier();
});

class SellerFinancialRulesNotifier extends StateNotifier<SellerFinancialRules> {
  SellerFinancialRulesNotifier() : super(const SellerFinancialRules());

  void updateRules({
    int? cpc,
    int? cpm,
    int? stdCommission,
    int? premCommission,
    int? cpt,
  }) {
    state = state.copyWith(
      cpcBaseRateToman: cpc,
      cpmBaseRateToman: cpm,
      commissionTierStandard: stdCommission,
      commissionTierPremium: premCommission,
      costPerTryOnCoins: cpt,
    );
  }
}

// ---------------------------------------------------------------------------
// 7. Section 6: Infrastructure & Security Settings State
// ---------------------------------------------------------------------------
final otaStringsProvider =
    StateNotifierProvider<OtaStringsNotifier, List<OtaStringItem>>((ref) {
  return OtaStringsNotifier();
});

class OtaStringsNotifier extends StateNotifier<List<OtaStringItem>> {
  OtaStringsNotifier() : super(_initialStrings());

  void updateString(String key, {String? fa, String? ar, String? en}) {
    state = [
      for (final s in state)
        if (s.key == key)
          s.copyWith(defaultFa: fa, ar: ar, en: en)
        else
          s,
    ];
  }

  static List<OtaStringItem> _initialStrings() {
    return const [
      OtaStringItem(
        key: 'home_welcome_title',
        defaultFa: 'کمد هوشمند و استایل اختصاصی شما',
        ar: 'خزانتك الذكية وأسلوبك المخصص',
        en: 'Your Smart Wardrobe & Personalized Style',
      ),
      OtaStringItem(
        key: 'stylist_cta_button',
        defaultFa: 'گفتگو با استایلیست شخصی',
        ar: 'محادثة مع خبير الأناقة',
        en: 'Chat with Personal Stylist',
      ),
      OtaStringItem(
        key: 'try_on_quota_exceeded',
        defaultFa: 'سقف پرو رایگان روزانه شما تکمیل شد.',
        ar: 'تم استهلاك رصيدك المجاني لتجربة الملابس اليوم.',
        en: 'Your free daily try-on quota has been reached.',
      ),
      OtaStringItem(
        key: 'wallet_topup_banner',
        defaultFa: 'جشنواره شارژ کیف پول با ۲۰٪ سکه هدیه',
        ar: 'مهرجان شحن المحفظة مع ۲۰٪ عملات إضافية',
        en: 'Wallet Top-up Festival: Get 20% Bonus Coins',
      ),
    ];
  }
}

final storeReviewerShieldProvider = StateNotifierProvider<
    StoreReviewerShieldNotifier, StoreReviewerShieldConfig>((ref) {
  return StoreReviewerShieldNotifier();
});

class StoreReviewerShieldNotifier
    extends StateNotifier<StoreReviewerShieldConfig> {
  StoreReviewerShieldNotifier() : super(const StoreReviewerShieldConfig());

  void toggleShield(bool val) {
    state = state.copyWith(isShieldActive: val);
  }

  void setBuildNumbers(String builds) {
    state = state.copyWith(underReviewBuildNumbers: builds);
  }

  void togglePromoBanner(bool val) {
    state = state.copyWith(promoBannerEnabled: val);
  }

  void setPromoBannerText(String text) {
    state = state.copyWith(promoBannerText: text);
  }
}

final userRbacListProvider =
    StateNotifierProvider<UserRbacNotifier, List<UserRbacItem>>((ref) {
  return UserRbacNotifier();
});

class UserRbacNotifier extends StateNotifier<List<UserRbacItem>> {
  UserRbacNotifier() : super(_initialUsers());

  void revokeSession(String uid) {
    state = [
      for (final u in state)
        if (u.uid == uid)
          u.copyWith(
            isSessionRevoked: true,
            activeSessionId: 'REVOKED_${DateTime.now().millisecondsSinceEpoch}',
          )
        else
          u,
    ];
  }

  static List<UserRbacItem> _initialUsers() {
    return const [
      UserRbacItem(
        uid: 'usr_88190',
        displayName: 'سارا رضایی',
        phone: '۰۹۱۲۸۸۸۹۹۰۰',
        deviceModel: 'iPhone 15 Pro Max',
        osVersion: 'iOS 18.2',
        ipAddress: '5.122.90.14',
        activeSessionId: 'sess_ios_a1b2c3d4e5',
        role: 'کاربر طلایی (Gold)',
      ),
      UserRbacItem(
        uid: 'usr_77120',
        displayName: 'امیرحسین پارسا',
        phone: '۰۹۳۵۱۱۱۴۴۷۷',
        deviceModel: 'Samsung Galaxy S24 Ultra',
        osVersion: 'Android 15',
        ipAddress: '185.140.22.8',
        activeSessionId: 'sess_and_f6g7h8i9j0',
        role: 'کاربر عادی (Standard)',
      ),
      UserRbacItem(
        uid: 'adm_9021',
        displayName: 'مهندس سهرابی',
        phone: '۰۹۱۲۰۰۰۱۱۱۱',
        deviceModel: 'MacBook Pro M3 Max (Web)',
        osVersion: 'macOS 15.1',
        ipAddress: '2.144.18.99',
        activeSessionId: 'sess_adm_root_7788',
        role: 'مدیر ارشد کلان (Super Admin)',
      ),
    ];
  }
}

final subAdminsProvider =
    StateNotifierProvider<SubAdminsNotifier, List<SubAdminModel>>((ref) {
  return SubAdminsNotifier();
});

class SubAdminsNotifier extends StateNotifier<List<SubAdminModel>> {
  SubAdminsNotifier() : super(_initialSubAdmins());

  void addSubAdmin(SubAdminModel subAdmin) {
    state = [...state, subAdmin];
  }

  static List<SubAdminModel> _initialSubAdmins() {
    return const [
      SubAdminModel(
        id: 'adm_fin_01',
        name: 'علی تقوی',
        email: 'taghavi@stylemorph.com',
        roleTitle: 'ناظر امور مالی و لجر',
        permissions: ['READ_LEDGER', 'REVERSE_TX', 'EXPORT_CSV'],
      ),
      SubAdminModel(
        id: 'adm_mod_02',
        name: 'ندا قاسمی',
        email: 'ghasemi@stylemorph.com',
        roleTitle: 'مدیر تایید کاتالوگ و فروشندگان',
        permissions: ['APPROVE_SELLER', 'APPROVE_PRODUCT', 'REJECT_QUEUE'],
      ),
    ];
  }
}

final botWebhooksProvider =
    StateNotifierProvider<BotWebhooksNotifier, List<BotWebhookItem>>((ref) {
  return BotWebhooksNotifier();
});

class BotWebhooksNotifier extends StateNotifier<List<BotWebhookItem>> {
  BotWebhooksNotifier() : super(_initialWebhooks());

  void toggleWebhook(String id) {
    state = [
      for (final b in state)
        if (b.id == id) b.copyWith(isActive: !b.isActive) else b,
    ];
  }

  void addWebhook(BotWebhookItem item) {
    state = [...state, item];
  }

  static List<BotWebhookItem> _initialWebhooks() {
    final now = DateTime.now();
    return [
      BotWebhookItem(
        id: 'wh_tg_alerts',
        platform: 'Telegram',
        name: 'کانال هشدارهای بحرانی سرور ابری',
        url: 'https://api.telegram.org/bot778899/sendMessage?chat_id=-100123',
        isOperational: false,
        isActive: true,
        lastPing: now.subtract(const Duration(minutes: 12)),
      ),
      BotWebhookItem(
        id: 'wh_ds_ops',
        platform: 'Discord',
        name: 'دیسکورد عملیات فنی و مدارشکن (Circuit Breaker)',
        url: 'https://discord.com/api/webhooks/123456/tokenABC',
        isOperational: true,
        isActive: true,
        lastPing: now.subtract(const Duration(minutes: 4)),
      ),
    ];
  }
}

final auditLogsProvider =
    StateNotifierProvider<AuditLogsNotifier, List<AuditLogItem>>((ref) {
  return AuditLogsNotifier();
});

class AuditLogsNotifier extends StateNotifier<List<AuditLogItem>> {
  AuditLogsNotifier() : super(_initialAuditLogs());

  void logAction({
    required String adminId,
    required String adminName,
    required String actionType,
    required String targetEntity,
    required String ip,
  }) {
    final now = DateTime.now();
    final newLog = AuditLogItem(
      logId: 'LOG-${now.millisecondsSinceEpoch}',
      timestamp: now,
      adminId: adminId,
      adminName: adminName,
      actionType: actionType,
      targetEntity: targetEntity,
      ipAddress: ip,
      sha256Hash:
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
    state = [newLog, ...state];
  }

  static List<AuditLogItem> _initialAuditLogs() {
    final now = DateTime.now();
    return [
      AuditLogItem(
        logId: 'LOG-9921',
        timestamp: now.subtract(const Duration(minutes: 18)),
        adminId: 'adm_9021',
        adminName: 'مهندس سهرابی',
        actionType: 'HOT_RELOAD_API_KEY',
        targetEntity: 'GCP Key: key-gcp-eu-01',
        ipAddress: '2.144.18.99',
        sha256Hash:
            '4a6e872c67b93a02d8472535031b288a74e50cd8427f32d3080ff524e93fb206',
      ),
      AuditLogItem(
        logId: 'LOG-9920',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 12)),
        adminId: 'adm_9021',
        adminName: 'مهندس سهرابی',
        actionType: 'UPDATE_REMOTE_CONFIG',
        targetEntity: 'Module: stylist (dailyFreeQuota -> 5)',
        ipAddress: '2.144.18.99',
        sha256Hash:
            '72808c1a601267812f866164f9c5d0f666f7f2b963e6361a6b0c20499cf9bc03',
      ),
      AuditLogItem(
        logId: 'LOG-9919',
        timestamp: now.subtract(const Duration(hours: 3)),
        adminId: 'adm_fin_01',
        adminName: 'علی تقوی',
        actionType: 'REVERSE_TRANSACTION',
        targetEntity: 'TX-2026-98407 (Amount: \$3.00)',
        ipAddress: '5.200.11.45',
        sha256Hash:
            '35b804d2091448bfa9df0e2c8427909b0b43521b36d01bc18bf2d950fef99298',
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// 8. Section 7: AdMob & AI Sponsoring State
// ---------------------------------------------------------------------------
final adMobConfigProvider =
    StateNotifierProvider<AdMobConfigNotifier, AdMobConfig>((ref) {
  return AdMobConfigNotifier();
});

class AdMobConfigNotifier extends StateNotifier<AdMobConfig> {
  AdMobConfigNotifier() : super(const AdMobConfig());

  void toggleAdMob(bool val) {
    state = state.copyWith(isAdMobEnabled: val);
  }

  void updateInterstitial({int? freq, int? cooldown}) {
    state = state.copyWith(
      interstitialFrequency: freq,
      interstitialCooldownSec: cooldown,
    );
  }

  void updateRewarded({int? coins, int? cap, String? ssvUrl}) {
    state = state.copyWith(
      rewardedCoinsPerVideo: coins,
      rewardedDailyCap: cap,
      rewardedSsvUrl: ssvUrl,
    );
  }

  void toggleAppOpen(bool val) {
    state = state.copyWith(appOpenAdsEnabled: val);
  }
}

final aiSponsoringConfigProvider =
    StateNotifierProvider<AiSponsoringConfigNotifier, AiSponsoringConfig>(
        (ref) {
  return AiSponsoringConfigNotifier();
});

class AiSponsoringConfigNotifier extends StateNotifier<AiSponsoringConfig> {
  AiSponsoringConfigNotifier() : super(const AiSponsoringConfig());

  void setWeight(int weight) {
    state = state.copyWith(stylistRecommendationWeightPct: weight);
  }

  void toggleWatermark(bool val) {
    state = state.copyWith(sponsoredWatermarkEnabled: val);
  }

  void setWatermarkText(String text) {
    state = state.copyWith(brandWatermarkText: text);
  }

  void setFloor(int floor) {
    state = state.copyWith(cpcAuctionFloorToman: floor);
  }
}

final adaptiveGenerosityConfigProvider = StateNotifierProvider<
    AdaptiveGenerosityNotifier, AdaptiveGenerosityConfig>((ref) {
  return AdaptiveGenerosityNotifier();
});

class AdaptiveGenerosityNotifier
    extends StateNotifier<AdaptiveGenerosityConfig> {
  AdaptiveGenerosityNotifier() : super(const AdaptiveGenerosityConfig());

  void toggleEnabled(bool val) {
    state = state.copyWith(isEnabled: val);
  }

  void updateTargetRatio(double ratio) {
    state = state.copyWith(targetAdToAiRatio: ratio);
  }

  void updateMultiplier(double multiplier) {
    state = state.copyWith(currentMultiplier: multiplier);
  }

  void updateDailyCoins(int coins) {
    state = state.copyWith(dynamicDailyFreeCoins: coins);
  }
}

// ---------------------------------------------------------------------------
// 9. Section 8: Support & Ticketing State
// ---------------------------------------------------------------------------
final supportTicketsProvider =
    StateNotifierProvider<SupportTicketsNotifier, List<SupportTicketItem>>(
        (ref) {
  return SupportTicketsNotifier(ref);
});

class SupportTicketsNotifier extends StateNotifier<List<SupportTicketItem>> {
  final Ref _ref;
  SupportTicketsNotifier(this._ref) : super(_initialTickets());

  void refundAndResolveTicket({
    required String ticketId,
    required String reason,
  }) {
    final target = state.firstWhere((t) => t.ticketId == ticketId);

    // 1. Issue ledger refund
    _ref.read(ledgerTransactionsProvider.notifier).issueDirectRefund(
          userId: target.userId,
          userName: target.userName,
          amountCoins: 150,
          amountUsd: 3.00,
          reason: 'پشتیبانی تیکت $ticketId: $reason',
        );

    // 2. Mark ticket resolved with system audit reply
    state = [
      for (final t in state)
        if (t.ticketId == ticketId)
          t.copyWith(
            status: TicketStatus.resolved,
            messages: [
              ...t.messages,
              TicketChatMessage(
                sender: 'مدیریت و لجر هوشمند',
                isFromAdmin: true,
                message:
                    'مبلغ ۱۵۰ سکه با موفقیت به کیف پول بازگردانده شد. دلیل: $reason',
                timestamp: DateTime.now(),
              ),
            ],
          )
        else
          t,
    ];
  }

  void replyTicket(String ticketId, String text) {
    state = [
      for (final t in state)
        if (t.ticketId == ticketId)
          t.copyWith(
            status: TicketStatus.inProgress,
            messages: [
              ...t.messages,
              TicketChatMessage(
                sender: 'کارشناس پشتیبانی StyleMorph',
                isFromAdmin: true,
                message: text,
                timestamp: DateTime.now(),
              ),
            ],
          )
        else
          t,
    ];
  }

  static List<SupportTicketItem> _initialTickets() {
    final now = DateTime.now();
    return [
      SupportTicketItem(
        ticketId: 'TCK-2026-809',
        userId: 'usr_88190',
        userName: 'سارا رضایی',
        userEmail: 'sara.rezaei@gmail.com',
        userCoinBalance: 320,
        subject: 'کسر سکه در اتاق پرو بدون نمایش خروجی نهایی',
        category: 'خطای هوش مصنوعی و کسر سکه',
        priority: TicketPriority.critical,
        status: TicketStatus.open,
        createdAt: now.subtract(const Duration(minutes: 24)),
        deviceModel: 'iPhone 15 Pro Max',
        osVersion: 'iOS 18.2',
        appVersion: 'v2.4.1 (Build 108)',
        ipAddress: '5.122.90.14',
        relatedTxId: 'TX-2026-98403',
        recentAiErrorLog:
            'GCP Error 429 [RESOURCE_EXHAUSTED] on Imagen-3 Task #9812-FLUX timeout 120s',
        messages: [
          TicketChatMessage(
            sender: 'سارا رضایی',
            isFromAdmin: false,
            message:
                'سلام، من می‌خواستم یک کت پاییزه رو پرو کنم، سکه از حساب من کم شد ولی برنامه خطای تایم‌اوت داد و تصویری برام نیومد. لطفاً سکه‌هام رو برگردونید.',
            timestamp: now.subtract(const Duration(minutes: 24)),
          ),
        ],
      ),
      SupportTicketItem(
        ticketId: 'TCK-2026-808',
        userId: 'usr_77120',
        userName: 'امیرحسین پارسا',
        userEmail: 'parsa.amir@yahoo.com',
        userCoinBalance: 1200,
        subject: 'تغییر شماره موبایل و همگام‌سازی کمد مجازی',
        category: 'حساب کاربری و حریم خصوصی',
        priority: TicketPriority.medium,
        status: TicketStatus.inProgress,
        createdAt: now.subtract(const Duration(hours: 2)),
        deviceModel: 'Samsung Galaxy S24 Ultra',
        osVersion: 'Android 15',
        appVersion: 'v2.4.0 (Build 105)',
        ipAddress: '185.140.22.8',
        messages: [
          TicketChatMessage(
            sender: 'امیرحسین پارسا',
            isFromAdmin: false,
            message:
                'سلام وقت بخیر، من خط موبایلم عوض شده چطور کمد و ست‌های ذخیره شده‌ام رو به شماره جدید منتقل کنم؟',
            timestamp: now.subtract(const Duration(hours: 2)),
          ),
          TicketChatMessage(
            sender: 'کارشناس پشتیبانی StyleMorph',
            isFromAdmin: true,
            message:
                'درود بر شما، جهت تأیید مالکیت کد پیگیری آخرین تراکنش خود را ارسال فرمایید.',
            timestamp: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      SupportTicketItem(
        ticketId: 'TCK-2026-807',
        userId: 'usr_33019',
        userName: 'فرزاد اکبری',
        userEmail: 'farzad.akbari@live.com',
        userCoinBalance: 40,
        subject: 'درخواست فاکتور رسمی خرید بسته سازمانی سکه',
        category: 'امور مالی و فاکتور',
        priority: TicketPriority.low,
        status: TicketStatus.resolved,
        createdAt: now.subtract(const Duration(days: 1)),
        deviceModel: 'Xiaomi 14 Pro',
        osVersion: 'HyperOS 2.0',
        appVersion: 'v2.4.1 (Build 108)',
        ipAddress: '91.99.12.3',
        relatedTxId: 'TX-2026-98404',
        messages: [
          TicketChatMessage(
            sender: 'فرزاد اکبری',
            isFromAdmin: false,
            message: 'فاکتور رسمی با شناسه ملی شرکت ارسال شد؟',
            timestamp: now.subtract(const Duration(days: 1)),
          ),
          TicketChatMessage(
            sender: 'کارشناس امور مالی',
            isFromAdmin: true,
            message: 'بله فاکتور با مهر الکترونیکی به ایمیل شما ارسال گردید.',
            timestamp: now.subtract(const Duration(hours: 22)),
          ),
        ],
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// 10. Isolated Seller Portal Workspace State
// ---------------------------------------------------------------------------
final sellerProductsProvider = StateNotifierProvider<SellerProductsNotifier,
    List<SellerProductItem>>((ref) {
  return SellerProductsNotifier();
});

class SellerProductsNotifier extends StateNotifier<List<SellerProductItem>> {
  SellerProductsNotifier() : super(_initialProducts());

  void toggleProductActive(String id) {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(isActive: !p.isActive) else p,
    ];
  }

  void addProduct(SellerProductItem item) {
    state = [item, ...state];
  }

  static List<SellerProductItem> _initialProducts() {
    return const [
      SellerProductItem(
        id: 'sp_101',
        title: 'کت فوتر پشمی زاگرس مدل Milan',
        category: 'پالتو و بارانی',
        priceToman: 4200000,
        redirectUrl: 'https://zagros-boutique.ir/item/milan',
        isActive: true,
        viewsCount: 1840,
        clicksCount: 312,
        tryOnCount: 145,
      ),
      SellerProductItem(
        id: 'sp_102',
        title: 'ست کت‌وشلوار کرپ مازراتی زنانه',
        category: 'کت و دامن',
        priceToman: 3500000,
        redirectUrl: 'https://zagros-boutique.ir/item/crepe-suit',
        isActive: true,
        viewsCount: 2450,
        clicksCount: 420,
        tryOnCount: 260,
      ),
      SellerProductItem(
        id: 'sp_103',
        title: 'شومیز ساتن ابریشم با طرح اختصاصی',
        category: 'شومیز و بلوز',
        priceToman: 1850000,
        redirectUrl: 'https://zagros-boutique.ir/item/silk-blouse',
        isActive: false,
        viewsCount: 920,
        clicksCount: 110,
        tryOnCount: 48,
      ),
    ];
  }
}

final sellerCampaignsProvider = StateNotifierProvider<SellerCampaignsNotifier,
    List<SellerCampaignItem>>((ref) {
  return SellerCampaignsNotifier();
});

class SellerCampaignsNotifier extends StateNotifier<List<SellerCampaignItem>> {
  SellerCampaignsNotifier() : super(_initialCampaigns());

  void toggleCampaign(String id) {
    state = [
      for (final c in state)
        if (c.id == id) c.copyWith(isActive: !c.isActive) else c,
    ];
  }

  void addCampaign(SellerCampaignItem item) {
    state = [item, ...state];
  }

  static List<SellerCampaignItem> _initialCampaigns() {
    return const [
      SellerCampaignItem(
        id: 'cmp_01',
        title: 'کمپین معرفی در استایلیست شخصی (AI Stylist)',
        dailyBudgetToman: 500000,
        spentBudgetToman: 320000,
        cpcBidToman: 2000,
        targetModule: 'پیشنهاد مستقیم در چت استایلیست',
        isActive: true,
      ),
      SellerCampaignItem(
        id: 'cmp_02',
        title: 'پروموشن در تب فروشگاه و بنچمارک قیمت',
        dailyBudgetToman: 300000,
        spentBudgetToman: 145000,
        cpcBidToman: 1500,
        targetModule: 'کالای اسپانسر شده در رتبه اول جستجو',
        isActive: true,
      ),
    ];
  }
}

