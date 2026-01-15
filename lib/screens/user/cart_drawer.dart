import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../order/confirmation_screen.dart';

class CartDrawer extends StatelessWidget {
  const CartDrawer({super.key});

  Future<void> _checkout(BuildContext context, String uid, List items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre panier est vide')),
      );
      return;
    }

    final total = items.fold<double>(
      0.0,
      (sum, i) => sum + (((i['price'] ?? 0) as num).toDouble() * ((i['qty'] ?? 1) as num).toDouble()),
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final doc = await FirebaseFirestore.instance.collection('orders').add({
        'customerId': uid,
        'items': items,
        'total': total,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('carts').doc(uid).set({'items': []});

      if (context.mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ConfirmationScreen(orderId: doc.id)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Commande échouée: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: SafeArea(
        child: user == null
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('Connectez-vous pour voir votre panier')),
              )
            : _CartDrawerBody(uid: user.uid, onCheckout: _checkout),
      ),
    );
  }
}

class _CartDrawerBody extends StatelessWidget {
  final String uid;
  final Future<void> Function(BuildContext context, String uid, List items) onCheckout;

  const _CartDrawerBody({required this.uid, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final cartRef = FirebaseFirestore.instance.collection('carts').doc(uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: cartRef.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final items = (data?['items'] as List?) ?? [];

        final total = items.fold<double>(
          0.0,
          (sum, i) => sum + (((i['price'] ?? 0) as num).toDouble() * ((i['qty'] ?? 1) as num).toDouble()),
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Panier',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (items.isEmpty)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Ajoutez des produits pour commencer.'),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final it = items[i] as Map<String, dynamic>;
                    final qty = (it['qty'] ?? 1) as num;
                    final price = ((it['price'] ?? 0) as num).toDouble();
                    final photoUrl = it['photoUrl'];

                    return Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 54,
                                height: 54,
                                child: photoUrl is String
                                    ? Image.network(photoUrl, fit: BoxFit.cover)
                                    : Container(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        child: const Icon(Icons.shopping_bag_outlined),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (it['name'] ?? '').toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('${(price * qty).toStringAsFixed(2)} €'),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final newItems = List.from(items);
                                if (qty > 1) {
                                  newItems[i]['qty'] = qty.toInt() - 1;
                                } else {
                                  newItems.removeAt(i);
                                }
                                await cartRef.set({'items': newItems});
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(qty.toInt().toString()),
                            IconButton(
                              onPressed: () async {
                                final newItems = List.from(items);
                                newItems[i]['qty'] = qty.toInt() + 1;
                                await cartRef.set({'items': newItems});
                              },
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              onPressed: () async {
                                final newItems = List.from(items);
                                newItems.removeAt(i);
                                await cartRef.set({'items': newItems});
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text('${total.toStringAsFixed(2)} €', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => onCheckout(context, uid, items),
                      child: const Text('Commander'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
