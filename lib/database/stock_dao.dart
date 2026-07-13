import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../models/cart_entry.dart';
import '../models/stock_item.dart';
import 'db_helper.dart';

class StockDao {
  Future<void> ensureGulaReset() async {
    final db = await DbHelper.db;
    final today = _todayStr();
    final rows = await db.query('settings',
        where: 'key = ?', whereArgs: ['gula_last_reset']);
    final lastReset = rows.isEmpty ? '' : rows.first['value'] as String;
    if (lastReset != today) {
      await db.update('stock', {'qty': 0},
          where: 'name = ?', whereArgs: ['gula']);
      await db.insert('settings',
          {'key': 'gula_last_reset', 'value': today},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<StockItem>> getAll() async {
    final db = await DbHelper.db;
    final rows = await db.query('stock', orderBy: 'id ASC');
    return rows.map(StockItem.fromMap).toList();
  }

  Future<int> getGulaAddedByDate(String datePrefix) async {
    final db = await DbHelper.db;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(qty), 0) as total
      FROM stock_log
      WHERE stock_name = 'gula' AND qty > 0 AND created_at LIKE ?
    ''', ['$datePrefix%']);
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getTodayGulaAdded() async => getGulaAddedByDate(_todayStr());

  Future<List<Map<String, dynamic>>> getLogByDate(String datePrefix) async {
    final db = await DbHelper.db;
    return db.query('stock_log',
        where: 'created_at LIKE ?',
        whereArgs: ['$datePrefix%'],
        orderBy: 'created_at DESC');
  }

  Future<void> adjustWithNote(int id, int delta, {String note = ''}) async {
    final db = await DbHelper.db;
    final rows = await db.query('stock', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;
    final name = rows.first['name'] as String;
    final label = rows.first['label'] as String;
    await db.rawUpdate(
        'UPDATE stock SET qty = MAX(0, qty + ?) WHERE id = ?', [delta, id]);
    if ((delta > 0 && name == 'gula') || delta < 0) {
      await _log(db, name: name, label: label, qty: delta, note: note);
    }
  }

  Future<void> setQtyWithLog(int id, int newQty, {String note = ''}) async {
    final db = await DbHelper.db;
    final rows = await db.query('stock', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;
    final name = rows.first['name'] as String;
    final label = rows.first['label'] as String;
    final oldQty = rows.first['qty'] as int;
    final safeQty = newQty < 0 ? 0 : newQty;
    final delta = safeQty - oldQty;
    await db.update('stock', {'qty': safeQty},
        where: 'id = ?', whereArgs: [id]);
    if (delta > 0 && name == 'gula') {
      await _log(db, name: name, label: label, qty: delta, note: note);
    } else if (delta < 0) {
      await _log(db, name: name, label: label, qty: delta, note: note);
    }
  }

  /// Kurangi stok cup & indomie otomatis dari transaksi.
  /// Sekarang cupSize diambil dari CartEntry (bukan Product).
  Future<void> deductForTransaction(List<CartEntry> items) async {
    final db = await DbHelper.db;
    for (final entry in items) {
      // cup dari CartEntry (dipilih saat order)
      if (entry.cupSize.isNotEmpty) {
        final stockName = 'cup_${entry.cupSize.toLowerCase()}';
        await db.rawUpdate('''
          UPDATE stock SET qty = MAX(0, qty + ?) WHERE name = ?
        ''', [-entry.qty, stockName]);
      }
      // indomie dari flag produk
      if (entry.product.usesIndomie) {
        await db.rawUpdate('''
          UPDATE stock SET qty = MAX(0, qty + ?) WHERE name = ?
        ''', [-entry.qty, 'mie_indomie']);
      }
    }
  }

  Future<void> _log(dynamic db, {
    required String name, required String label,
    required int qty, required String note,
  }) async {
    await db.insert('stock_log', {
      'stock_name': name, 'stock_label': label,
      'qty': qty, 'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  String _todayStr() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-'
        '${d.day.toString().padLeft(2,'0')}';
  }
}
