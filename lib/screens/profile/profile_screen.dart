import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../widgets/app_section_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['fullName'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your profile')),
      );
    }
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            tooltip: _isEditing ? 'Sauvegarder' : 'Modifier',
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _toggleEdit,
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Profile data not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String fullName = data['fullName'] ?? 'Unknown';
          final String email = data['email'] ?? user.email ?? 'No email';
          final String phone = data['phone'] ?? 'No phone';
          final String address = data['address'] ?? 'No address';
          final String? photoUrl = data['photoUrl'];
          final String role = data['role'] ?? 'user';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isEditing ? _pickImage : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: cs.surfaceContainerHighest,
                                backgroundImage: photoUrl != null
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: photoUrl == null
                                    ? Icon(Icons.person, size: 60, color: cs.onSurfaceVariant)
                                    : null,
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cs.secondary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: cs.surface, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          fullName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            role[0].toUpperCase() + role.substring(1),
                            style: TextStyle(
                              color: cs.onSecondaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSectionHeader(
                          title: 'Informations personnelles',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoField(
                          icon: Icons.email,
                          label: 'Email',
                          value: email,
                          isEditable: false,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoField(
                          icon: Icons.person,
                          label: 'Full Name',
                          value: _nameController.text,
                          controller: _nameController,
                          isEditable: _isEditing,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoField(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: _phoneController.text,
                          controller: _phoneController,
                          isEditable: _isEditing,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoField(
                          icon: Icons.location_on,
                          label: 'Address',
                          value: _addressController.text,
                          controller: _addressController,
                          isEditable: _isEditing,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Statistics
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSectionHeader(
                          title: 'Statistiques d\'achats',
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('orders')
                              .where('customerId', isEqualTo: user.uid)
                              .snapshots(),
                          builder: (context, ordersSnap) {
                            if (ordersSnap.connectionState == ConnectionState.waiting) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Commandes',
                                      '—',
                                      Icons.shopping_bag,
                                      cs.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total dépensé',
                                      '—',
                                      Icons.attach_money,
                                      cs.secondary,
                                    ),
                                  ),
                                ],
                              );
                            }

                            final docs = ordersSnap.data?.docs ?? const [];
                            final totalOrders = docs.length;
                            double totalSpent = 0;
                            for (final doc in docs) {
                              final data = (doc.data() as Map<String, dynamic>);
                              final v = (data['total'] ?? data['totalPrice'] ?? 0);
                              if (v is num) {
                                totalSpent += v.toDouble();
                              }
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Commandes',
                                    totalOrders.toString(),
                                    Icons.shopping_bag,
                                    cs.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Total dépensé',
                                    '€${totalSpent.toStringAsFixed(2)}',
                                    Icons.attach_money,
                                    cs.secondary,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required String label,
    required String value,
    TextEditingController? controller,
    bool isEditable = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.primary),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: isEditable && controller != null
              ? TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(fontSize: 16, color: cs.onSurface),
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _toggleEdit() async {
    if (_isEditing) {
      // Save changes
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fullName': _nameController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 70,
      );

      if (image != null) {
        // Here you would upload the image to a service like Firebase Storage
        // and update the user's photoUrl field
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image upload would be implemented here'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
