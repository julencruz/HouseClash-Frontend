import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/house_repository.dart';
import '../domain/house_models.dart';

part 'ranking_controller.g.dart';

@riverpod
class RankingController extends _$RankingController {
  @override
  FutureOr<List<MemberStats>> build() {
    final cached = ref.read(houseRepositoryProvider).getCachedRanking();
    if (cached != null) return cached;
    return ref.read(houseRepositoryProvider).getRanking(RankingPeriod.ALL_TIME);
  }

  Future<void> refresh({bool forceRefresh = true}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(houseRepositoryProvider).getRanking(RankingPeriod.ALL_TIME, forceRefresh: forceRefresh),
    );
  }
}

