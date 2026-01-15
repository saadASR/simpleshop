import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/app_section_header.dart';

class OrdersHistoryScreen extends StatelessWidget {
  final bool isAdmin;
  const OrdersHistoryScreen({super.key, required this.isAdmin});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'processing':
        return 'En cours';
      case 'shipped':
        return 'Expédiée';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Veuillez vous connecter.')),
      );
    }

    final cs = Theme.of(context).colorScheme;

    final query = isAdmin
        ? FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true)
        : FirebaseFirestore.instance
            .collection('orders')
            .where('customerId', isEqualTo: user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
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
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final docs = List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);
          if (!isAdmin) {
            docs.sort((a, b) {
              final ad = a.data() as Map<String, dynamic>;
              final bd = b.data() as Map<String, dynamic>;
              final at = ad['createdAt'];
              final bt = bd['createdAt'];
              final ams = at is Timestamp ? at.millisecondsSinceEpoch : 0;
              final bms = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
              return bms.compareTo(ams);
            });
          }
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Aucune commande',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vos commandes apparaîtront ici.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: AppSectionHeader(
                  title: 'Historique',
                  subtitle: isAdmin ? 'Toutes les commandes' : 'Vos commandes récentes',
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final data = d.data() as Map<String, dynamic>;
                    final total = ((data['total'] ?? 0) as num).toDouble();
                    final status = (data['status'] ?? 'pending').toString();
                    final items = (data['items'] as List?) ?? const [];
                    final createdAt = data['createdAt'];
                    final createdLabel = createdAt is Timestamp
                        ? createdAt.toDate().toString().split('.').first
                        : '';

                    final canUpdateStatus = isAdmin || (data['delivererId'] != null && data['delivererId'] == user.uid);

                    final statusBg = _statusColor(status);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Commande #${d.id.substring(0, 8)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Articles: ${items.length}',
                                    style: TextStyle(color: cs.onSurfaceVariant),
                                  ),
                                ),
                                Text(
                                  '${total.toStringAsFixed(2)} €',
                                  style: TextStyle(color: cs.secondary, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            if (createdLabel.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                createdLabel,
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ],
                            if (canUpdateStatus) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: PopupMenuButton<String>(
                                  tooltip: 'Changer le statut',
                                  onSelected: (value) async {
                                    try {
                                      await d.reference.update({
                                        'status': value,
                                        'updatedAt': FieldValue.serverTimestamp(),
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Statut mis à jour: ${_statusLabel(value)}')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Impossible de changer le statut: $e')),
                                        );
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'pending', child: Text('En attente')),
                                    PopupMenuItem(value: 'processing', child: Text('En cours')),
                                    PopupMenuItem(value: 'shipped', child: Text('Expédiée')),
                                    PopupMenuItem(value: 'delivered', child: Text('Livrée')),
                                    PopupMenuItem(value: 'cancelled', child: Text('Annulée')),
                                  ],
                                  icon: const Icon(Icons.more_horiz),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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
