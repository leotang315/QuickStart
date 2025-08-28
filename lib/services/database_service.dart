import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/program.dart';
import '../models/category.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'quick_start.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE programs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        arguments TEXT,
        iconPath TEXT,
        category TEXT,
        isFrequent INTEGER NOT NULL DEFAULT 0,
        defaultIconName TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        iconName TEXT
      )
    ''');
    
    // 不再插入默认的'All'类别
  }

  Future<int> insertProgram(Program program) async {
    final db = await database;
    return await db.insert('programs', program.toMap());
  }

  Future<List<Program>> getPrograms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('programs');
    return List.generate(maps.length, (i) => Program.fromMap(maps[i]));
  }

  Future<List<Program>> getProgramsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'programs',
      where: 'category = ?',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) => Program.fromMap(maps[i]));
  }

  Future<int> updateProgram(Program program) async {
    final db = await database;
    return await db.update(
      'programs',
      program.toMap(),
      where: 'id = ?',
      whereArgs: [program.id],
    );
  }

  Future<int> deleteProgram(int id) async {
    final db = await database;
    return await db.delete(
      'programs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProgramsByCategory(String category) async {
    final db = await database;
    return await db.delete(
      'programs',
      where: 'category = ?',
      whereArgs: [category],
    );
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE programs ADD COLUMN defaultIconName TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          iconName TEXT
        )
      ''');
      
      // 不再插入默认的'All'类别
      
      // 从现有程序中提取类别并插入到categories表
      final List<Map<String, dynamic>> existingCategories = await db.rawQuery(
        'SELECT DISTINCT category FROM programs WHERE category IS NOT NULL AND category != ""'
      );
      
      for (final categoryMap in existingCategories) {
        final categoryName = categoryMap['category'] as String;
        await db.insert('categories', {'name': categoryName, 'iconName': null}, 
          conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  // Category operations
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}