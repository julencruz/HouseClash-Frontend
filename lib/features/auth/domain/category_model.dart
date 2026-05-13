class CategoryModel {
  final int id;
  final int houseId;
  final String name;
  final String? description;
  final bool isDefault;

  const CategoryModel({
    required this.id,
    required this.houseId,
    required this.name,
    this.description,
    required this.isDefault,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] as int,
    houseId: json['houseId'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    isDefault: json['isDefault'] as bool,
  );
}

