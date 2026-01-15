import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../user/cart_drawer.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScaleFactorOf(context);
    final tileExtent = textScale > 1.2 ? 400.0 : (textScale > 1.0 ? 380.0 : 360.0);
    final gridAspectRatio = textScale > 1.2
        ? 0.56
        : (textScale > 1.0 ? 0.60 : 0.66);
    return Scaffold(
      drawer: const CartDrawer(),
      appBar: AppBar(
        title: const Text('Produits'),
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
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun produit disponible',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: tileExtent,
              childAspectRatio: gridAspectRatio,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;
              final productId = products[index].id;
              final String name = product['name'] ?? 'Unknown Product';
              final String description = product['description'] ?? 'No description';
              final double price = (product['price'] ?? 0).toDouble();
              final String? imageUrl = (product['imageUrl'] ?? product['photoUrl']) as String?;

              Future<void> addToCart() async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez vous connecter.')),
                  );
                  return;
                }

                final cartRef = FirebaseFirestore.instance.collection('carts').doc(user.uid);
                final doc = await cartRef.get();
                List items = [];
                if (doc.exists) items = List.from(doc.data()!['items'] ?? []);

                final idx = items.indexWhere((e) => e['productId'] == productId);
                final photoUrl = product['photoUrl'] ?? product['imageUrl'];

                if (idx >= 0) {
                  items[idx]['qty'] = ((items[idx]['qty'] ?? 1) as num).toInt() + 1;
                } else {
                  items.add({
                    'productId': productId,
                    'name': product['name'] ?? '',
                    'price': product['price'] ?? 0,
                    'photoUrl': photoUrl,
                    'qty': 1,
                  });
                }

                await cartRef.set({'items': items});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ajouté au panier.')),
                  );
                }
              }

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        productId: productId,
                        product: product,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(child: Icon(Icons.image, size: 42));
                                  },
                                )
                              : const Center(child: Icon(Icons.image, size: 42)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${price.toStringAsFixed(2)} €',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Ajouter au panier',
                                    onPressed: addToCart,
                                    icon: const Icon(Icons.add_shopping_cart),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
