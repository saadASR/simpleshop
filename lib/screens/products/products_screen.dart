import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../user/cart_drawer.dart';
import 'product_detail_screen.dart';
import '../../widgets/app_product_card.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/app_section_header.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

          final query = _query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
          final filtered = query.isEmpty
              ? products
              : products.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final n = (data['name'] ?? '').toString().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
                  final d = (data['description'] ?? '').toString().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
                  return n.contains(query) || d.contains(query);
                }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSectionHeader(
                      title: 'Catalogue',
                      subtitle: 'Trouvez ce dont vous avez besoin',
                      trailing: Builder(
                        builder: (context) {
                          return IconButton(
                            tooltip: 'Panier',
                            icon: const Icon(Icons.shopping_cart_outlined),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppSearchField(
                      hintText: 'Rechercher un produit…',
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 56, color: Colors.grey),
                              const SizedBox(height: 12),
                              const Text(
                                'Aucun résultat',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Essayez un autre mot-clé.',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: tileExtent,
                          childAspectRatio: gridAspectRatio,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index].data() as Map<String, dynamic>;
                          final productId = filtered[index].id;
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

                          return AppProductCard(
                            name: name,
                            description: description,
                            price: price,
                            imageUrl: imageUrl,
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
                            onAddToCart: addToCart,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
