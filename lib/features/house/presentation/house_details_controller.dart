import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/house_repository.dart';
import '../domain/house_models.dart';

part 'house_details_controller.g.dart';

@riverpod
class HouseDetailsController extends _$HouseDetailsController {
  @override
  FutureOr<HouseDetailsModel> build() {
    final cached = ref.read(houseRepositoryProvider).getCachedHouseDetails();
    if (cached != null) return cached;
    return ref.read(houseRepositoryProvider).getHouseDetails();
  }

  Future<void> refresh({bool forceRefresh = true}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(houseRepositoryProvider).getHouseDetails(forceRefresh: forceRefresh),
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

