import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/house_storage.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/caches_ttl.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/house_models.dart';

part 'house_repository.g.dart';

@riverpod
HouseRepository houseRepository(Ref ref) => HouseRepository(
      dio: ref.watch(apiClientProvider),
      cache: ref.watch(cacheManagerProvider),
      houseStorage: ref.read(houseStorageProvider.notifier),
      houseId: ref.watch(houseStorageProvider).valueOrNull?.houseId.toString() ?? '0',
    );

class HouseRepository {
  final Dio _dio;
  final CacheManager _cache;
  final HouseStorage _houseStorage;
  final String _houseId;

  HouseRepository({
    required Dio dio,
    required CacheManager cache,
    required HouseStorage houseStorage,
    required String houseId,
  })  : _dio = dio,
        _cache = cache,
        _houseStorage = houseStorage,
        _houseId = houseId;

  void _invalidateHouse() {
    _cache.invalidate(CacheKeys.houseDetails(_houseId));
    _cache.invalidate(CacheKeys.houseMembers(_houseId));
    _cache.invalidate(CacheKeys.ranking(_houseId));
  }

  HouseDetailsModel? getCachedHouseDetails() =>
      _cache.get<HouseDetailsModel>(CacheKeys.houseDetails(_houseId));

  List<MemberStats>? getCachedRanking() =>
      _cache.get<List<MemberStats>>(CacheKeys.ranking(_houseId));

  Future<List<UserSession>> getMembers({bool forceRefresh = false}) async {
    final key = CacheKeys.houseMembers(_houseId);
    if (!forceRefresh) {
      final cached = _cache.get<List<UserSession>>(key);
      if (cached != null) return cached;
    }
    final response = await _dio.get('/api/houses/me');
    final membersList = response.data['members'] as List;
    final data = membersList.map((json) => UserSession.fromJson(json)).toList();
    _cache.set(key, data, ttl: CacheTTLs.houseMembers);
    return data;
  }

  Future<HouseDetailsModel> getHouseDetails({bool forceRefresh = false}) async {
    final key = CacheKeys.houseDetails(_houseId);
    if (!forceRefresh) {
      final cached = _cache.get<HouseDetailsModel>(key);
      if (cached != null) return cached;
    }
    final response = await _dio.get('/api/houses/me');
    final data = HouseDetailsModel.fromJson(response.data as Map<String, dynamic>);
    _cache.set(key, data, ttl: CacheTTLs.houseDetails);
    return data;
  }

  Future<void> joinHouse(String inviteCode) async {
    final response = await _dio.post(
      '/api/houses/join',
      data: {'inviteCode': inviteCode},
    );
    final user = UserSession.fromJson(response.data);

    final houseResp = await _dio.get('/api/houses/me');
    final createdBy = houseResp.data['house']['createdBy'] as int;

    await _houseStorage.saveHouse(user.houseId!, createdBy);
  }

  Future<String> createHouse(String name, String? description) async {
    final data = <String, dynamic>{'name': name};
    if (description != null) data['description'] = description;

    final response = await _dio.post('/api/houses', data: data);
    final houseId = response.data['id'] as int;
    final createdBy = response.data['createdBy'] as int;
    final inviteCode = response.data['inviteCode'] as String;

    await _houseStorage.saveHouse(houseId, createdBy);
    return inviteCode;
  }

  Future<HouseModel> updateHouse(String name) async {
    final response = await _dio.patch('/api/houses', data: {'name': name});
    _invalidateHouse();
    return HouseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> leaveHouse() async {
    await _dio.post('/api/houses/leave');
    _invalidateHouse();
    await _houseStorage.clearHouse();
  }

  Future<UserSession> kickMember(int userId) async {
    final response =
        await _dio.post('/api/houses/kick', data: {'userId': userId});
    _invalidateHouse();
    return UserSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HouseModel> transferOwnership(int newOwnerId) async {
    final response = await _dio.post(
      '/api/houses/transfer-ownership',
      data: {'newOwnerId': newOwnerId},
    );
    final house = HouseModel.fromJson(response.data as Map<String, dynamic>);
    final houseSession = _houseStorage.state.valueOrNull;
    if (houseSession != null) {
      await _houseStorage.saveHouse(houseSession.houseId, newOwnerId);
    }
    _invalidateHouse();
    return house;
  }

  Future<List<MemberStats>> getRanking(RankingPeriod period, {bool forceRefresh = false}) async {
    final key = CacheKeys.ranking(_houseId);
    if (!forceRefresh) {
      final cached = _cache.get<List<MemberStats>>(key);
      if (cached != null) return cached;
    }
    final response = await _dio.get(
      '/api/houses/ranking',
      queryParameters: {'period': period.value},
    );
    final data = (response.data as List)
        .map((json) => MemberStats.fromJson(json as Map<String, dynamic>))
        .toList();
    _cache.set(key, data, ttl: CacheTTLs.ranking);
    return data;
  }
}
