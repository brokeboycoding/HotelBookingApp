import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking_management_screen.dart';
import 'room_management_screen.dart';
import 'statistics_screen.dart';
import 'user_management_screen.dart';
import '../../sample_data.dart';
import '../login/login_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;

  String adminName = "Admin";
  String adminEmail = "admin@gmail.com";

  final List<Widget> _screens = const [
    RoomManagementScreen(),
    BookingManagementScreen(),
    UserManagementScreen(),
    StatisticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    loadAdminInfo();
  }

  // ===========================================================
  // ⭐ Lấy thông tin admin từ Firestore
  // ===========================================================
  Future<void> loadAdminInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (snap.exists) {
        setState(() {
          adminName = snap.data()?["name"] ?? "Admin";
          adminEmail = snap.data()?["email"] ?? user.email ?? "admin@gmail.com";
        });
      }
    } catch (_) {}
  }

  // ===========================================================
  // ⭐ Đăng xuất
  // ===========================================================
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.blueAccent,
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(adminName),
              accountEmail: Text(adminEmail),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, size: 40),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.meeting_room),
              title: const Text("Quản lý phòng"),
              onTap: () {
                setState(() => _index = 0);
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.book_online),
              title: const Text("Quản lý đặt phòng"),
              onTap: () {
                setState(() => _index = 1);
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Quản lý người dùng"),
              onTap: () {
                setState(() => _index = 2);
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text("Thống kê"),
              onTap: () {
                setState(() => _index = 3);
                Navigator.pop(context);
              },
            ),

            const Divider(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: generateSampleHotelData,
                child: const Text("Tạo dữ liệu mẫu"),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title:
              const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
              onTap: logout,
            ),
          ],
        ),
      ),

      body: _screens[_index],
    );
  }
}
