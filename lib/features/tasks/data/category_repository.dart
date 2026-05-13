import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/house_storage.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/caches_ttl.dart';
import '../../auth/domain/category_model.dart';

part 'category_repository.g.dart';

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) => CategoryRepository(
  dio:     ref.watch(apiClientProvider),
  cache:   ref.watch(cacheManagerProvider),
  houseId: ref.watch(houseStorageProvider).valueOrNull?.houseId.toString() ?? '0',
);

class CategoryRepository {
  final Dio          _dio;
  final CacheManager _cache;
  final String       _houseId;

  CategoryRepository({
    required Dio dio,
    required CacheManager cache,
    required String houseId,
  })  : _dio     = dio,
        _cache   = cache,
        _houseId = houseId;

  void _invalidate() => _cache.invalidate(CacheKeys.categories(_houseId));

  Future<List<CategoryModel>> getCategories({bool forceRefresh = false}) async {
    final key = CacheKeys.categories(_houseId);
    if (!forceRefresh) {
      final cached = _cache.get<List<CategoryModel>>(key);
      if (cached != null) return cached;
    }
    final response = await _dio.get('/api/categories');
    final data = (response.data as List)
        .map((json) => CategoryModel.fromJson(json))
        .toList();
    _cache.set(key, data, ttl: CacheTTLs.categories);
    return data;
  }

  Future<CategoryModel> createCategory({
    required String name,
    required int houseId,
    String? description,
  }) async {
    final response = await _dio.post(
      '/api/categories',
      data: {
        'name': name,
        'houseId': houseId,
        if (description != null && description.isNotEmpty) 'description': description,
      },
    );
    _invalidate();
    return CategoryModel.fromJson(response.data);
  }

  Future<CategoryModel> updateCategory(int categoryId, String name) async {
    final response = await _dio.patch(
      '/api/categories/$categoryId',
      data: {'name': name},
    );
    _invalidate();
    return CategoryModel.fromJson(response.data);
  }

  Future<void> deleteCategory(int categoryId) async {
    await _dio.delete('/api/categories/$categoryId');
    _invalidate();
  }
}

