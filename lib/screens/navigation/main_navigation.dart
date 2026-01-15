import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_products_screen.dart';
import '../cart/cart_screen.dart';
import '../home/landing_home_screen.dart';
import '../order/orders_history_screen.dart';
import '../products/products_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final role = (data?['role'] ?? 'user').toString();

        late final List<Widget> screens;
        late final List<BottomNavigationBarItem> items;

        if (role == 'admin') {
          screens = const [
            AdminDashboardScreen(),
            AdminProductsScreen(),
            OrdersHistoryScreen(isAdmin: true),
            ProfileScreen(),
          ];
          items = const [
            BottomNavigationBarItem(icon: Icon(Icons.space_dashboard_outlined), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Produits'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Historique'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
          ];
        } else {
          screens = const [
            LandingHomeScreen(),
            ProductsScreen(),
            CartScreen(),
            OrdersHistoryScreen(isAdmin: false),
            ProfileScreen(),
          ];
          items = const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Produits'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Panier'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Historique'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
          ];
        }

        if (_currentIndex >= screens.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          body: screens[_currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            destinations: [
              for (final it in items)
                NavigationDestination(
                  icon: it.icon,
                  selectedIcon: it.activeIcon ?? it.icon,
                  label: it.label ?? '',
                ),
            ],
          ),
        );
      },
    );
  }
}
