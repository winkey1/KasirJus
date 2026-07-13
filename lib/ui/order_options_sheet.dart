import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/currency.dart';

/// Menampilkan pilihan cup/topping/qty sebelum masuk keranjang.
/// Return: (cupSize, hasTopping, qty) atau null jika dibatalkan.
Future<({String cupSize, bool hasTopping, int qty})?> showOrderOptionsSheet(
  BuildContext context,
  Product product,
) async {
  return showModalBottomSheet<({String cupSize, bool hasTopping, int qty})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _OrderOptionsSheet(product: product),
  );
}

class _OrderOptionsSheet extends StatefulWidget {
  final Product product;
  const _OrderOptionsSheet({required this.product});

  @override
  State<_OrderOptionsSheet> createState() => _OrderOptionsSheetState();
}

class _OrderOptionsSheetState extends State<_OrderOptionsSheet> {
  String _cupSize = 'M';   // default Medium untuk jus
  bool _hasTopping = false;
  int _qty = 1;

  Product get p => widget.product;
  int get _unitPrice => p.price + (_hasTopping ? p.toppingPrice : 0);
  int get _total => _unitPrice * _qty;

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final isJus = !p.usesIndomie;

    return Container(
      margin: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * 0.1,
        right: MediaQuery.of(context).size.width * 0.1,
        bottom: kb,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header produk
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20))),
                        Text(formatRupiah(p.price),
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formatRupiah(_total),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                          fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Column(
                children: [
                  // ── Pilih Cup (hanya untuk jus) ───────────────
                  if (isJus) ...[
                    const _SectionLabel(label: 'Ukuran Cup'),
                    const SizedBox(height: 8),
                    Row(
                      children: ['J', 'M', 'S'].map((size) {
                        final sel = _cupSize == size;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _cupSize = size),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: sel
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: sel
                                        ? const Color(0xFF2E7D32)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      size == 'J' ? 'Jumbo' : size == 'M' ? 'Medium' : 'Small',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: sel ? Colors.white : Colors.black54),
                                    ),
                                    Text(
                                      size,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: sel ? Colors.white : Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],
                  // ── Topping (hanya untuk mie) ─────────────────
                  if (!isJus && p.toppingPrice > 0) ...[
                    const _SectionLabel(label: 'Topping'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _hasTopping = !_hasTopping),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _hasTopping
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _hasTopping
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _hasTopping
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: _hasTopping
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tambah Topping',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _hasTopping
                                      ? const Color(0xFF1B5E20)
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              '+${formatRupiah(p.toppingPrice)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  // ── Qty ───────────────────────────────────────
                  const _SectionLabel(label: 'Jumlah'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _QtyBtn(
                          icon: Icons.remove,
                          onTap: () {
                            if (_qty > 1) setState(() => _qty--);
                          }),
                      const SizedBox(width: 20),
                      Text('$_qty',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 20),
                      _QtyBtn(
                          icon: Icons.add,
                          onTap: () => setState(() => _qty++)),
                    ],
                  ),
                ],
              ),
            ),
            // ── Tombol Tambah ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(
                          context,
                          (
                            cupSize: isJus ? _cupSize : '',
                            hasTopping: _hasTopping,
                            qty: _qty,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Tambah ke Keranjang  ${formatRupiah(_total)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1B5E20))),
      );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      );
}
