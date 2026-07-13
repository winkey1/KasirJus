class Product {
  final int? id;
  final String name;
  final int price;
  final String category;
  final bool usesIndomie;  // true = produk mie
  final int toppingPrice;  // harga topping mie (default 0)
  // cupSize dihapus dari produk — dipilih saat order

  const Product({
    this.id,
    required this.name,
    required this.price,
    this.category = 'jus',
    this.usesIndomie = false,
    this.toppingPrice = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
    'category': category,
    'uses_indomie': usesIndomie ? 1 : 0,
    'topping_price': toppingPrice,
  };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: map['id'] as int?,
    name: map['name'] as String,
    price: map['price'] as int,
    category: map['category'] as String? ?? 'jus',
    usesIndomie: (map['uses_indomie'] as int? ?? 0) == 1,
    toppingPrice: map['topping_price'] as int? ?? 0,
  );

  Product copyWith({
    int? id, String? name, int? price,
    String? category, bool? usesIndomie, int? toppingPrice,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    price: price ?? this.price,
    category: category ?? this.category,
    usesIndomie: usesIndomie ?? this.usesIndomie,
    toppingPrice: toppingPrice ?? this.toppingPrice,
  );

  String get badge {
    if (usesIndomie) return toppingPrice > 0 ? 'Mie · Topping +${toppingPrice ~/ 1000}k' : 'Mie';
    return '';
  }
}
