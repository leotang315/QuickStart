import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/program.dart';
import '../models/category.dart';
import '../models/program_with_category.dart';

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
      version: 4,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        iconName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE programs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        arguments TEXT,
        iconPath TEXT,
        category_id INTEGER,
        frequency INTEGER NOT NULL DEFAULT 0,

        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    // 插入桌面类别，使用固定ID=0
    await db.execute('''
      INSERT INTO categories (id, name, iconName) VALUES (0, '桌面', 'desktop_windows')
    ''');
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    
  }

  Future<int> insertProgram(Program program) async {
    final db = await database;
    return await db.insert('programs', program.toMap());
  }

  Future<int> deleteProgram(int id) async {
    final db = await database;
    return await db.delete('programs', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProgramsByCategoryId(int categoryId) async {
    final db = await database;
    return await db.delete(
      'programs',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
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

  Future<List<Program>> getPrograms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('programs');
    return List.generate(maps.length, (i) => Program.fromMap(maps[i]));
  }

  Future<List<Program>> getProgramsByCategoryId(int? categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (categoryId == null) {
      // 获取没有分类的程序
      maps = await db.query('programs', where: 'category_id IS NULL');
    } else {
      maps = await db.query(
        'programs',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
    }

    return List.generate(maps.length, (i) => Program.fromMap(maps[i]));
  }

  // 添加联合查询方法，获取程序及其分类信息
  Future<List<Map<String, dynamic>>> getProgramsWithCategory() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, c.name as category_name, c.iconName as category_icon
      FROM programs p
      LEFT JOIN categories c ON p.category_id = c.id
      ORDER BY p.name
    ''');
  }

  // 获取ProgramWithCategory对象列表
  Future<List<ProgramWithCategory>> getProgramsWithCategoryObjects() async {
    final maps = await getProgramsWithCategory();
    return List.generate(
      maps.length,
      (i) => ProgramWithCategory.fromMap(maps[i]),
    );
  }

  // 根据分类ID获取带分类信息的程序列表
  Future<List<ProgramWithCategory>> getProgramsWithCategoryByCategoryId(
    int? categoryId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    if (categoryId == null) {
      maps = await db.rawQuery('''
        SELECT p.*, c.name as category_name, c.iconName as category_icon
        FROM programs p
        LEFT JOIN categories c ON p.category_id = c.id
        WHERE p.category_id IS NULL
        ORDER BY p.name
      ''');
    } else {
      maps = await db.rawQuery(
        '''
        SELECT p.*, c.name as category_name, c.iconName as category_icon
        FROM programs p
        LEFT JOIN categories c ON p.category_id = c.id
        WHERE p.category_id = ?
        ORDER BY p.name
      ''',
        [categoryId],
      );
    }

    return List.generate(
      maps.length,
      (i) => ProgramWithCategory.fromMap(maps[i]),
    );
  }

  // Category operations
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
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

  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<Category?> getCategoryByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

}