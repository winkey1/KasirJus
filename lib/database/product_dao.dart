import '../models/product.dart';
import 'db_helper.dart';

class ProductDao {
  Future<List<Product>> getAll() async {
    final db = await DbHelper.db;
    final rows = await db.query('products', orderBy: 'name ASC');
    return rows.map(Product.fromMap).toList();
  }

  Future<int> insert(Product p) async {
    final db = await DbHelper.db;
    final map = p.toMap()..remove('id');
    return db.insert('products', map);
  }

  Future<void> update(Product p) async {
    final db = await DbHelper.db;
    await db.update('products', p.toMap(),
        where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> delete(int id) async {
    final db = await DbHelper.db;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}
