import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'house_storage.g.dart';

@riverpod
class HouseStorage extends _$HouseStorage {
  final _storage = const FlutterSecureStorage();
  static const _keyHouseId  = 'house_id';
  static const _keyCreatedBy = 'house_created_by';

  @override
  FutureOr<HouseSession?> build() async {
    final houseId   = await _storage.read(key: _keyHouseId);
    final createdBy = await _storage.read(key: _keyCreatedBy);
    if (houseId == null || createdBy == null) return null;
    return HouseSession(
      houseId:   int.parse(houseId),
      createdBy: int.parse(createdBy),
    );
  }

  Future<void> saveHouse(int houseId, int createdBy) async {
    await _storage.write(key: _keyHouseId,   value: houseId.toString());
    await _storage.write(key: _keyCreatedBy, value: createdBy.toString());
    state = AsyncData(HouseSession(houseId: houseId, createdBy: createdBy));
  }

  Future<void> clearHouse() async {
    await _storage.delete(key: _keyHouseId);
    await _storage.delete(key: _keyCreatedBy);
    state = const AsyncData(null);
  }
}

class HouseSession {
  final int houseId;
  final int createdBy;

  const HouseSession({required this.houseId, required this.createdBy});

  bool isCaptain(int userId) => createdBy == userId;
}