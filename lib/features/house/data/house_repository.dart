import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/house_storage.dart';
import '../../auth/domain/auth_models.dart';
import '../domain/house_models.dart';

part 'house_repository.g.dart';

@riverpod
HouseRepository houseRepository(Ref ref) => HouseRepository(
      dio: ref.watch(apiClientProvider),
      houseStorage: ref.read(houseStorageProvider.notifier),
    );

class HouseRepository {
  final Dio _dio;
  final HouseStorage _houseStorage;

  HouseRepository({
    required Dio dio,
    required HouseStorage houseStorage,
  })  : _dio = dio,
        _houseStorage = houseStorage;

  Future<List<UserSession>> getMembers() async {
    final response = await _dio.get('/api/houses/me');
    final membersList = response.data['members'] as List;
    return membersList.map((json) => UserSession.fromJson(json)).toList();
  }

  Future<HouseDetailsModel> getHouseDetails() async {
    final response = await _dio.get('/api/houses/me');
    return HouseDetailsModel.fromJson(response.data as Map<String, dynamic>);
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
    return HouseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> leaveHouse() async {
    await _dio.post('/api/houses/leave');
    await _houseStorage.clearHouse();
  }

  Future<UserSession> kickMember(int userId) async {
    final response =
        await _dio.post('/api/houses/kick', data: {'userId': userId});
    return UserSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HouseModel> transferOwnership(int newOwnerId) async {
    final response = await _dio.post(
      '/api/houses/transfer-ownership',
      data: {'newOwnerId': newOwnerId},
    );
    final house =
        HouseModel.fromJson(response.data as Map<String, dynamic>);
    final houseSession = _houseStorage.state.valueOrNull;
    if (houseSession != null) {
      await _houseStorage.saveHouse(houseSession.houseId, newOwnerId);
    }
    return house;
  }

  Future<List<MemberStats>> getRanking(RankingPeriod period) async {
    final response = await _dio.get(
      '/api/houses/ranking',
      queryParameters: {'period': period.value},
    );
    return (response.data as List)
        .map((json) => MemberStats.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
