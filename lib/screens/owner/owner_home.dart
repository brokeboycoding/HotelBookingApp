import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ⭐ Import màn login & hồ sơ dùng chung
import '../login/login_screen.dart';
import '../user_profile_screen.dart';

class OwnerHome extends StatelessWidget {
  const OwnerHome({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // Sau khi signOut → quay về Login và xóa toàn bộ history
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trang Chủ Khách Sạn (Owner)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: "Hồ sơ",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Đăng xuất",
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Xin chào Chủ khách sạn!",
          style: TextStyle(fontSize: 26),
        ),
      ),
    );
  }
}
