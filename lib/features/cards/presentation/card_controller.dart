import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../activity/presentation/activity_controller.dart';
import '../../auth/data/auth_controller.dart';
import '../../tasks/presentation/task_controller.dart';
import '../data/card_repository.dart';
import '../domain/card_model.dart';

part 'card_controller.g.dart';

@Riverpod(keepAlive: true)
class CardController extends _$CardController {
  @override
  FutureOr<List<CardModel>> build() async => _fetch();

  Future<List<CardModel>> _fetch({bool forceRefresh = false}) =>
      ref.read(cardRepositoryProvider).getMyCards(forceRefresh: forceRefresh);

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(forceRefresh: true));
  }

  Future<List<CardModel>> openPack() async {
    final newCards = await ref.read(cardRepositoryProvider).openPack();
    ref.read(authControllerProvider.notifier).refreshProfile();
    state = await AsyncValue.guard(() => _fetch(forceRefresh: true));
    return newCards;
  }

  Future<void> useCard(int cardId, {
    int? targetUserId,
    int? targetTaskId,
    int? targetCategoryId,
  }) async {
    await ref.read(cardRepositoryProvider).useCard(
      cardId,
      targetUserId:     targetUserId,
      targetTaskId:     targetTaskId,
      targetCategoryId: targetCategoryId,
    );
    ref.read(authControllerProvider.notifier).refreshProfile();
    ref.read(activityControllerProvider.notifier).refresh();
    ref.read(taskControllerProvider.notifier).refresh();
    state = await AsyncValue.guard(() => _fetch(forceRefresh: true));
  }
}

