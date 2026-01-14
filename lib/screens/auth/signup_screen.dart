import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  dynamic _profileImage;
  bool _isLoading = false;

  // 🔒 Cloudinary unsigned upload
  static const String cloudName = "dzjlarnuv";
  static const String uploadPreset = "flutter_profiles";

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    if (kIsWeb) {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _profileImage = {
            'name': picked.name,
            'bytes': bytes,
            'webPath': picked.path,
          };
        });
      }
    } else {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _profileImage = picked;
        });
      }
    }
  }

  Future<String?> _uploadImage(dynamic image) async {
    final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset;

    if (kIsWeb) {
      // Web: use bytes directly
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          image['bytes'],
          filename: image['name'],
        ),
      );
    } else {
      // Mobile/Desktop: use file path
      final bytes = await image.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: image.name,
        ),
      );
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseData);
      return data['secure_url'];
    }
    return null;
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? photoUrl;

      if (_profileImage != null) {
        photoUrl = await _uploadImage(_profileImage!);
      }

      UserCredential credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'fullName': _fullNameController.text.trim(),
        'birthday': _birthdayController.text.trim(),
        'email': _emailController.text.trim(),
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // back to sign in
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        await _handleEmailInUse(_emailController.text.trim());
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message ?? e.code}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailInUse(String email) async {
    try {
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      final providerText = methods.isNotEmpty ? methods.join(', ') : 'password';

      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Email already in use'),
            content: Text('This email is already registered using: $providerText.\n\nWhat would you like to do?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              if (methods.contains('password'))
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to sign in screen with pre-filled email
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SignInScreen(initialEmail: email),
                      ),
                    );
                  },
                  child: const Text('Sign in'),
                ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _sendPasswordReset(email);
                },
                child: const Text('Reset password'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching providers: $e')),
        );
      }
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send reset email: ${e.message ?? e.code}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage != null
                      ? kIsWeb
                          ? MemoryImage(_profileImage['bytes'])
                          : FileImage(_profileImage)
                      : null,
                  child: _profileImage == null
                      ? const Icon(Icons.camera_alt, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (v) =>
                v == null || v.isEmpty ? "Required" : null,
              ),

              TextFormField(
                controller: _birthdayController,
                decoration: const InputDecoration(
                  labelText: "Birthday",
                  hintText: "Select your birthday",
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Default to 18 years ago
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)), // Minimum age 13
                  );
                  
                  if (pickedDate != null) {
                    setState(() {
                      _birthdayController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                    });
                  }
                },
                validator: (v) {
                  if (v == null || v.isEmpty) return "Required";
                  
                  // Validate date format and age
                  try {
                    DateTime birthday = DateTime.parse(v);
                    DateTime now = DateTime.now();
                    int age = now.year - birthday.year;
                    
                    // Adjust age if birthday hasn't occurred this year yet
                    if (now.month < birthday.month || 
                        (now.month == birthday.month && now.day < birthday.day)) {
                      age--;
                    }
                    
                    if (age < 13) {
                      return "You must be at least 13 years old";
                    }
                    if (age > 120) {
                      return "Please enter a valid date";
                    }
                  } catch (e) {
                    return "Invalid date format";
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) =>
                v == null || !v.contains('@') ? "Invalid email" : null,
              ),

              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (v) =>
                v != null && v.length < 6 ? "Min 6 characters" : null,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Create Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
