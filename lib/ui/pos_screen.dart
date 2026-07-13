import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/product_dao.dart';
import '../logic/cart_notifier.dart';
import '../models/product.dart';
import 'cart_sidebar.dart';
import 'order_options_sheet.dart';
import 'product_grid.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  PosScreenState createState() => PosScreenState();
}

// State publik agar MainShell bisa memanggil refreshProducts()
class PosScreenState extends State<PosScreen> {
  final _dao = ProductDao();
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _dao.getAll();
    if (mounted) setState(() { _products = products; _loading = false; });
  }

  /// Dipanggil oleh MainShell setelah kembali dari ManageScreen
  void refreshProducts() => _loadProducts();

  /// Tampilkan OrderOptionsSheet lalu tambah ke keranjang
  Future<void> _onProductTap(Product product) async {
    final result = await showOrderOptionsSheet(context, product);
    if (result == null || !mounted) return;
    context.read<CartNotifier>().addEntry(
      product,
      cupSize: result.cupSize,
      hasTopping: result.hasTopping,
      qty: result.qty,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ProductGrid(products: _products, onTap: _onProductTap),
        ),
        const CartSidebar(),
      ],
    );
  }
}
