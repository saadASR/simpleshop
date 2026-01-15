import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../admin/admin_delivery_invites_screen.dart';
import '../admin/admin_products_screen.dart';
import '../delivery/delivery_screen.dart';
import '../user/cart_screen.dart';
import '../user/orders_screen.dart';
import '../products/product_detail_screen.dart';
import '../order/confirmation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('User data not found')));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String fullName = data['fullName'] ?? 'Unknown';
        final String? photoUrl = data['photoUrl'];
        final String role = data['role'] ?? 'user';



        // Build the list of tabs/pages based on role
        final List<Widget> pages = [
          _buildProfileTab(fullName, photoUrl, role),
        ];

        final List<BottomNavigationBarItem> items = [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        ];

        if (role == 'user') {
          pages.add(_buildProductsTab());
          items.add(const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Products'));
          pages.add(const OrdersScreen());
          items.add(const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'));
          pages.add(CartScreen(onBrowse: () => setState(() => _selectedIndex = 1)));
          items.add(const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'));
        } else if (role == 'admin') {
          pages.add(const AdminProductsScreen());
          items.add(const BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Produits'));
          pages.add(const AdminDeliveryInvitesScreen());
          items.add(const BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'Invites'));
        } else if (role == 'deliver') {
          pages.add(const DeliveryScreen());
          items.add(const BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Delivery'));
        }

        // Ensure selected index is valid (role may have changed)
        if (_selectedIndex >= pages.length) _selectedIndex = 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('SimpleShop'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
          body: pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            items: items,
            onTap: (idx) => setState(() => _selectedIndex = idx),
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }

  Future<void> _addToCart(String uid, String productId, Map<String, dynamic> product) async {
    final cartRef = FirebaseFirestore.instance.collection('carts').doc(uid);
    final doc = await cartRef.get();
    List items = [];
    if (doc.exists) items = List.from(doc.data()!['items'] ?? []);

    // find existing item
    final idx = items.indexWhere((e) => e['productId'] == productId);
    if (idx >= 0) {
      items[idx]['qty'] = (items[idx]['qty'] ?? 1) + 1;
    } else {
      items.add({
        'productId': productId,
        'name': product['name'] ?? '',
        'price': product['price'] ?? 0,
        'photoUrl': product['photoUrl'],
        'qty': 1,
      });
    }

    await cartRef.set({'items': items});
  }

  Future<DocumentReference?> _buyNow(String uid, String productId, Map<String, dynamic> product) async {
    try {
      final order = {
        'customerId': uid,
        'items': [
          {
            'productId': productId,
            'name': product['name'] ?? '',
            'price': product['price'] ?? 0,
            'photoUrl': product['photoUrl'],
            'qty': 1,
          }
        ],
        'total': (product['price'] ?? 0),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };
      final doc = await FirebaseFirestore.instance.collection('orders').add(order);
      return doc;
    } catch (e) {
      return null;
    }
  }

  Widget _buildProfileTab(String fullName, String? photoUrl, String role) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null ? const Icon(Icons.person, size: 60) : null,
          ),
          const SizedBox(height: 20),
          Text(
            fullName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Role: ' + (role[0].toUpperCase() + role.substring(1)), style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No products'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data() as Map<String, dynamic>;
            final price = (data['price'] ?? 0).toDouble();
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: d.id, product: data)),
                );
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['photoUrl'] != null)
                        Image.network(data['photoUrl'], height: 160, width: double.infinity, fit: BoxFit.cover),
                      const SizedBox(height: 8),
                      Text(data['name'] ?? 'Unnamed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(data['description'] ?? ''),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('\u007F ' + price.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              TextButton(
                                child: const Text('Add to cart'),
                                onPressed: () async {
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in')));
                                    return;
                                  }
                                  await _addToCart(user.uid, d.id, data);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                                },
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                child: const Text('Buy now'),
                                onPressed: () async {
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in')));
                                    return;
                                  }
                                  final doc = await _buyNow(user.uid, d.id, data);
                                  if (doc != null) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => ConfirmationScreen(orderId: doc.id)),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order failed')));
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
