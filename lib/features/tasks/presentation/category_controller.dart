import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/category_model.dart';
import '../data/category_repository.dart';

part 'category_controller.g.dart';

@Riverpod(keepAlive: true)
class CategoryController extends _$CategoryController {
  @override
  FutureOr<List<CategoryModel>> build() async {
    return ref.read(categoryRepositoryProvider).getCategories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(categoryRepositoryProvider).getCategories(forceRefresh: true),
    );
  }

  Future<CategoryModel> createCategory({
    required String name,
    required int houseId,
    String? description,
  }) async {
    final category = await ref.read(categoryRepositoryProvider).createCategory(
      name: name,
      houseId: houseId,
      description: description,
    );

    final previousState = state.valueOrNull ?? [];
    state = AsyncData([...previousState, category]);

    return category;
  }

  Future<CategoryModel> updateCategory(int categoryId, String name) async {
    final updated = await ref.read(categoryRepositoryProvider).updateCategory(categoryId, name);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((c) => c.id == categoryId ? updated : c).toList().cast<CategoryModel>());
    return updated;
  }

  Future<void> deleteCategory(int categoryId) async {
    await ref.read(categoryRepositoryProvider).deleteCategory(categoryId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((c) => c.id != categoryId).toList());
  }
}
