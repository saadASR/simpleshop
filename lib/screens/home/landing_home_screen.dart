import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../products/products_screen.dart';
import '../user/cart_drawer.dart';
import '../../widgets/app_section_header.dart';

class LandingHomeScreen extends StatelessWidget {
  const LandingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const CartDrawer(),
      appBar: AppBar(
        title: const Text('Accueil'),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              // Hero Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(Icons.storefront, size: 44, color: cs.onSecondaryContainer),
                      ),
                      const SizedBox(height: 16),
                      AppSectionHeader(
                        title: 'Bienvenue sur SimpleShop',
                        subtitle: 'Découvrez nos produits et commandez en quelques secondes.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Quick Actions
              AppSectionHeader(
                title: 'Commencer',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.secondary,
                  foregroundColor: cs.onSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
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
    );
  }
}
