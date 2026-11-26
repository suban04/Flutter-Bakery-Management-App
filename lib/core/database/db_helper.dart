import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'cake_shop_manager.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createAllTables(db);
        if (oldVersion < 3) {
          try {
            await db.execute(
              'ALTER TABLE b2b_cake_dispatch ADD COLUMN weight TEXT DEFAULT "1/2 Kg"',
            );
          } catch (_) {}
        }
      },
    );
  }

  static Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        price REAL,
        stock_qty INTEGER,
        low_stock_limit INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        total_amount REAL,
        payment_mode TEXT,
        items_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS special_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT,
        phone TEXT,
        flavour TEXT,
        weight TEXT,
        message TEXT,
        total_price REAL,
        advance_paid REAL,
        delivery_date TEXT,
        image_path TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bakery_parties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bakery_name TEXT,
        phone TEXT,
        current_balance REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bakery_ledger (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        party_id INTEGER,
        date TEXT,
        type TEXT,
        amount REAL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        title TEXT,
        category TEXT,
        amount REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_production (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        flavour TEXT,
        weight TEXT,
        yesterday_leftover INTEGER DEFAULT 0,
        made_today INTEGER DEFAULT 0,
        making_cost REAL DEFAULT 0,
        selling_price REAL DEFAULT 0,
        remaining_today INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS b2b_cake_dispatch (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        party_id INTEGER,
        bakery_name TEXT,
        flavour TEXT,
        weight TEXT,
        qty INTEGER,
        price_per_cake REAL,
        total_amount REAL
      )
    ''');
  }
}