import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/house_repository.dart';
import '../domain/house_models.dart';

part 'house_details_controller.g.dart';

@riverpod
class HouseDetailsController extends _$HouseDetailsController {
  @override
  Future<HouseDetailsModel> build() async {
    return ref.read(houseRepositoryProvider).getHouseDetails();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(houseRepositoryProvider).getHouseDetails(),
    );
  }

  Future<void> updateName(String name) async {
    await ref.read(houseRepositoryProvider).updateHouse(name);
    await refresh();
  }

  Future<void> kickMember(int userId) async {
    await ref.read(houseRepositoryProvider).kickMember(userId);
    await refresh();
  }

  Future<void> transferOwnership(int newOwnerId) async {
    await ref.read(houseRepositoryProvider).transferOwnership(newOwnerId);
    await refresh();
  }

  Future<void> leaveHouse() async {
    await ref.read(houseRepositoryProvider).leaveHouse();
  }
}

