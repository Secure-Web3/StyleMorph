import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/ai_gateway_client.dart';
import '../../../core/state/app_state.dart';
import '../data/atelier_repository.dart';
import '../domain/atelier_models.dart';

class AtelierState {
  final String activeTab; // 'showcase' or 'creations'
  final String templateCategory;
  final String mediaType; // 'all', 'p', 'v'
  final String creationsFilter; // 'all', 'r', 'p', 'f'
  final List<AtelierTemplate> templates;
  final List<AtelierCreation> creations;
  final Set<int> wishlist;
  final bool isProUser;

  const AtelierState({
    this.activeTab = 'showcase',
    this.templateCategory = 'all',
    this.mediaType = 'all',
    this.creationsFilter = 'all',
    required this.templates,
    required this.creations,
    this.wishlist = const {},
    this.isProUser = true,
  });

  AtelierState copyWith({
    String? activeTab,
    String? templateCategory,
    String? mediaType,
    String? creationsFilter,
    List<AtelierTemplate>? templates,
    List<AtelierCreation>? creations,
    Set<int>? wishlist,
    bool? isProUser,
  }) {
    return AtelierState(
      activeTab: activeTab ?? this.activeTab,
      templateCategory: templateCategory ?? this.templateCategory,
      mediaType: mediaType ?? this.mediaType,
      creationsFilter: creationsFilter ?? this.creationsFilter,
      templates: templates ?? this.templates,
      creations: creations ?? this.creations,
      wishlist: wishlist ?? this.wishlist,
      isProUser: isProUser ?? this.isProUser,
    );
  }

  int get pendingCreationsCount {
    return creations.where((c) =>
        c.status == CreationStatus.queue ||
        c.status == CreationStatus.processing).length;
  }

  List<AtelierTemplate> get filteredTemplates {
    return templates.where((t) {
      if (templateCategory == 'fav' && !wishlist.contains(t.id)) {
        return false;
      }
      if (templateCategory != 'all' &&
          templateCategory != 'fav' &&
          t.category != templateCategory) {
        return false;
      }
      if (mediaType != 'all' && t.type != mediaType) {
        return false;
      }
      return true;
    }).toList();
  }

  List<AtelierCreation> get filteredCreations {
    return creations.where((c) {
      if (creationsFilter == 'r' && c.status != CreationStatus.ready) {
        return false;
      }
      if (creationsFilter == 'p' &&
          c.status != CreationStatus.queue &&
          c.status != CreationStatus.processing) {
        return false;
      }
      if (creationsFilter == 'f' && c.status != CreationStatus.failed) {
        return false;
      }
      return true;
    }).toList();
  }
}

class AtelierNotifier extends StateNotifier<AtelierState> {
  final Ref _ref;

  AtelierNotifier(AtelierRepository repo, this._ref)
      : super(
          AtelierState(
            templates: repo.getTemplates(),
            creations: repo.getCreations(),
          ),
        );

  void switchTab(String tab) {
    state = state.copyWith(activeTab: tab);
  }

  void setCategory(String cat) {
    state = state.copyWith(templateCategory: cat);
  }

  void setMediaType(String type) {
    state = state.copyWith(mediaType: type);
  }

  void setCreationsFilter(String filter) {
    state = state.copyWith(creationsFilter: filter);
  }

  void toggleWishlist(int id) {
    final next = Set<int>.from(state.wishlist);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(wishlist: next);
  }

  void generateTemplate(
    AtelierTemplate template, {
    bool simulateFailure = false,
  }) {
    final coins = _ref.read(appStateProvider).coins;
    if (coins < template.price) {
      throw Exception('موجودی سکه شما کافی نیست.');
    }

    // Hold coins upfront before dispatching to AI Gateway
    _ref.read(appStateProvider.notifier).addCoins(-template.price);

    final newCreation = AtelierCreation(
      id: DateTime.now().microsecondsSinceEpoch,
      templateId: template.id,
      templateTitle: template.name,
      type: template.type,
      status: CreationStatus.queue,
      progress: 10,
      date: 'همین حالا',
    );

    final updated = List<AtelierCreation>.from(state.creations)
      ..insert(0, newCreation);
    state = state.copyWith(creations: updated);

    unawaited(
      _processCreationJob(
        creationId: newCreation.id,
        template: template,
        refundOnFailure: true,
        simulateFailure: simulateFailure,
      ),
    );
  }

  Future<void> _processCreationJob({
    required int creationId,
    required AtelierTemplate template,
    required bool refundOnFailure,
    bool simulateFailure = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _updateProgress(creationId, CreationStatus.processing, 45);

    final gateway = _ref.read(aiGatewayClientProvider);
    final localeCode = _ref.read(localeProvider).code;
    final idempotencyKey =
        gateway.generateIdempotencyKey('atelier_${template.id}_$creationId');

    final serviceType = template.type == 'v'
        ? AiServiceType.atelierVideo
        : AiServiceType.atelierPhoto;
    final qualityTier = template.price <= 5
        ? AiQualityTier.fast
        : template.price <= 15
            ? AiQualityTier.standard
            : AiQualityTier.cinematic;

    try {
      final result = await gateway.generate(
        userId: 'user_local_demo',
        serviceType: serviceType,
        qualityTier: qualityTier,
        prompt: '${template.name}: ${template.description}',
        templateId: 'tpl_${template.id}',
        locale: localeCode,
        idempotencyKey: idempotencyKey,
        simulateFailure: simulateFailure,
      );
      if (!mounted) return;

      _updateProgress(creationId, CreationStatus.processing, 85);
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      _updateProgress(
        creationId,
        CreationStatus.ready,
        100,
        anatomicalScore: result.anatomicalScore,
        watermarkText: result.watermarkText,
        mediaUrl: result.mediaUrl,
        cacheHit: result.cacheHit,
      );
    } catch (_) {
      if (!mounted) return;
      if (refundOnFailure) {
        _ref.read(appStateProvider.notifier).addCoins(template.price);
      }
      _updateProgress(creationId, CreationStatus.failed, 0);
    }
  }

  void _updateProgress(
    int id,
    CreationStatus status,
    int progress, {
    double? anatomicalScore,
    String? watermarkText,
    String? mediaUrl,
    bool? cacheHit,
  }) {
    if (!mounted) return;
    final idx = state.creations.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final updatedList = List<AtelierCreation>.from(state.creations);
      updatedList[idx] = updatedList[idx].copyWith(
        status: status,
        progress: progress,
        anatomicalScore: anatomicalScore,
        watermarkText: watermarkText,
        mediaUrl: mediaUrl,
        cacheHit: cacheHit,
      );
      state = state.copyWith(creations: updatedList);
    }
  }

  void retryCreation(int id) {
    final idx = state.creations.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final creation = state.creations[idx];
      final matchingTemplate = state.templates.firstWhere(
        (t) => t.id == creation.templateId,
        orElse: () => state.templates.first,
      );
      _updateProgress(id, CreationStatus.queue, 10);
      unawaited(
        _processCreationJob(
          creationId: id,
          template: matchingTemplate,
          refundOnFailure: false,
        ),
      );
    }
  }

  void togglePrivate(int id) {
    final idx = state.creations.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final updated = List<AtelierCreation>.from(state.creations);
      updated[idx] = updated[idx].copyWith(isPrivate: !updated[idx].isPrivate);
      state = state.copyWith(creations: updated);
    }
  }

  void deleteCreation(int id) {
    final updated = List<AtelierCreation>.from(state.creations)
      ..removeWhere((c) => c.id == id);
    state = state.copyWith(creations: updated);
  }
}

final atelierRepositoryProvider = Provider<AtelierRepository>(
  (_) => AtelierRepository(),
);

final atelierProvider = StateNotifierProvider<AtelierNotifier, AtelierState>(
  (ref) => AtelierNotifier(ref.read(atelierRepositoryProvider), ref),
);
