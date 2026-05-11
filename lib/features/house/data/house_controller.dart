import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'house_repository.dart';

part 'house_controller.g.dart';

@riverpod
class HouseController extends _$HouseController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> joinHouse(String inviteCode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(houseRepositoryProvider).joinHouse(inviteCode),
    );
  }

  Future<String?> createHouse(String name, String? description) async {
    state = const AsyncLoading();
    String? code;
    state = await AsyncValue.guard(() async {
      code = await ref.read(houseRepositoryProvider).createHouse(name, description);
    });
    return code;
  }
}
