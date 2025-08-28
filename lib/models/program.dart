import 'dart:io';

class Program {
  final int? id;
  final String name;
  final String path;
  final String? arguments;
  final String? iconPath;
  final int? categoryId;  
  final int frequency;

  Program({
    this.id,
    required this.name,
    required this.path,
    this.arguments,
    this.iconPath,
    this.categoryId,
    this.frequency = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'arguments': arguments,
      'iconPath': iconPath,
      'category_id': categoryId,
      'frequency': frequency,
    };
  }

  factory Program.fromMap(Map<String, dynamic> map) {
    return Program(
      id: map['id'],
      name: map['name'],
      path: map['path'],
      arguments: map['arguments'],
      iconPath: map['iconPath'],
      categoryId: map['category_id'],
      frequency: map['frequency'] ?? 0,
    );
  }
}
