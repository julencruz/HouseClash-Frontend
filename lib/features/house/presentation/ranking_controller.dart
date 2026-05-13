import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/house_repository.dart';
import '../domain/house_models.dart';

part 'ranking_controller.g.dart';

@riverpod
class RankingController extends _$RankingController {
  @override
  Future<List<MemberStats>> build() async {
    return ref.read(houseRepositoryProvider).getRanking(RankingPeriod.ALL_TIME);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(houseRepositoryProvider).getRanking(RankingPeriod.ALL_TIME),
    );
  }
}



