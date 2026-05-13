import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/activity_repository.dart';
import '../domain/activity_model.dart';

part 'activity_controller.g.dart';

@Riverpod(keepAlive: true)
class ActivityController extends _$ActivityController {
  @override
  FutureOr<List<ActivityModel>> build() => _fetch();

  Future<List<ActivityModel>> _fetch({bool forceRefresh = false}) =>
      ref.read(activityRepositoryProvider).getActivityLog(forceRefresh: forceRefresh);

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(forceRefresh: true));
  }
}

