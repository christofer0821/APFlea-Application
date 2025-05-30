import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'auth/login_page.dart';
import 'screens/buyer/buyer_main.dart';
import 'screens/seller/seller_main.dart';
import 'screens/admin/admin_home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APFlea',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoginPage(); // Not logged in

        final uid = snapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final role = userData['role'];

            if (role == 'buyer') return const BuyerMainPage();
            if (role == 'seller') return const SellerMainPage();
            if (role == 'admin') return const AdminHomePage();

            return const Scaffold(body: Center(child: Text("Unknown role")));
          },
        );
      },
    );
  }
}
