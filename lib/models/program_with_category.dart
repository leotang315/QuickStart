class ProgramWithCategory {
  final int? id;
  final String name;
  final String path;
  final String? arguments;
  final String? iconPath;
  final int? categoryId;
  final int frequency;
  final String? categoryName;
  final String? categoryIcon;

  ProgramWithCategory({
    this.id,
    required this.name,
    required this.path,
    this.arguments,
    this.iconPath,
    this.categoryId,
    this.frequency = 0,
    this.categoryName,
    this.categoryIcon,
  });

  factory ProgramWithCategory.fromMap(Map<String, dynamic> map) {
    return ProgramWithCategory(
      id: map['id'],
      name: map['name'],
      path: map['path'],
      arguments: map['arguments'],
      iconPath: map['iconPath'],
      categoryId: map['category_id'],
      frequency: map['frequency'] ?? 0,

      categoryName: map['category_name'],
      categoryIcon: map['category_icon'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'arguments': arguments,
      'iconPath': iconPath,
      'category_id': categoryId,
      'frequency': frequency,

      'category_name': categoryName,
      'category_icon': categoryIcon,
    };
  }

  @override
  String toString() {
    return 'ProgramWithCategory{id: $id, name: $name, path: $path, categoryName: $categoryName}';
  }
}