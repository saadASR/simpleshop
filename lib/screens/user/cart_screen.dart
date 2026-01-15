import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../order/confirmation_screen.dart';

class CartScreen extends StatelessWidget {
  final VoidCallback? onBrowse;
  const CartScreen({super.key, this.onBrowse});

  Future<void> _checkout(BuildContext context, String uid, List items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    final total = items.fold<double>(0.0, (sum, i) => sum + ((i['price'] ?? 0) * (i['qty'] ?? 1)));

    // show progress dialog
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

      if (!context.mounted) return;

      // clear cart
      await FirebaseFirestore.instance.collection('carts').doc(uid).set({'items': []});

      if (!context.mounted) return;

      // dismiss progress
      Navigator.of(context, rootNavigator: true).pop();

      // navigate to confirmation screen with order id
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ConfirmationScreen(orderId: doc.id)),
      );
    } catch (e) {
      // dismiss progress
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not signed in'));

    final cartRef = FirebaseFirestore.instance.collection('carts').doc(user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: cartRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final items = (data?['items'] as List?) ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Your cart is empty', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onBrowse ?? () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tap the Products tab to browse products')));
                  },
                  child: const Text('Browse Products'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final it = items[i];
                  return ListTile(
                    leading: it['photoUrl'] != null ? Image.network(it['photoUrl'], width: 56, height: 56, fit: BoxFit.cover) : const Icon(Icons.shopping_bag),
                    title: Text(it['name'] ?? ''),
                    subtitle: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () async {
                            final newItems = List.from(items);
                            if ((newItems[i]['qty'] ?? 1) > 1) {
                              newItems[i]['qty'] = (newItems[i]['qty'] ?? 1) - 1;
                            } else {
                              newItems.removeAt(i);
                            }
                            await cartRef.set({'items': newItems});
                          },
                        ),
                        Text('Qty: ${it['qty'] ?? 1}'),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () async {
                            final newItems = List.from(items);
                            newItems[i]['qty'] = (newItems[i]['qty'] ?? 1) + 1;
                            await cartRef.set({'items': newItems});
                          },
                        ),
                        const SizedBox(width: 12),
                        Text(((it['price'] ?? 0) * (it['qty'] ?? 1)).toString()),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final newItems = List.from(items);
                        newItems.removeAt(i);
                        await cartRef.set({'items': newItems});
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _checkout(context, user.uid, items),
                      child: const Text('Checkout'),
                    ),
                  ),
                ],
              ),
            )
          ],
        );
      },
    );
  }
}
