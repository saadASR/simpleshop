import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucune commande pour le moment.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              final total = ((data['total'] ?? 0) as num).toDouble();
              final status = (data['status'] ?? 'pending').toString();
              final items = (data['items'] as List?) ?? const [];

              final canUpdateStatus = isAdmin || (data['delivererId'] != null && data['delivererId'] == user.uid);

              return Card(
                elevation: 0,
                child: ListTile(
                  title: Text('Commande #${d.id.substring(0, 8)}'),
                  subtitle: Row(
                    children: [
                      Expanded(child: Text('Articles: ${items.length}')),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(status),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${total.toStringAsFixed(2)} €'),
                      if (canUpdateStatus)
                        PopupMenuButton<String>(
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
                          icon: const Icon(Icons.more_vert),
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
