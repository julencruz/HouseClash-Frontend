import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/activity_repository.dart';
import '../domain/activity_model.dart';

part 'activity_controller.g.dart';


class ActivityState {
  final List<ActivityModel> entries;
  final bool isLast;
  final int nextPage;
  final bool isLoadingMore;

  const ActivityState({
    required this.entries,
    required this.isLast,
    required this.nextPage,
    this.isLoadingMore = false,
  });

  ActivityState copyWith({
    List<ActivityModel>? entries,
    bool? isLast,
    int? nextPage,
    bool? isLoadingMore,
  }) => ActivityState(
    entries: entries ?? this.entries,
    isLast: isLast ?? this.isLast,
    nextPage: nextPage ?? this.nextPage,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

@Riverpod(keepAlive: true)
class ActivityController extends _$ActivityController {
  @override
  Future<ActivityState> build() => _loadPage(0);

  Future<ActivityState> _loadPage(int page) async {
    final result = await ref
        .read(activityRepositoryProvider)
        .getActivityLogPaged(page: page);
    return ActivityState(
      entries: result.content,
      isLast: result.isLast,
      nextPage: result.page + 1,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadPage(0));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLast || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final result = await ref
          .read(activityRepositoryProvider)
          .getActivityLogPaged(page: current.nextPage);

      state = AsyncData(current.copyWith(
        entries: [...current.entries, ...result.content],
        isLast: result.isLast,
        nextPage: result.page + 1,
        isLoadingMore: false,
      ));
    } catch (e, st) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      if (kDebugMode) print('loadMore error: $e\n$st');
    }
  }
}
