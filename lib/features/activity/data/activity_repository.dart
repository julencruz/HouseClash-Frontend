import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/house_storage.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/caches_ttl.dart';
import '../domain/activity_model.dart';

part 'activity_repository.g.dart';

@Riverpod(keepAlive: true)
ActivityRepository activityRepository(Ref ref) => ActivityRepository(
  dio: ref.watch(apiClientProvider),
  cache: ref.watch(cacheManagerProvider),
  houseId: ref.watch(houseStorageProvider).valueOrNull?.houseId.toString() ?? '0',
);

class ActivityRepository {
  final Dio _dio;
  final CacheManager _cache;
  final String _houseId;

  ActivityRepository({
    required Dio dio,
    required CacheManager cache,
    required String houseId,
  })  : _dio = dio,
        _cache = cache,
        _houseId = houseId;

  Future<List<ActivityModel>> getActivityLog({bool forceRefresh = false}) async {
    final key = CacheKeys.activity(_houseId);
    if (!forceRefresh) {
      final cached = _cache.get<List<ActivityModel>>(key);
      if (cached != null) return cached;
    }
    final response = await _dio.get('/api/houses/$_houseId/activity-log');
    final data = (response.data as List)
        .map((json) => ActivityModel.fromJson(json as Map<String, dynamic>))
        .toList();
    _cache.set(key, data, ttl: CacheTTLs.activity);
    return data;
  }
}

