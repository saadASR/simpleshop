import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../products/products_screen.dart';
import '../user/cart_drawer.dart';

class LandingHomeScreen extends StatelessWidget {
  const LandingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const CartDrawer(),
      appBar: AppBar(
        title: const Text('SimpleShop'),
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
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.primary.withOpacity(0.12),
              cs.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(Icons.storefront, size: 54, color: cs.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'SimpleShop',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Découvrez nos produits et commandez en quelques secondes.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProductsScreen()),
                    );
                  },
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text('Voir les produits'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProductsScreen()),
                    );
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Parcourir le catalogue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
