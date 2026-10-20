import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class HistoryService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'habitguard.db',
    );

    return openDatabase(
      path,
      version: 2,

      // ------------------------------------------------
      // Create database for a new installation
      // ------------------------------------------------
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE daily_usage (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT UNIQUE,
            total_minutes INTEGER,
            risk_level TEXT,
            risk_confidence REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE app_usage (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            package_name TEXT,
            app_name TEXT,
            category TEXT,
            usage_minutes INTEGER
          )
        ''');
      },

      // ------------------------------------------------
      // Upgrade existing database: version 1 -> 2
      // ------------------------------------------------
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE daily_usage
            ADD COLUMN risk_level TEXT
          ''');

          await db.execute('''
            ALTER TABLE daily_usage
            ADD COLUMN risk_confidence REAL
          ''');
        }
      },
    );
  }

  // --------------------------------------------------
  // Save Usage + Risk
  // --------------------------------------------------

  static Future<void> saveUsage({
    required String date,
    required List<Map<String, dynamic>> apps,
    String? riskLevel,
    double? riskConfidence,
  }) async {
    final db = await database;

    int totalMinutes = 0;

    for (final app in apps) {
      totalMinutes +=
          (app['usageMinutes'] ?? 0) as int;
    }

    // ------------------------------------------------
    // Save daily usage
    // ------------------------------------------------

    await db.insert(
      'daily_usage',
      {
        'date': date,
        'total_minutes': totalMinutes,
        'risk_level': riskLevel,
        'risk_confidence': riskConfidence,
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );

    // ------------------------------------------------
    // Remove old app records for this date
    // ------------------------------------------------

    await db.delete(
      'app_usage',
      where: 'date = ?',
      whereArgs: [date],
    );

    // ------------------------------------------------
    // Save app-wise usage
    // ------------------------------------------------

    for (final app in apps) {
      await db.insert(
        'app_usage',
        {
          'date': date,
          'package_name':
              app['packageName'] ?? '',
          'app_name':
              app['appName'] ?? 'Unknown',
          'category':
              app['category'] ?? 'Other',
          'usage_minutes':
              app['usageMinutes'] ?? 0,
        },
      );
    }
  }

  // --------------------------------------------------
  // Get app usage for a specific date
  // --------------------------------------------------

  static Future<List<Map<String, dynamic>>>
      getUsageForDate(String date) async {
    final db = await database;

    return db.query(
      'app_usage',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'usage_minutes DESC',
    );
  }

  // --------------------------------------------------
  // Get daily usage + risk for a specific date
  // --------------------------------------------------

  static Future<Map<String, dynamic>?>
      getDailyUsage(String date) async {
    final db = await database;

    final result = await db.query(
      'daily_usage',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // --------------------------------------------------
  // Get all daily history
  // --------------------------------------------------

  static Future<List<Map<String, dynamic>>>
      getAllDailyUsage() async {
    final db = await database;

    return db.query(
      'daily_usage',
      orderBy: 'date DESC',
    );
  }
  static Future<List<Map<String, dynamic>>> getLast7DaysUsage() async {
    final db = await database;

    final result = await db.query(
      'daily_usage',
      orderBy: 'date DESC',
      limit: 7,
    );

    return result;
  }
}

