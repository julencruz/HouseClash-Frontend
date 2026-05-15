import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/auth/token_storage.dart';
import '../../../features/activity/presentation/activity_controller.dart';
import '../../../features/cards/presentation/card_controller.dart';
import '../../../features/house/presentation/house_details_controller.dart';
import '../../../features/house/presentation/ranking_controller.dart';
import '../../../features/tasks/presentation/category_controller.dart';
import '../../../features/tasks/presentation/task_controller.dart';
import '../domain/auth_models.dart';
import 'auth_repository.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  Future<UserSession?> build() async {
    final token = await ref.watch(tokenStorageProvider.future);
    if (token == null) return null;
    try {
      return await ref.read(authRepositoryProvider).fetchProfile();
    } catch (_) {
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email, password),
    );
  }

  Future<void> register(String username, String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(username, email, password),
    );
  }

  Future<void> refreshProfile() async {
    final updated = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).fetchProfile(),
    );
    state = updated;
  }

  Future<void> updateProfile({
    String? username,
    String? oldPassword,
    String? newPassword,
  }) async {
    final updated = await ref.read(authRepositoryProvider).updateProfile(
      username: username,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    state = AsyncData(updated);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.invalidate(taskControllerProvider);
    ref.invalidate(cardControllerProvider);
    ref.invalidate(activityControllerProvider);
    ref.invalidate(houseDetailsControllerProvider);
    ref.invalidate(rankingControllerProvider);
    ref.invalidate(categoryControllerProvider);
    state = const AsyncData(null);
  }
}