import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  static const String cloudName = 'dzjlarnuv';
  static const String uploadPreset = 'flutter_profiles';

  Future<String?> _uploadProductImage(dynamic image) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)..fields['upload_preset'] = uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes('file', image['bytes'], filename: image['name']),
    );

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseData);
      return data['secure_url'];
    }
    return null;
  }

  Future<dynamic> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    return {'name': picked.name, 'bytes': bytes, 'webPath': kIsWeb ? picked.path : null};
  }

  Future<void> _openProductEditor({required BuildContext context, String? productId, Map<String, dynamic>? initial}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: (initial?['name'] ?? '').toString());
    final desc = TextEditingController(text: (initial?['description'] ?? '').toString());
    final price = TextEditingController(text: (initial?['price'] ?? '').toString());

    dynamic pickedImage;
    bool isSaving = false;
    bool isUploading = false;
    bool didPop = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void safeSetSheetState(VoidCallback fn) {
              if (!ctx.mounted) return;
              setSheetState(fn);
            }

            Future<void> pick() async {
              final img = await _pickImage();
              if (!ctx.mounted) return;
              if (img != null) safeSetSheetState(() => pickedImage = img);
            }

            Future<void> save() async {
              if (!formKey.currentState!.validate()) return;
              safeSetSheetState(() => isSaving = true);

              try {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Veuillez vous connecter.')),
                    );
                  }
                  return;
                }

                final p = double.tryParse(price.text.trim().replaceAll(',', '.')) ?? 0.0;
                String? photoUrl = (initial?['photoUrl'] ?? initial?['imageUrl']) as String?;

                if (pickedImage != null) {
                  safeSetSheetState(() => isUploading = true);
                  final uploaded = await _uploadProductImage(pickedImage);
                  if (!ctx.mounted) return;
                  photoUrl = uploaded;
                  safeSetSheetState(() => isUploading = false);
                }

                final payload = <String, dynamic>{
                  'name': name.text.trim(),
                  'description': desc.text.trim(),
                  'price': p,
                  'photoUrl': photoUrl,
                };

                final col = FirebaseFirestore.instance.collection('products');
                if (productId == null) {
                  await col.add({
                    ...payload,
                    'createdBy': uid,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                } else {
                  await col.doc(productId).update(payload);
                }

                if (!ctx.mounted) return;
                didPop = true;
                Navigator.of(ctx).pop();
                if (context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(productId == null ? 'Produit créé' : 'Produit mis à jour')),
                    );
                  });
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              } finally {
                if (!didPop) {
                  safeSetSheetState(() {
                    isSaving = false;
                    isUploading = false;
                  });
                }
              }
            }

            final cs = Theme.of(ctx).colorScheme;
            final existingImageUrl = (initial?['photoUrl'] ?? initial?['imageUrl']) as String?;

            Widget imagePreview() {
              if (pickedImage != null) {
                return Image.memory(pickedImage['bytes'], fit: BoxFit.cover);
              }
              if (existingImageUrl != null && existingImageUrl.isNotEmpty) {
                return Image.network(existingImageUrl, fit: BoxFit.cover);
              }
              return const Center(child: Icon(Icons.image_outlined, size: 44));
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    productId == null ? 'Nouveau produit' : 'Modifier produit',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: pick,
                    child: Container(
                      height: 160,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          imagePreview(),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(Icons.camera_alt_outlined, color: cs.onPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: name,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: desc,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: price,
                          decoration: const InputDecoration(
                            labelText: 'Prix',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: isSaving ? null : save,
                    icon: isUploading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: Text(isSaving ? 'Enregistrement...' : 'Enregistrer'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      name.dispose();
      desc.dispose();
      price.dispose();
    });
  }

  Future<void> _deleteProduct(BuildContext context, String productId) async {
    final cs = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Supprimer produit'),
          content: const Text('Confirmer la suppression ?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit supprimé')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits (Admin)'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductEditor(context: context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const Center(child: Text('Aucun produit'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString();
              final price = ((data['price'] ?? 0) as num).toDouble();
              final img = (data['photoUrl'] ?? data['imageUrl']) as String?;

              return Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        child: img != null
                            ? Image.network(
                                img,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_outlined)),
                              )
                            : const Center(child: Icon(Icons.image_outlined)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text('${price.toStringAsFixed(2)} €', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Modifier',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openProductEditor(context: context, productId: d.id, initial: data),
                      ),
                      IconButton(
                        tooltip: 'Supprimer',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteProduct(context, d.id),
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
