import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ConfirmationScreen extends StatelessWidget {
  final String orderId;
  const ConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmation')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Commande non trouvée: $orderId'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List items = List.from(data['items'] ?? []);
          final total = ((data['total'] ?? 0) as num).toDouble();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 96),
                const SizedBox(height: 12),
                const Text('Commande confirmée !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('ID de la commande : $orderId', textAlign: TextAlign.center),
                const SizedBox(height: 16),

                const Text('Récapitulatif', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final it = items[i] as Map<String, dynamic>;
                      final qty = it['qty'] ?? 1;
                      final price = ((it['price'] ?? 0) as num).toDouble();
                      return ListTile(
                        leading: it['photoUrl'] != null ? Image.network(it['photoUrl'], width: 56, height: 56, fit: BoxFit.cover) : const Icon(Icons.shopping_bag),
                        title: Text(it['name'] ?? ''),
                        subtitle: Text('Qty: $qty'),
                        trailing: Text('${(qty * price).toStringAsFixed(2)} €'),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
                Text('Total: ${total.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                const SizedBox(height: 12),
                const Text('Votre commande a bien été enregistrée.', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('Retour à l\'accueil'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
