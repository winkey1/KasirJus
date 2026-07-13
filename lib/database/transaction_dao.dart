import '../models/cart_entry.dart';
import '../models/transaction_record.dart';
import 'db_helper.dart';

class TransactionDao {
  // ─── WRITE ────────────────────────────────────────────────────
  Future<void> save(List<CartEntry> items, int total) async {
    final db = await DbHelper.db;
    await db.transaction((txn) async {
      final txId = await txn.insert('transactions', {
        'total_price': total,
        'created_at': DateTime.now().toIso8601String(),
      });
      for (final e in items) {
        await txn.insert('transaction_items', {
          'transaction_id': txId,
          'product_name': e.displayName,   // nama + cup/topping
          'qty': e.qty,
          'price': e.unitPrice,            // harga termasuk topping
          'cup_size': e.cupSize,           // dari CartEntry, bukan Product
          'uses_indomie': e.product.usesIndomie ? 1 : 0,
        });
      }
    });
  }

  // ─── READ: summary untuk tanggal tertentu ─────────────────────
  Future<int> getTotalByDate(String datePrefix) async {
    final db = await DbHelper.db;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total_price), 0) as total
      FROM transactions WHERE created_at LIKE ?
    ''', ['$datePrefix%']);
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getTodayTotal() async =>
      getTotalByDate(_todayPrefix());

  Future<int> getWeekTotal() async {
    final db = await DbHelper.db;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final from = _datePrefix(monday);
    final to = _todayPrefix();
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total_price), 0) as total
      FROM transactions
      WHERE created_at >= ? AND created_at <= ?
    ''', ['${from}T00:00:00', '${to}T23:59:59.999']);
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getMonthTotal() async {
    final db = await DbHelper.db;
    final now = DateTime.now();
    final month =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total_price), 0) as total
      FROM transactions WHERE created_at LIKE ?
    ''', ['$month%']);
    return (result.first['total'] as int?) ?? 0;
  }

  // ─── READ: item summary untuk tanggal tertentu ────────────────
  Future<List<Map<String, dynamic>>> getItemSummaryByDate(
      String datePrefix) async {
    final db = await DbHelper.db;
    return db.rawQuery('''
      SELECT
        ti.product_name,
        ti.price,
        SUM(ti.qty)            AS total_qty,
        SUM(ti.qty * ti.price) AS total_harga
      FROM transaction_items ti
      JOIN transactions t ON ti.transaction_id = t.id
      WHERE t.created_at LIKE ?
      GROUP BY ti.product_name, ti.price
      ORDER BY total_qty DESC
    ''', ['$datePrefix%']);
  }

  /// Rekap cup per ukuran untuk tanggal tertentu
  Future<Map<String, int>> getCupUsageByDate(String datePrefix) async {
    try {
      final db = await DbHelper.db;
      final rows = await db.rawQuery('''
        SELECT ti.cup_size, SUM(ti.qty) as total
        FROM transaction_items ti
        JOIN transactions t ON ti.transaction_id = t.id
        WHERE t.created_at LIKE ? AND ti.cup_size <> ''
        GROUP BY ti.cup_size
      ''', ['$datePrefix%']);
      return {
        for (final r in rows)
          r['cup_size'] as String: (r['total'] as int? ?? 0),
      };
    } catch (e) {
      // Kolom cup_size mungkin belum ada di DB lama — return kosong
      return {};
    }
  }

  /// Total indomie terjual untuk tanggal tertentu
  Future<int> getIndomieUsageByDate(String datePrefix) async {
    try {
      final db = await DbHelper.db;
      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(ti.qty), 0) as total
        FROM transaction_items ti
        JOIN transactions t ON ti.transaction_id = t.id
        WHERE t.created_at LIKE ? AND ti.uses_indomie = 1
      ''', ['$datePrefix%']);
      return (result.first['total'] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ─── READ: list & detail harian ──────────────────────────────
  Future<List<TransactionRecord>> getTransactionsByDate(
      String datePrefix) async {
    final db = await DbHelper.db;
    final rows = await db.query('transactions',
        where: 'created_at LIKE ?',
        whereArgs: ['$datePrefix%'],
        orderBy: 'created_at DESC');
    return rows.map(TransactionRecord.fromMap).toList();
  }

  Future<List<TransactionRecord>> getTodayTransactions() async =>
      getTransactionsByDate(_todayPrefix());

  Future<List<Map<String, dynamic>>> getTodayItemSummary() async =>
      getItemSummaryByDate(_todayPrefix());

  Future<List<TransactionItem>> getItemsOf(int txId) async {
    final db = await DbHelper.db;
    final rows = await db.query('transaction_items',
        where: 'transaction_id = ?', whereArgs: [txId]);
    return rows.map(TransactionItem.fromMap).toList();
  }

  // ─── helpers ──────────────────────────────────────────────────
  String _todayPrefix() => _datePrefix(DateTime.now());
  String _datePrefix(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
