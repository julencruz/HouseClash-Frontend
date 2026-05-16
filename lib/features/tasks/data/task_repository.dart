import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/house_storage.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/caches_ttl.dart';
import '../../auth/domain/task_models.dart';

part 'task_repository.g.dart';

@Riverpod(keepAlive: true)
TaskRepository taskRepository(Ref ref) => TaskRepository(
  dio:     ref.watch(apiClientProvider),
  cache:   ref.watch(cacheManagerProvider),
  houseId: ref.watch(houseStorageProvider).valueOrNull?.houseId.toString() ?? '0',
);

class TaskRepository {
  final Dio          _dio;
  final CacheManager _cache;
  final String       _houseId;

  TaskRepository({
    required Dio dio,
    required CacheManager cache,
    required String houseId,
  })  : _dio     = dio,
        _cache   = cache,
        _houseId = houseId;

  void _invalidateTasks() => _cache.invalidate(CacheKeys.taskList(_houseId));

  Future<List<TaskModel>> getActiveTasks({bool forceRefresh = false}) async {
    final key = CacheKeys.taskList(_houseId);
    if (!forceRefresh) {
      final cached = _cache.get<List<TaskModel>>(key);
      if (cached != null) return cached;
    }
    final response = await _dio.get('/api/tasks');
    final data = (response.data as List)
        .map((json) => TaskModel.fromJson(json))
        .toList();
    _cache.set(key, data, ttl: CacheTTLs.taskList);
    return data;
  }

  Future<TaskModel> assignTask(int taskId) async {
    final response = await _dio.post('/api/tasks/$taskId/assign');
    _invalidateTasks();
    return TaskModel.fromJson(response.data);
  }

  Future<TaskModel> unassignTask(int taskId) async {
    final response = await _dio.post('/api/tasks/$taskId/unassign');
    _invalidateTasks();
    return TaskModel.fromJson(response.data);
  }

  Future<void> deleteTask(int taskId) async {
    await _dio.delete('/api/tasks/$taskId');
    _invalidateTasks();
  }

  Future<TaskModel> completeTask(int taskId) async {
    final response = await _dio.post('/api/tasks/$taskId/complete');
    _invalidateTasks();
    return TaskModel.fromJson(response.data);
  }

  Future<TaskModel> validateTask(int taskId, String decision) async {
    final response = await _dio.post(
      '/api/tasks/$taskId/validate',
      data: {'decision': decision},
    );
    _invalidateTasks();
    return TaskModel.fromJson(response.data);
  }

  Future<TaskModel> updateTask(int taskId, {
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
    final body = <String, dynamic>{};
    if (title != null)       body['title']            = title;
    if (description != null) body['description']      = description;
    if (clearDescription)    body['clearDescription'] = true;
    if (effort != null)      body['effort']           = effort.name.toUpperCase();
    if (categoryId != null)  body['categoryId']       = categoryId;
    if (recurrence != null)  body['recurrence']       = recurrence;
    if (clearRecurrence)     body['clearRecurrence']  = true;
    if (deadline != null)    body['deadline']         = deadline.toIso8601String();
    if (clearDeadline)       body['clearDeadline']    = true;

    final response = await _dio.patch(
      '/api/tasks/$taskId',
      data: body,
      options: Options(contentType: 'application/json'),
    );
    _invalidateTasks();
    return TaskModel.fromJson(response.data);
  }

  Future<TaskModel> createTask({
    required String title,
    required Effort effort,
    required int houseId,
    String? description,
    int? categoryId,
    String? recurrence,
    DateTime? deadline,
  }) async {
    final response = await _dio.post(
      '/api/tasks',
      data: {
        'title': title,
        'effort': effort.name.toUpperCase(),
        'houseId': houseId,
        if (description != null && description.isNotEmpty) 'description': description,
        if (categoryId != null) 'categoryId': categoryId,
        if (recurrence != null) 'recurrence': recurrence,
        if (deadline != null) 'deadline': deadline.toIso8601String(),
      },
    );
    _invalidateTasks();
    return TaskModel.fromJson(response.data);
  }
}
