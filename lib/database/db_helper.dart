import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'quickjuice.db'),
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _seed(db);
    await _seedStock(db);
  }

  static Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS stock (
          id    INTEGER PRIMARY KEY AUTOINCREMENT,
          name  TEXT NOT NULL UNIQUE,
          label TEXT NOT NULL,
          qty   INTEGER NOT NULL DEFAULT 0,
          unit  TEXT NOT NULL DEFAULT 'pcs'
        )
      ''');
      await _seedStock(db);
    }
    if (oldV < 3) {
      try { await db.execute("ALTER TABLE products ADD COLUMN cup_size TEXT NOT NULL DEFAULT ''"); } catch (_) {}
      try { await db.execute('ALTER TABLE products ADD COLUMN uses_indomie INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
      try { await db.execute("ALTER TABLE transaction_items ADD COLUMN cup_size TEXT NOT NULL DEFAULT ''"); } catch (_) {}
      try { await db.execute('ALTER TABLE transaction_items ADD COLUMN uses_indomie INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS stock_log (
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          stock_name TEXT NOT NULL,
          stock_label TEXT NOT NULL DEFAULT '',
          qty        INTEGER NOT NULL,
          note       TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_stock_log_date ON stock_log(created_at)');
    }
    if (oldV < 5) {
      // Pastikan kolom cup_size & uses_indomie ada di transaction_items.
      // Mungkin tidak ter-add di v3 jika migrasi lama silently-failed.
      try { await db.execute("ALTER TABLE transaction_items ADD COLUMN cup_size TEXT NOT NULL DEFAULT ''"); } catch (_) {}
      try { await db.execute('ALTER TABLE transaction_items ADD COLUMN uses_indomie INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
      // Juga pastikan products punya kolom ini
      try { await db.execute("ALTER TABLE products ADD COLUMN cup_size TEXT NOT NULL DEFAULT ''"); } catch (_) {}
      try { await db.execute('ALTER TABLE products ADD COLUMN uses_indomie INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
      // Pastikan settings table ada
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key   TEXT PRIMARY KEY,
          value TEXT NOT NULL DEFAULT ''
        )
      ''');
      // Pastikan stock_log punya kolom note & stock_label
      try { await db.execute("ALTER TABLE stock_log ADD COLUMN note TEXT NOT NULL DEFAULT ''"); } catch (_) {}
      try { await db.execute("ALTER TABLE stock_log ADD COLUMN stock_label TEXT NOT NULL DEFAULT ''"); } catch (_) {}
    }
    if (oldV < 6) {
      try { await db.execute('ALTER TABLE products ADD COLUMN topping_price INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
    }
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE products (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        name         TEXT NOT NULL,
        price        INTEGER NOT NULL,
        category     TEXT NOT NULL DEFAULT 'jus',
        cup_size     TEXT NOT NULL DEFAULT '',
        uses_indomie INTEGER NOT NULL DEFAULT 0,
        topping_price INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        total_price INTEGER NOT NULL,
        created_at  TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE transaction_items (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_name   TEXT NOT NULL,
        qty            INTEGER NOT NULL,
        price          INTEGER NOT NULL,
        cup_size       TEXT NOT NULL DEFAULT '',
        uses_indomie   INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE stock (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        name  TEXT NOT NULL UNIQUE,
        label TEXT NOT NULL,
        qty   INTEGER NOT NULL DEFAULT 0,
        unit  TEXT NOT NULL DEFAULT 'pcs'
      )
    ''');
    await db.execute('''
      CREATE TABLE stock_log (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        stock_name  TEXT NOT NULL,
        stock_label TEXT NOT NULL DEFAULT '',
        qty         INTEGER NOT NULL,
        note        TEXT NOT NULL DEFAULT '',
        created_at  TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('CREATE INDEX idx_tx_date ON transactions(created_at)');
    await db.execute('CREATE INDEX idx_stock_log_date ON stock_log(created_at)');
  }

  static Future<void> _seed(Database db) async {
    final seeds = [
      ('Jus Mangga', 8000),   ('Jus Alpukat', 10000),
      ('Jus Jeruk', 7000),    ('Jus Apel', 8000),
      ('Jus Stroberi', 9000), ('Jus Semangka', 7000),
      ('Jus Nanas', 7000),    ('Jus Melon', 8000),
    ];
    for (final (name, price) in seeds) {
      await db.insert('products', {'name': name, 'price': price});
    }
  }

  static Future<void> _seedStock(Database db) async {
    final stocks = [
      ('cup_j',       'Cup Jumbo (J)',  0, 'pcs'),
      ('cup_m',       'Cup Medium (M)', 0, 'pcs'),
      ('cup_s',       'Cup Small (S)',  0, 'pcs'),
      ('mie_indomie', 'Mie Indomie',   0, 'bungkus'),
      ('gula',        'Gula',          0, 'kg'),
    ];
    for (final (name, label, qty, unit) in stocks) {
      await db.insert('stock', {
        'name': name, 'label': label, 'qty': qty, 'unit': unit,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
