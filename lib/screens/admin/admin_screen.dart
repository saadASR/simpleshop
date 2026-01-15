import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _productFormKey = GlobalKey<FormState>();
  final _productName = TextEditingController();
  final _productDesc = TextEditingController();
  final _productPrice = TextEditingController();

  dynamic _productImage;
  bool _isUploadingImage = false;
  static const String cloudName = 'dzjlarnuv';
  static const String uploadPreset = 'flutter_profiles';

  final _inviteFormKey = GlobalKey<FormState>();
  final _inviteEmail = TextEditingController();
  final _inviteFullName = TextEditingController();

  bool _isCreatingProduct = false;
  bool _isInviting = false;

  Future<void> _createProduct() async {
    if (!_productFormKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => _isCreatingProduct = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final price = double.tryParse(_productPrice.text.trim()) ?? 0.0;
      String? photoUrl;
      if (_productImage != null) {
        photoUrl = await _uploadProductImage(_productImage);
      }
      await FirebaseFirestore.instance.collection('products').add({
        'name': _productName.text.trim(),
        'description': _productDesc.text.trim(),
        'price': price,
        'photoUrl': photoUrl,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product created')),
      );

      _productName.clear();
      _productDesc.clear();
      _productPrice.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create product: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isCreatingProduct = false);
    }
  }

  Future<void> _pickProductImage() async {
    if (!mounted) return;
    final picker = ImagePicker();
    if (kIsWeb) {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        setState(() {
          _productImage = {'name': picked.name, 'bytes': bytes, 'webPath': picked.path};
        });
      }
    } else {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        if (!mounted) return;
        setState(() {
          _productImage = picked;
        });
      }
    }
  }

  Future<String?> _uploadProductImage(dynamic image) async {
    if (!mounted) return null;
    setState(() => _isUploadingImage = true);
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset;

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes('file', image['bytes'], filename: image['name']),
        );
      } else {
        final bytes = await image.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: image.name),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        return data['secure_url'];
      }
      return null;
    } finally {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _inviteDeliveryUser() async {
    if (!_inviteFormKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => _isInviting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('delivery_invites').add({
        'email': _inviteEmail.text.trim(),
        'fullName': _inviteFullName.text.trim(),
        'createdBy': uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery user invited (pending)')),
      );

      _inviteEmail.clear();
      _inviteFullName.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to invite: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isInviting = false);
    }
  }

  @override
  void dispose() {
    _productName.dispose();
    _productDesc.dispose();
    _productPrice.dispose();
    _inviteEmail.dispose();
    _inviteFullName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Create Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Form(
              key: _productFormKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickProductImage,
                    child: _productImage != null
                        ? (kIsWeb
                            ? Image.memory(_productImage['bytes'], height: 160, width: double.infinity, fit: BoxFit.cover)
                            : Image.file(_productImage, height: 160, width: double.infinity, fit: BoxFit.cover))
                        : Container(
                            height: 160,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: const Center(child: Icon(Icons.camera_alt, size: 40)),
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _productName,
                    decoration: const InputDecoration(labelText: 'Product name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _productDesc,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  TextFormField(
                    controller: _productPrice,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isCreatingProduct ? null : _createProduct,
                    child: _isCreatingProduct ? const CircularProgressIndicator() : const Text('Create Product'),
                  ),
                ],
              ),
            ),

            const Divider(height: 32),

            const Text('Invite Delivery User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Form(
              key: _inviteFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _inviteEmail,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => v == null || !v.contains('@') ? 'Invalid email' : null,
                  ),
                  TextFormField(
                    controller: _inviteFullName,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isInviting ? null : _inviteDeliveryUser,
                    child: _isInviting ? const CircularProgressIndicator() : const Text('Invite Delivery User'),
                  ),
                ],
              ),
            ),

            const Divider(height: 32),

            const Text('Pending Invites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('delivery_invites')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const Text('No invites');
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final data = d.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['email'] ?? ''),
                      subtitle: Text('Status: ${data['status'] ?? 'pending'}'),
                      trailing: data['status'] == 'pending'
                          ? TextButton(
                              child: const Text('Revoke'),
                              onPressed: () async {
                                await d.reference.delete();
                              },
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
