import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  Future<void> _updateStatus(DocumentReference ref, String status) async {
    await ref.update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('delivererId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No assigned orders'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order: ${d.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (data['items'] != null) Text('Items: ${data['items'].toString()}'),
                      const SizedBox(height: 8),
                      Text('Status: $status'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (status == 'pending')
                            ElevatedButton(
                              child: const Text('Accept'),
                              onPressed: () => _updateStatus(d.reference, 'accepted'),
                            ),
                          const SizedBox(width: 8),
                          if (status == 'accepted')
                            ElevatedButton(
                              child: const Text('Picked Up'),
                              onPressed: () => _updateStatus(d.reference, 'picked_up'),
                            ),
                          const SizedBox(width: 8),
                          if (status == 'picked_up')
                            ElevatedButton(
                              child: const Text('Delivered'),
                              onPressed: () => _updateStatus(d.reference, 'delivered'),
                            ),
                        ],
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
