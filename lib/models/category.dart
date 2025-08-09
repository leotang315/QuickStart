class Category {
  final int? id;
  final String name;
  final String? iconName; // 存储选择的图标名称
  
  Category({
    this.id,
    required this.name,
    this.iconName,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
    };
  }
  
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      iconName: map['iconName'],
    );
  }
  
  Category copyWith({
    int? id,
    String? name,
    String? iconName,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
    );
  }
}