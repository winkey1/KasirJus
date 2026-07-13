class TransactionRecord {
  final int id;
  final int totalPrice;
  final DateTime createdAt;
  final List<TransactionItem> items;

  const TransactionRecord({
    required this.id,
    required this.totalPrice,
    required this.createdAt,
    this.items = const [],
  });

  factory TransactionRecord.fromMap(Map<String, dynamic> map) =>
      TransactionRecord(
        id: map['id'] as int,
        totalPrice: map['total_price'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  TransactionRecord copyWith({List<TransactionItem>? items}) =>
      TransactionRecord(
        id: id,
        totalPrice: totalPrice,
        createdAt: createdAt,
        items: items ?? this.items,
      );
}

class TransactionItem {
  final int id;
  final int transactionId;
  final String productName;
  final int qty;
  final int price;

  const TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productName,
    required this.qty,
    required this.price,
  });

  int get subtotal => qty * price;

  factory TransactionItem.fromMap(Map<String, dynamic> map) =>
      TransactionItem(
        id: map['id'] as int,
        transactionId: map['transaction_id'] as int,
        productName: map['product_name'] as String,
        qty: map['qty'] as int,
        price: map['price'] as int,
      );
}
