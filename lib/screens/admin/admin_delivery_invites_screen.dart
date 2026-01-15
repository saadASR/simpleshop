import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDeliveryInvitesScreen extends StatefulWidget {
  const AdminDeliveryInvitesScreen({super.key});

  @override
  State<AdminDeliveryInvitesScreen> createState() => _AdminDeliveryInvitesScreenState();
}

class _AdminDeliveryInvitesScreenState extends State<AdminDeliveryInvitesScreen> {
  final _inviteFormKey = GlobalKey<FormState>();
  final _inviteEmail = TextEditingController();
  final _inviteFullName = TextEditingController();

  bool _isInviting = false;

  @override
  void dispose() {
    _inviteEmail.dispose();
    _inviteFullName.dispose();
    super.dispose();
  }

  Future<void> _inviteDeliveryUser() async {
    if (!_inviteFormKey.currentState!.validate()) return;
    setState(() => _isInviting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('delivery_invites').add({
        'email': _inviteEmail.text.trim(),
        'fullName': _inviteFullName.text.trim(),
        'createdBy': uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation envoyée')),
        );
      }

      _inviteEmail.clear();
      _inviteFullName.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isInviting = false);
    }
  }

  Future<void> _revokeInvite(DocumentReference ref) async {
    try {
      await ref.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation supprimée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inviter un livreur'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _inviteFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Nouvelle invitation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _inviteEmail,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _inviteFullName,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _isInviting ? null : _inviteDeliveryUser,
                      icon: _isInviting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_outlined),
                      label: Text(_isInviting ? 'Envoi...' : 'Envoyer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Invitations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('delivery_invites').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Erreur: ${snapshot.error}'),
                );
              }

              final docs = snapshot.data?.docs ?? const [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucune invitation'),
                );
              }

              return Column(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final email = (data['email'] ?? '').toString();
                  final fullName = (data['fullName'] ?? '').toString();
                  final status = (data['status'] ?? 'pending').toString();

                  final Color statusColor = status == 'pending' ? cs.secondary : cs.primary;
                  final Color statusTextColor = status == 'pending' ? cs.onSecondary : cs.onPrimary;

                  return Card(
                    elevation: 0,
                    child: ListTile(
                      title: Text(fullName.isEmpty ? email : fullName),
                      subtitle: Text(email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: statusTextColor, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                          if (status == 'pending')
                            IconButton(
                              tooltip: 'Supprimer',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _revokeInvite(d.reference),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
