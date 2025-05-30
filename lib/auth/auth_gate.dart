import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/buyer/buyer_main.dart';
import '../screens/seller/seller_main.dart';
import '../screens/admin/admin_dashboard.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData) {
          return const LoginPage();
        }

        final uid = snapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const LoginPage();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final role = userData['role'];

            if (role == 'buyer') {
              return const BuyerMainPage();
            } else if (role == 'seller') {
              return const SellerMainPage();
            } else if (role == 'admin') {
              return const AdminDashboard();
            } else {
              return const Scaffold(body: Center(child: Text("Unknown role.")));
            }
          },
        );
      },
    );
  }
}
