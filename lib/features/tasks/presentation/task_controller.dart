import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/data/auth_controller.dart';
import '../../auth/domain/task_models.dart';
import '../data/task_repository.dart';

part 'task_controller.g.dart';

@Riverpod(keepAlive: true)
class TaskController extends _$TaskController {
  @override
  FutureOr<List<TaskModel>> build() async => _fetchTasks();

  Future<List<TaskModel>> _fetchTasks({bool forceRefresh = false}) =>
      ref.read(taskRepositoryProvider).getActiveTasks(forceRefresh: forceRefresh);

  void _refreshProfile() =>
      ref.read(authControllerProvider.notifier).refreshProfile();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTasks(forceRefresh: true));
  }

  Future<void> assignTask(int taskId) async {
    final result = await AsyncValue.guard(() async {
      await ref.read(taskRepositoryProvider).assignTask(taskId);
      _refreshProfile();
      return _fetchTasks();
    });
    state = result;
  }

  Future<void> unassignTask(int taskId) async {
    final result = await AsyncValue.guard(() async {
      await ref.read(taskRepositoryProvider).unassignTask(taskId);
      _refreshProfile();
      return _fetchTasks();
    });
    state = result;
  }

  Future<void> completeTask(int taskId) async {
    final result = await AsyncValue.guard(() async {
      await ref.read(taskRepositoryProvider).completeTask(taskId);
      _refreshProfile();
      return _fetchTasks();
    });
    state = result;
  }

  Future<void> validateTask(int taskId, String decision) async {
    final result = await AsyncValue.guard(() async {
      await ref.read(taskRepositoryProvider).validateTask(taskId, decision);
      _refreshProfile();
      return _fetchTasks();
    });
    state = result;
  }

  Future<void> deleteTask(int taskId) async {
    state = await AsyncValue.guard(() async {
      await ref.read(taskRepositoryProvider).deleteTask(taskId);
      return _fetchTasks();
    });
  }

  Future<void> updateTask(int taskId, {
    String? title,
    String? description,
    bool clearDescription = false,
    Effort? effort,
    int? categoryId,
    String? recurrence,
    bool clearRecurrence = false,
    DateTime? deadline,
    bool clearDeadline = false,
  }) async {
    await ref.read(taskRepositoryProvider).updateTask(
      taskId,
      title: title,
      description: description,
      clearDescription: clearDescription,
      effort: effort,
      categoryId: categoryId,
      recurrence: recurrence,
      clearRecurrence: clearRecurrence,
      deadline: deadline,
      clearDeadline: clearDeadline,
    );
    state = await AsyncValue.guard(() => _fetchTasks(forceRefresh: true));
  }

  Future<void> createTask({
    required String title,
    required Effort effort,
    required int houseId,
    String? description,
    int? categoryId,
    String? recurrence,
    DateTime? deadline,
  }) async {
    final result = await AsyncValue.guard(() async {
      await ref.read(taskRepositoryProvider).createTask(
        title: title,
        effort: effort,
        houseId: houseId,
        description: description,
        categoryId: categoryId,
        recurrence: recurrence,
        deadline: deadline,
      );
      return _fetchTasks();
    });
    state = result;
  }
}
