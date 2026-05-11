import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/house_storage.dart';
import '../../auth/domain/auth_models.dart';

part 'house_repository.g.dart';

@riverpod
HouseRepository houseRepository(Ref ref) => HouseRepository(
  dio:          ref.watch(apiClientProvider),
  houseStorage: ref.read(houseStorageProvider.notifier),
);

class HouseRepository {
  final Dio           _dio;
  final HouseStorage  _houseStorage;

  HouseRepository({
    required Dio dio,
    required HouseStorage houseStorage,
  })  : _dio          = dio,
        _houseStorage = houseStorage;

  Future<void> joinHouse(String inviteCode) async {
    final response = await _dio.post(
      '/api/houses/join',
      data: {'inviteCode': inviteCode},
    );
    final user = UserSession.fromJson(response.data);
    
    // Fetch house details to get the creator
    final houseResp = await _dio.get('/api/houses/me');
    final createdBy = houseResp.data['house']['createdBy'] as int;
    
    await _houseStorage.saveHouse(user.houseId!, createdBy);
  }

  Future<void> createHouse(String name, String? description) async {
    final data = <String, dynamic>{'name': name};
    if (description != null) data['description'] = description;

    final response = await _dio.post('/api/houses', data: data);
    final houseId = response.data['id'] as int;
    final createdBy = response.data['createdBy'] as int;

    await _houseStorage.saveHouse(houseId, createdBy);
  }
}
