import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/caches_ttl.dart';
import '../domain/card_model.dart';

part 'card_repository.g.dart';

@Riverpod(keepAlive: true)
CardRepository cardRepository(Ref ref) => CardRepository(
  dio:   ref.watch(apiClientProvider),
  cache: ref.watch(cacheManagerProvider),
);

class CardRepository {
  final Dio _dio;
  final CacheManager _cache;

  CardRepository({required Dio dio, required CacheManager cache})
      : _dio = dio,
        _cache = cache;

  Future<List<CardModel>> getMyCards({bool forceRefresh = false}) async {
    const key = 'cards:mine';
    if (!forceRefresh) {
      final cached = _cache.get<List<CardModel>>(key);
      if (cached != null) return cached;
    }
    final response = await _dio.get('/api/cards');
    final data = (response.data as List)
        .map((json) => CardModel.fromJson(json))
        .toList();
    _cache.set(key, data, ttl: CacheTTLs.cardInventory);
    return data;
  }

  void _invalidateCards() => _cache.invalidate('cards:mine');

  Future<List<CardModel>> openPack() async {
    final response = await _dio.post('/api/cards/open-pack');
    _invalidateCards();
    return (response.data as List)
        .map((json) => CardModel.fromJson(json))
        .toList();
  }

  Future<void> useCard(int cardId, {
    int? targetUserId,
    int? targetTaskId,
    int? targetCategoryId,
  }) async {
    await _dio.post('/api/cards/$cardId/use', data: {
      if (targetUserId != null)     'targetUserId':     targetUserId,
      if (targetTaskId != null)     'targetTaskId':     targetTaskId,
      if (targetCategoryId != null) 'targetCategoryId': targetCategoryId,
    });
    _invalidateCards();
  }
}

