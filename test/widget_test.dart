import 'package:flutter_test/flutter_test.dart';
import 'package:quick_start/models/program.dart';
import 'package:quick_start/models/category.dart';

void main() {
  group('Model Tests', () {
    test('Program model should create and convert correctly', () {
      // Create a test program
      final program = Program(
        id: 1,
        name: 'Test App',
        path: 'C:\\test\\app.exe',
        iconPath: 'C:\\test\\icon.ico',
        categoryId: 1,
      );
      
      // Verify program properties
      expect(program.id, equals(1));
      expect(program.name, equals('Test App'));
      expect(program.path, equals('C:\\test\\app.exe'));
      expect(program.iconPath, equals('C:\\test\\icon.ico'));
      expect(program.categoryId, equals(1));
      
      // Test toMap conversion
      final map = program.toMap();
      expect(map['id'], equals(1));
      expect(map['name'], equals('Test App'));
      expect(map['path'], equals('C:\\test\\app.exe'));
      
      // Test fromMap conversion
      final programFromMap = Program.fromMap(map);
      expect(programFromMap.name, equals(program.name));
      expect(programFromMap.path, equals(program.path));
    });
    
    test('Category model should create and convert correctly', () {
      // Create a test category
      final category = Category(
        id: 1,
        name: 'Games',
        iconResource: 'games',
      );
      
      // Verify category properties
      expect(category.id, equals(1));
      expect(category.name, equals('Games'));
      expect(category.iconResource, equals('games'));
      
      // Test toMap conversion
      final map = category.toMap();
      expect(map['id'], equals(1));
      expect(map['name'], equals('Games'));
      expect(map['iconResource'], equals('games'));
      
      // Test fromMap conversion
      final categoryFromMap = Category.fromMap(map);
      expect(categoryFromMap.name, equals(category.name));
      expect(categoryFromMap.iconResource, equals(category.iconResource));
    });
  });
}