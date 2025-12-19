import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';   // ⭐ THÊM DÒNG NÀY

import 'firebase_options.dart';

// Screens
import 'screens/intro/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/owner/owner_home.dart';
import 'screens/customer/customer_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⭐ NẠP DỮ LIỆU NGÔN NGỮ cho Intl
  await initializeDateFormatting('vi', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

// ===========================================================
// ⭐ RoleWrapper — điều hướng theo ROLE
// ===========================================================

class RoleWrapper extends StatelessWidget {
  const RoleWrapper({super.key});

  Future<String?> getRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    return snap.data()?["role"];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data;

        switch (role) {
          case "admin":
            return const AdminHome();
          case "owner":
            return const OwnerHome();
          case "customer":
            return const CustomerShell();
          default:
            return const LoginScreen();
        }
      },
    );
  }
}
