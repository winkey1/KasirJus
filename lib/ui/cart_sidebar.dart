import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/cart_notifier.dart';
import '../models/cart_entry.dart';
import '../utils/currency.dart';

const _kSidebarWidth = 280.0;

class CartSidebar extends StatelessWidget {
  const CartSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartNotifier>();
    final items = cart.items;

    return SizedBox(
      width: _kSidebarWidth,
      child: ClipRect(
        child: Container(
          color: const Color(0xFFF5F5F5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Flexible(child: _buildItemList(context, items)),
              const Divider(height: 1),
              _buildTotal(cart.total),
              _buildPayButton(context, cart),
              if (!cart.isEmpty) _buildResetButton(context, cart),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text('Pesanan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildItemList(BuildContext context, List<CartEntry> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Belum ada pesanan',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => _CartItemRow(entry: items[i]),
    );
  }

  Widget _buildTotal(int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(formatRupiah(total),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32))),
        ],
      ),
    );
  }

  Widget _buildPayButton(BuildContext context, CartNotifier cart) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: cart.isEmpty ? null : () => _onPay(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('BAYAR',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, CartNotifier cart) {
    return SizedBox(
      height: 32,
      child: TextButton(
        onPressed: () => context.read<CartNotifier>().clear(),
        style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: const Text('Batal / Reset',
            style: TextStyle(color: Colors.red, fontSize: 12)),
      ),
    );
  }

  Future<void> _onPay(BuildContext context) async {
    final cart = context.read<CartNotifier>();
    await cart.checkout();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi tersimpan')));
    }
  }
}

// ─── Row item di keranjang ────────────────────────────────────────

class _CartItemRow extends StatelessWidget {
  final CartEntry entry;
  const _CartItemRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final key = entry.cartKey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry.qty}x ${entry.displayName}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('@ ${formatRupiah(entry.unitPrice)}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          SizedBox(
            width: 65,
            child: Text(formatRupiah(entry.subtotal),
                style: const TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32)),
                textAlign: TextAlign.right),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => context.read<CartNotifier>().setQty(key, 0),
          ),
        ],
      ),
    );
  }
}
