import 'package:flutter/material.dart';
import '../database/transaction_dao.dart';
import '../models/transaction_record.dart';
import '../utils/currency.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _dao = TransactionDao();

  int _todayTotal = 0;
  int _weekTotal = 0;
  int _monthTotal = 0;
  List<Map<String, dynamic>> _itemSummary = [];
  List<TransactionRecord> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _dao.getTodayTotal(),
      _dao.getWeekTotal(),
      _dao.getMonthTotal(),
      _dao.getTodayItemSummary(),
      _dao.getTodayTransactions(),
    ]);
    if (!mounted) return;
    setState(() {
      _todayTotal = results[0] as int;
      _weekTotal = results[1] as int;
      _monthTotal = results[2] as int;
      _itemSummary = results[3] as List<Map<String, dynamic>>;
      _transactions = results[4] as List<TransactionRecord>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F0),
      appBar: AppBar(
        title: const Text('Riwayat & Pendapatan'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildRevenueCards(),
                  const SizedBox(height: 16),
                  _buildItemSummaryCard(),
                  const SizedBox(height: 16),
                  _buildTransactionList(),
                ],
              ),
            ),
    );
  }

  // ─── Kartu Pendapatan ─────────────────────────────────────────
  Widget _buildRevenueCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Pendapatan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _RevenueCard(
                label: 'Hari Ini',
                amount: _todayTotal,
                icon: Icons.today,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RevenueCard(
                label: 'Minggu Ini',
                amount: _weekTotal,
                icon: Icons.date_range,
                color: const Color(0xFF388E3C),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RevenueCard(
                label: 'Bulan Ini',
                amount: _monthTotal,
                icon: Icons.calendar_month,
                color: const Color(0xFF43A047),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Rekap Item Terjual Hari Ini ──────────────────────────────
  Widget _buildItemSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long,
                    color: Color(0xFF2E7D32), size: 20),
                SizedBox(width: 8),
                Text(
                  'Keterangan Penjualan Hari Ini',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (_itemSummary.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Belum ada transaksi hari ini',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else ...[
              // Header tabel
              const _ItemRow(
                name: 'Produk',
                qty: 'Qty',
                harga: 'Total',
                isHeader: true,
              ),
              const Divider(height: 8),
              ..._itemSummary.map(
                (row) => _ItemRow(
                  name: row['product_name'] as String,
                  qty: '${row['total_qty']}x',
                  harga: formatRupiah(row['total_harga'] as int),
                ),
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL HARI INI',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    formatRupiah(_todayTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Daftar Transaksi Hari Ini ────────────────────────────────
  Widget _buildTransactionList() {
    if (_transactions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Daftar Transaksi Hari Ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
        ),
        ...List.generate(_transactions.length, (i) {
          final tx = _transactions[i];
          final jam =
              '${tx.createdAt.hour.toString().padLeft(2, '0')}:'
              '${tx.createdAt.minute.toString().padLeft(2, '0')}';
          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE8F5E9),
                child: Text(
                  '#${tx.id}',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                formatRupiah(tx.totalPrice),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Pukul $jam'),
              trailing: const Icon(Icons.chevron_right,
                  color: Color(0xFF2E7D32)),
              onTap: () => _showDetail(tx),
            ),
          );
        }),
      ],
    );
  }

  // ─── BottomSheet Detail Transaksi ────────────────────────────
  Future<void> _showDetail(TransactionRecord tx) async {
    final items = await _dao.getItemsOf(tx.id);
    if (!mounted) return;
    final jam =
        '${tx.createdAt.hour.toString().padLeft(2, '0')}:'
        '${tx.createdAt.minute.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaksi #${tx.id}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Pukul $jam',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 20),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(item.productName)),
                    Text('${item.qty}x',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: Text(
                        formatRupiah(item.subtotal),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  formatRupiah(tx.totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget helpers ───────────────────────────────────────────────

class _RevenueCard extends StatelessWidget {
  final String label;
  final int amount;
  final IconData icon;
  final Color color;

  const _RevenueCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color, color.withAlpha(200)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 6),
            Text(
              formatRupiah(amount),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final String name;
  final String qty;
  final String harga;
  final bool isHeader;

  const _ItemRow({
    required this.name,
    required this.qty,
    required this.harga,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      fontSize: isHeader ? 12 : 13,
      color: isHeader ? Colors.grey.shade600 : Colors.black87,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(name, style: style)),
          SizedBox(
              width: 40, child: Text(qty, style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 90, child: Text(harga, style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
