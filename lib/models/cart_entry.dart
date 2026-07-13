import '../models/product.dart';

class CartEntry {
  final Product product;
  final int qty;
  final String cupSize;   // 'J','M','S','' — dipilih saat order
  final bool hasTopping;  // khusus mie

  const CartEntry({
    required this.product,
    required this.qty,
    this.cupSize = '',
    this.hasTopping = false,
  });

  /// Key unik per entry: produk + cup + topping
  String get cartKey => '${product.id}_${cupSize}_$hasTopping';

  /// Harga satuan (termasuk topping jika ada)
  int get unitPrice =>
      product.price + (hasTopping ? product.toppingPrice : 0);

  int get subtotal => unitPrice * qty;

  /// Nama tampilan di sidebar keranjang
  String get displayName {
    final buf = StringBuffer(product.name);
    if (cupSize.isNotEmpty) buf.write(' (Cup $cupSize)');
    if (hasTopping) buf.write(' +Topping');
    return buf.toString();
  }

  CartEntry copyWith({int? qty, String? cupSize, bool? hasTopping}) =>
      CartEntry(
        product: product,
        qty: qty ?? this.qty,
        cupSize: cupSize ?? this.cupSize,
        hasTopping: hasTopping ?? this.hasTopping,
      );
}
