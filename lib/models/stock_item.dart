class StockItem {
  final int id;
  final String name;  // key unik, contoh: 'cup_j'
  final String label; // display name, contoh: 'Cup Jumbo (J)'
  final int qty;
  final String unit;  // contoh: 'pcs', 'bungkus', 'kg'

  const StockItem({
    required this.id,
    required this.name,
    required this.label,
    required this.qty,
    required this.unit,
  });

  factory StockItem.fromMap(Map<String, dynamic> map) => StockItem(
        id: map['id'] as int,
        name: map['name'] as String,
        label: map['label'] as String,
        qty: map['qty'] as int,
        unit: map['unit'] as String,
      );

  StockItem copyWith({int? qty}) => StockItem(
        id: id,
        name: name,
        label: label,
        qty: qty ?? this.qty,
        unit: unit,
      );
}
