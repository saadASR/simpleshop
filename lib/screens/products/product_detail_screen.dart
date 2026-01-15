import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../order/confirmation_screen.dart';
import '../user/cart_drawer.dart';

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

    return Scaffold(
      drawer: const CartDrawer(),
      appBar: AppBar(
        title: Text((p['name'] ?? 'Produit').toString()),
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
        padding: const EdgeInsets.all(16),
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: Icon(Icons.image, size: 56)),
            ),
          const SizedBox(height: 12),
          Text(p['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${price.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(p['description'] ?? ''),
          const SizedBox(height: 18),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text('Quantité', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(
                    onPressed: () => setState(() => _qty++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addToCart,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Ajouter au panier'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isOrdering ? null : _orderNow,
                  child: _isOrdering
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Commander'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
