import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/program.dart';

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
      version: 1,
      onCreate: _createDb,
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
        isFrequent INTEGER NOT NULL DEFAULT 0
      )
    ''');
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
}