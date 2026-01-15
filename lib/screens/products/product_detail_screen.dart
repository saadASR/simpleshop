import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../order/confirmation_screen.dart';
import '../user/cart_drawer.dart';
import '../../widgets/app_section_header.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.productId, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  bool _isOrdering = false;

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter.')),
      );
      return;
    }

    try {
      final cartRef = FirebaseFirestore.instance.collection('carts').doc(user.uid);
      final doc = await cartRef.get();
      List items = [];
      if (doc.exists) items = List.from(doc.data()!['items'] ?? []);

      final idx = items.indexWhere((e) => e['productId'] == widget.productId);
      final photoUrl = widget.product['photoUrl'] ?? widget.product['imageUrl'];

      if (idx >= 0) {
        items[idx]['qty'] = ((items[idx]['qty'] ?? 1) as num).toInt() + _qty;
      } else {
        items.add({
          'productId': widget.productId,
          'name': widget.product['name'] ?? '',
          'price': widget.product['price'] ?? 0,
          'photoUrl': photoUrl,
          'qty': _qty,
        });
      }

      await cartRef.set({'items': items});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajouté au panier.')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.message ?? e.code}')),
        );
      }
    }
  }

  Future<void> _orderNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isOrdering = true);

    final item = {
      'productId': widget.productId,
      'name': widget.product['name'] ?? '',
      'price': widget.product['price'] ?? 0,
      'photoUrl': widget.product['photoUrl'] ?? widget.product['imageUrl'],
      'qty': _qty,
    };

    final total = (_qty * ((widget.product['price'] ?? 0) as num)).toDouble();

    try {
      final doc = await FirebaseFirestore.instance.collection('orders').add({
        'customerId': user.uid,
        'items': [item],
        'total': total,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isOrdering = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ConfirmationScreen(orderId: doc.id)),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _isOrdering = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.message ?? e.code}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final price = ((p['price'] ?? 0) as num).toDouble();
    final imageUrl = (p['photoUrl'] ?? p['imageUrl']) as String?;
    final cs = Theme.of(context).colorScheme;
    final total = (price * _qty).toDouble();

    return Scaffold(
      drawer: const CartDrawer(),
      appBar: AppBar(
        title: const Text('Détails produit'),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                tooltip: 'Panier',
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 280,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: cs.surfaceContainerHighest,
                          child: const Center(child: Icon(Icons.image_outlined, size: 56)),
                        );
                      },
                    )
                  else
                    Container(
                      color: cs.surfaceContainerHighest,
                      child: const Center(child: Icon(Icons.image_outlined, size: 56)),
                    ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.fromBorderSide(
                          BorderSide(color: cs.outlineVariant.withOpacity(0.7)),
                        ),
                      ),
                      child: Text(
                        '${price.toStringAsFixed(2)} €',
                        style: TextStyle(
                          color: cs.secondary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppSectionHeader(
            title: (p['name'] ?? '').toString(),
            subtitle: 'Vendu et livré par SimpleShop',
          ),
          const SizedBox(height: 10),
          Text(
            (p['description'] ?? '').toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Quantité', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      IconButton(
                        onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      IconButton(
                        onPressed: () => setState(() => _qty++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Total', style: TextStyle(color: cs.onSurfaceVariant)),
                      const Spacer(),
                      Text(
                        '${total.toStringAsFixed(2)} €',
                        style: TextStyle(color: cs.secondary, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: cs.secondary,
              foregroundColor: cs.onSecondary,
            ),
            onPressed: _addToCart,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Ajouter au panier'),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _isOrdering ? null : _orderNow,
            child: _isOrdering
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Commander maintenant'),
          ),
        ],
      ),
    );
  }
}
