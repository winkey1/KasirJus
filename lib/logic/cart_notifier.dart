import 'package:flutter/foundation.dart';
import '../models/cart_entry.dart';
import '../models/product.dart';
import '../database/transaction_dao.dart';
import '../database/stock_dao.dart';

class CartNotifier extends ChangeNotifier {
  // key = cartKey (productId_cupSize_hasTopping)
  final _items = <String, CartEntry>{};
  final _txDao = TransactionDao();
  final _stockDao = StockDao();

  List<CartEntry> get items => _items.values.toList();
  int get total => _items.values.fold(0, (s, e) => s + e.subtotal);
  bool get isEmpty => _items.isEmpty;

  /// Tambah produk dengan pilihan cup/topping/qty
  void addEntry(
    Product product, {
    String cupSize = '',
    bool hasTopping = false,
    int qty = 1,
  }) {
    final entry = CartEntry(
      product: product,
      qty: qty,
      cupSize: cupSize,
      hasTopping: hasTopping,
    );
    final key = entry.cartKey;
    final existing = _items[key];
    _items[key] = existing == null
        ? entry
        : existing.copyWith(qty: existing.qty + qty);
    notifyListeners();
  }

  /// Ubah qty berdasarkan cartKey
  void setQty(String cartKey, int qty) {
    if (qty <= 0) {
      _items.remove(cartKey);
    } else {
      final e = _items[cartKey];
      if (e != null) _items[cartKey] = e.copyWith(qty: qty);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  Future<void> checkout() async {
    if (_items.isEmpty) return;
    final snapshot = List<CartEntry>.from(items);
    final totalSnapshot = total;
    clear();
    await _txDao.save(snapshot, totalSnapshot);
    await _stockDao.deductForTransaction(snapshot);
  }
}
