import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_storage.g.dart';

@riverpod
class TokenStorage extends _$TokenStorage {
  final _storage = const FlutterSecureStorage();
  static const _key = 'auth_token';

  @override
  FutureOr<String?> build() async {
    return await _storage.read(key: _key);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _key, value: token);
    state = AsyncData(token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _key);
    state = const AsyncData(null);
  }
}