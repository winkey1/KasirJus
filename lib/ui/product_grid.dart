import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/currency.dart';

const kPadS = 6.0;
const kPadM = 12.0;
const kPadL = 20.0;

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final void Function(Product) onTap;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(kPadM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: kPadM,
        crossAxisSpacing: kPadM,
        childAspectRatio: 1.2,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(product: product, onTap: onTap);
      },
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Product product;
  final void Function(Product) onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _ctrl.reverse();
    widget.onTap(widget.product);
    _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFF2E7D32).withAlpha(40),
          onTap: _handleTap,
          child: Padding(
            padding: const EdgeInsets.all(kPadS),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: kPadS),
                Text(
                  formatRupiah(widget.product.price),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
