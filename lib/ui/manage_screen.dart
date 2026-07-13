import 'package:flutter/material.dart';
import '../database/product_dao.dart';
import '../models/product.dart';
import '../utils/currency.dart';

class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key});

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  final _dao = ProductDao();
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final products = await _dao.getAll();
    if (mounted) setState(() => _products = products);
  }

  Future<void> _showForm({Product? existing}) async {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
        text: existing != null ? '${existing.price}' : '');
    final toppingCtrl = TextEditingController(
        text: existing != null && existing.toppingPrice > 0
            ? '${existing.toppingPrice}'
            : '');
    bool usesIndomie = existing?.usesIndomie ?? false;

    // ── Dialog Posisi Atas (Top-Aligned): aman dari keyboard di landscape ──────
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          return _TopDialog(
            title: existing == null ? 'Tambah Produk' : 'Edit Produk',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: existing == null,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rp)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                // ── Toggle Mie ──────────────────────────
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Produk Mie / Indomie',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text(
                              'Stok indomie berkurang & bisa tambah topping',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Switch(
                      value: usesIndomie,
                      onChanged: (v) =>
                          setDlg(() => usesIndomie = v),
                      activeThumbColor: const Color(0xFF2E7D32),
                      activeTrackColor:
                          const Color(0xFF2E7D32).withAlpha(100),
                    ),
                  ],
                ),
                // ── Harga Topping (hanya muncul jika mie) ─
                if (usesIndomie) ...[  
                  const SizedBox(height: 10),
                  TextField(
                    controller: toppingCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Harga Topping (Rp)',
                      hintText: 'Contoh: 3000',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      prefixIcon: Icon(Icons.add_circle_outline,
                          size: 18, color: Color(0xFF2E7D32)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Isi 0 jika tidak ada topping',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
            actions: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final price =
                        int.tryParse(priceCtrl.text.trim()) ?? 0;
                    if (name.isEmpty || price <= 0) return;
                    final product = Product(
                      id: existing?.id,
                      name: name,
                      price: price,
                      usesIndomie: usesIndomie,
                      toppingPrice: int.tryParse(toppingCtrl.text.trim()) ?? 0,
                    );
                    if (existing == null) {
                      await _dao.insert(product);
                    } else {
                      await _dao.update(product);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _delete(Product p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Hapus "${p.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _dao.delete(p.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _products.isEmpty
          ? const Center(child: Text('Belum ada produk'))
          : ListView.separated(
              itemCount: _products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = _products[index];
                return ListTile(
                  title: Text(p.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                  subtitle: Row(
                    children: [
                      Text(formatRupiah(p.price)),
                      if (p.badge.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _StockBadge(label: p.badge),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: Color(0xFF2E7D32)),
                        onPressed: () => _showForm(existing: p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red),
                        onPressed: () => _delete(p),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}


// ─── Widget: badge stok di list produk ───────────────────────────

class _StockBadge extends StatelessWidget {
  final String label;
  const _StockBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: const Color(0xFF2E7D32), width: 0.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Dialog posisi TOP — aman dari keyboard di landscape ─────────

class _TopDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final Widget actions;

  const _TopDialog({
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    return Align(
      // Posisi di atas layar → keyboard di bawah tidak mengganggu
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(
          top: mq.padding.top + 16,
          left: w * 0.1,
          right: w * 0.1,
          bottom: mq.viewInsets.bottom > 0 ? mq.viewInsets.bottom + 16 : 16, // prevent overflow from bottom
        ),
        child: Material(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          elevation: 8,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20))),
                const SizedBox(height: 12),
                content,
                const SizedBox(height: 14),
                actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
