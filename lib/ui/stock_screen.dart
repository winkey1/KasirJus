import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/stock_dao.dart';
import '../models/stock_item.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _dao = StockDao();
  List<StockItem> _items = [];
  int _todayGulaAdded = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWithReset();
  }

  Future<void> _loadWithReset() async {
    setState(() => _loading = true);
    // Reset gula ke 0 jika hari baru
    await _dao.ensureGulaReset();
    final results = await Future.wait([
      _dao.getAll(),
      _dao.getTodayGulaAdded(),
    ]);
    if (mounted) {
      setState(() {
        _items = results[0] as List<StockItem>;
        _todayGulaAdded = results[1] as int;
        _loading = false;
      });
    }
  }

  /// Tampilkan dialog konfirmasi + note sebelum mengurangi stok
  Future<void> _askNoteAndAdjust(StockItem item, int delta) async {
    final noteCtrl = TextEditingController();
    final isReduction = delta < 0;

    // Untuk penambahan gula, tidak perlu note — langsung proses
    if (!isReduction) {
      await _dao.adjustWithNote(item.id, delta);
      _loadWithReset();
      return;
    }

    // Dialog di TOP layar — keyboard di bawah tidak bertabrakan di landscape
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _TopDialog(
        title: 'Kurangi ${item.label}',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kurangi ${item.label} sebanyak '
                '${delta.abs()} ${item.unit}?',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Keterangan (opsional)',
                hintText: 'Contoh: 1 cup J pecah',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kurangi'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _dao.adjustWithNote(item.id, delta,
          note: noteCtrl.text.trim());
      _loadWithReset();
    }
  }

  Future<void> _editManual(StockItem item) async {
    final ctrl = TextEditingController(text: '${item.qty}');
    final noteCtrl = TextEditingController();

    // Dialog di TOP layar — keyboard di bawah tidak bertabrakan di landscape
    await showDialog<void>(
      context: context,
      builder: (ctx) => _TopDialog(
        title: 'Set Stok — ${item.label}',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Jumlah (${item.unit})',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Keterangan (opsional)',
                hintText: 'Contoh: 1 cup J pecah',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            if (item.name == 'gula') ...[  
              const SizedBox(height: 6),
              Text(
                'Gula akan reset ke 0 setiap hari baru.',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
              ),
            ],
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
                final v = int.tryParse(ctrl.text.trim()) ?? item.qty;
                await _dao.setQtyWithLog(item.id, v,
                    note: noteCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                _loadWithReset();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F0),
      appBar: AppBar(
        title: const Text('Stok Modal'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadWithReset),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWithReset,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.inventory_2,
                                  color: Color(0xFF2E7D32), size: 20),
                              SizedBox(width: 8),
                              Text('Jumlah Bahan Modal',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20))),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                              'Cup & Indomie: otomatis berkurang tiap transaksi',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                          const Text('Gula: reset ke 0 setiap hari baru',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                          const Text('Tap angka untuk edit langsung',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 8),
                          ..._items.map((item) => _StockRow(
                                item: item,
                                onMinus: () =>
                                    _askNoteAndAdjust(item, -1),
                                onPlus: () =>
                                    _askNoteAndAdjust(item, 1),
                                onTapQty: () => _editManual(item),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGulaCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildGulaCard() {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.water_drop,
                  color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gula Terpakai Hari Ini',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20))),
                  Text('Dari setiap penambahan stok gula hari ini',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Text(
              '$_todayGulaAdded kg',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Row item stok ────────────────────────────────────────────────

class _StockRow extends StatelessWidget {
  final StockItem item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onTapQty;

  const _StockRow({
    required this.item,
    required this.onMinus,
    required this.onPlus,
    required this.onTapQty,
  });

  Color get _indicatorColor {
    if (item.qty == 0) return Colors.red.shade400;
    if (item.qty < 10) return Colors.orange.shade600;
    return const Color(0xFF2E7D32);
  }

  IconData get _icon {
    if (item.name.startsWith('cup')) return Icons.local_drink;
    if (item.name == 'mie_indomie') return Icons.ramen_dining;
    return Icons.water_drop;
  }

  String get _autoLabel =>
      item.name == 'gula' ? 'Manual·Reset Harian' : 'Auto-kurang';

  Color get _autoColor =>
      item.name == 'gula' ? Colors.orange.shade700 : const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE8F5E9),
            child: Icon(_icon, color: const Color(0xFF2E7D32), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Text(item.unit,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _autoColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_autoLabel,
                          style: TextStyle(
                              fontSize: 9,
                              color: _autoColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            color: Colors.red.shade400,
            onPressed: onMinus,
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          GestureDetector(
            onTap: onTapQty,
            child: Container(
              width: 50,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _indicatorColor.withAlpha(25),
                border: Border.all(color: _indicatorColor, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${item.qty}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _indicatorColor)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: const Color(0xFF2E7D32),
            onPressed: onPlus,
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
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
