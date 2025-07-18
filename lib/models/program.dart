import 'dart:io';

class Program {
  final int? id;
  final String name;
  final String path;
  final String? arguments;
  final String? iconPath;
  final String? category;
  final bool isFrequent;

  Program({
    this.id,
    required this.name,
    required this.path,
    this.arguments,
    this.iconPath,
    this.category,
    this.isFrequent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'arguments': arguments,
      'iconPath': iconPath,
      'category': category,
      'isFrequent': isFrequent ? 1 : 0,
    };
  }

  factory Program.fromMap(Map<String, dynamic> map) {
    return Program(
      id: map['id'],
      name: map['name'],
      path: map['path'],
      arguments: map['arguments'],
      iconPath: map['iconPath'],
      category: map['category'],
      isFrequent: map['isFrequent'] == 1,
    );
  }
}
