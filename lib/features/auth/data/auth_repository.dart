import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/house_storage.dart';
import '../../../core/auth/token_storage.dart';
import '../domain/auth_models.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) => AuthRepository(
  dio:          ref.watch(apiClientProvider),
  tokenStorage: ref.read(tokenStorageProvider.notifier),
  houseStorage: ref.read(houseStorageProvider.notifier),
);

class AuthRepository {
  final Dio           _dio;
  final TokenStorage  _tokenStorage;
  final HouseStorage  _houseStorage;

  AuthRepository({
    required Dio dio,
    required TokenStorage tokenStorage,
    required HouseStorage houseStorage,
  })  : _dio          = dio,
        _tokenStorage = tokenStorage,
        _houseStorage = houseStorage;

  Future<UserSession> login(String email, String password) async {
    final response = await _dio.post(
      '/api/users/login',
      data: {'email': email, 'passwordRaw': password},
    );
    final token = response.data['token'] as String;
    final user  = UserSession.fromJson(response.data['user']);

    if (user.houseId != null) {
      _houseStorage.setLoading();
    }

    await _tokenStorage.saveToken(token);
    await _persistHouseIfNeeded(user);

    return user;
  }

  Future<UserSession> register(String username, String email, String password) async {
    await _dio.post(
      '/api/users/register',
      data: {
        'username':    username,
        'email':       email,
        'passwordRaw': password,
      },
    );
    return login(email, password);
  }

  Future<UserSession> fetchProfile() async {
    final response = await _dio.get('/api/users/me');
    return UserSession.fromJson(response.data);
  }

  Future<void> logout() async {
    await _tokenStorage.clearToken();
    await _houseStorage.clearHouse();
  }

  Future<void> _persistHouseIfNeeded(UserSession user) async {
    if (user.houseId == null) return;

    final response = await _dio.get('/api/houses/me');
    final createdBy = response.data['house']['createdBy'] as int;

    await _houseStorage.saveHouse(user.houseId!, createdBy);
  }
}