import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String selectedRole = 'buyer';
  bool isLoading = false;
  bool _obscurePassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
        'uid': userCred.user!.uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'role': selectedRole,
        'createdAt': Timestamp.now(),
      });

      // ✅ Sign out and return to login
      await _auth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created. Please log in.")),
        );
        Navigator.of(context).pop(); // back to login
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Signup failed")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Create Account", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (value) => value!.isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                validator: (value) => value!.isEmpty ? "Enter your phone number" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) => value!.isEmpty ? "Enter your email" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) =>
                    value!.length < 6 ? "Password must be at least 6 characters" : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'buyer', child: Text("Buyer")),
                  DropdownMenuItem(value: 'seller', child: Text("Seller")),
                ],
                onChanged: (value) => setState(() => selectedRole = value!),
                decoration: const InputDecoration(labelText: "Select Role"),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: isLoading ? null : signUp,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
