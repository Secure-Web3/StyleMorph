import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/ai_gateway_client.dart';
import '../../../core/services/health_service.dart';
import '../../../core/state/app_state.dart';
import '../data/stylist_repository.dart';
import '../domain/stylist_models.dart';

enum TryOnStatus {
  idle,
  holdingCoins,
  analyzingAnatomy,
  renderingGarment,
  completed,
}

class StylistState {
  final String activeOccasion;
  final List<StylistOutfit> outfits;
  final List<ChatMessage> chatMessages;
  final int dailyFreeChatsLeft;
  final TryOnStatus tryOnStatus;
  final TryOnTier selectedTier;
  final String? lastGeneratedImage;
  final AiGenerationResult? lastTryOnResult;

  const StylistState({
    this.activeOccasion = 'روزمره',
    required this.outfits,
    required this.chatMessages,
    this.dailyFreeChatsLeft = 8,
    this.tryOnStatus = TryOnStatus.idle,
    this.selectedTier = TryOnTier.standard,
    this.lastGeneratedImage,
    this.lastTryOnResult,
  });

  StylistState copyWith({
    String? activeOccasion,
    List<StylistOutfit>? outfits,
    List<ChatMessage>? chatMessages,
    int? dailyFreeChatsLeft,
    TryOnStatus? tryOnStatus,
    TryOnTier? selectedTier,
    String? lastGeneratedImage,
    AiGenerationResult? lastTryOnResult,
    bool clearLastTryOnResult = false,
  }) {
    return StylistState(
      activeOccasion: activeOccasion ?? this.activeOccasion,
      outfits: outfits ?? this.outfits,
      chatMessages: chatMessages ?? this.chatMessages,
      dailyFreeChatsLeft: dailyFreeChatsLeft ?? this.dailyFreeChatsLeft,
      tryOnStatus: tryOnStatus ?? this.tryOnStatus,
      selectedTier: selectedTier ?? this.selectedTier,
      lastGeneratedImage: lastGeneratedImage ?? this.lastGeneratedImage,
      lastTryOnResult: clearLastTryOnResult
          ? null
          : (lastTryOnResult ?? this.lastTryOnResult),
    );
  }

  List<StylistOutfit> get filteredOutfits {
    return outfits.where((o) => o.occasion == activeOccasion).toList();
  }
}

class StylistNotifier extends StateNotifier<StylistState> {
  final StylistRepository _repo;
  final Ref _ref;

  StylistNotifier(this._repo, this._ref)
    : super(
        StylistState(
          outfits: _repo.getOutfits(),
          chatMessages: _repo.getInitialMessages(),
        ),
      );

  void setOccasion(String occ) {
    state = state.copyWith(activeOccasion: occ);
  }

  void setSelectedTier(TryOnTier tier) {
    state = state.copyWith(selectedTier: tier);
  }

  void toggleLock(String id) {
    _repo.toggleLock(id);
    state = state.copyWith(outfits: _repo.getOutfits());
  }

  void toggleSave(String id) {
    _repo.toggleSave(id);
    state = state.copyWith(outfits: _repo.getOutfits());
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updated = List<ChatMessage>.from(state.chatMessages)..add(userMsg);
    state = state.copyWith(
      chatMessages: updated,
      dailyFreeChatsLeft: (state.dailyFreeChatsLeft - 1).clamp(0, 10),
    );

    // AI automated reply incorporating biometric context if wearable is connected
    Future.delayed(const Duration(milliseconds: 600), () {
      final health = _ref.read(healthServiceProvider);
      final String replyText;

      if (health.isConnected &&
          health.sleepHours != null &&
          health.sleepHours! < 5.5) {
        replyText =
            'طبق دیتای ساعت هوشمند (${health.sourceDevice.hardwareModel})، دیشب ${health.sleepHours} ساعت خوابیدی؛ استایل امروز با الیاف کژوال، تنفس‌پذیر و بدون احساس خستگی از کمد پیشنهاد شد.';
      } else if (health.isConnected &&
          health.steps != null &&
          health.steps! >= 10000) {
        replyText =
            'با توجه به تحرک بالای امروز (${health.steps} گام)، کفش سبک ارگونومیک و لایه‌بندی تنفس‌پذیر را در این ترکیب استایل اولویت قرار دادم.';
      } else {
        replyText =
            'بر اساس سبک انتخابی «${state.activeOccasion}» و آیتم‌های کمد، این ترکیب هارمونی رنگی بهتری با تناژ پوست شما ایجاد می‌کند.';
      }

      final aiMsg = ChatMessage(
        id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
        text: replyText,
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        chatMessages: List<ChatMessage>.from(state.chatMessages)..add(aiMsg),
      );
    });
  }

  Future<void> runTryOnSimulation(
    StylistOutfit outfit, {
    bool simulateFailure = false,
  }) async {
    final cost = state.selectedTier.coinCost;
    final currentCoins = _ref.read(appStateProvider).coins;

    if (currentCoins < cost) {
      throw Exception('موجودی سکه برای این سطح کیفیت کافی نیست.');
    }

    final gateway = _ref.read(aiGatewayClientProvider);
    final localeCode = _ref.read(localeProvider).code;
    final idempotencyKey = gateway.generateIdempotencyKey('tryon_${outfit.id}');

    // Step 1: Hold coins before invoking AI Gateway
    state = state.copyWith(
      tryOnStatus: TryOnStatus.holdingCoins,
      clearLastTryOnResult: true,
    );
    _ref.read(appStateProvider.notifier).addCoins(-cost);

    try {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      // Step 2: Invoke AI Gateway (with automatic graceful offline fallback)
      state = state.copyWith(tryOnStatus: TryOnStatus.analyzingAnatomy);
      final qualityTier = switch (state.selectedTier) {
        TryOnTier.fast => AiQualityTier.fast,
        TryOnTier.standard => AiQualityTier.standard,
        TryOnTier.cinematic => AiQualityTier.cinematic,
      };

      final healthSnapshot = _ref.read(healthServiceProvider);
      final healthContext = healthSnapshot.isConnected
          ? healthSnapshot.toGatewayContext()
          : null;

      final result = await gateway.generate(
        userId: 'user_local_demo',
        serviceType: AiServiceType.virtualTryOn,
        qualityTier: qualityTier,
        prompt: 'Virtual try-on for ${outfit.title} (${outfit.occasion})',
        garmentId: outfit.id,
        locale: localeCode,
        idempotencyKey: idempotencyKey,
        healthContext: healthContext,
        simulateFailure: simulateFailure,
      );
      if (!mounted) return;

      // Step 3: Rendering garment & finalizing capture
      state = state.copyWith(tryOnStatus: TryOnStatus.renderingGarment);
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      state = state.copyWith(
        tryOnStatus: TryOnStatus.completed,
        lastGeneratedImage: outfit.title,
        lastTryOnResult: result,
      );
    } catch (e) {
      // Automatic Release: refund held coins on AI failure or anatomical rejection
      if (mounted) {
        _ref.read(appStateProvider.notifier).addCoins(cost);
        state = state.copyWith(tryOnStatus: TryOnStatus.idle);
      }
      rethrow;
    }
  }

  void resetTryOnStatus() {
    state = state.copyWith(
      tryOnStatus: TryOnStatus.idle,
      clearLastTryOnResult: true,
    );
  }
}

final stylistRepositoryProvider = Provider<StylistRepository>(
  (_) => StylistRepository(),
);

final stylistProvider = StateNotifierProvider<StylistNotifier, StylistState>(
  (ref) => StylistNotifier(ref.read(stylistRepositoryProvider), ref),
);
