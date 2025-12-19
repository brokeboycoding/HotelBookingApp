import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking_management_screen.dart';
import 'room_management_screen.dart';
import 'statistics_screen.dart';
import 'user_management_screen.dart';
import '../../sample_data.dart';
import '../login/login_screen.dart';
import '../profile/user_profile_screen.dart';

// ✅ THÊM IMPORT trang duyệt đơn
import 'admin_owner_requests_screen.dart'; // <- đổi đúng path theo project bạn

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;

  final List<Widget> _screens = const [
    RoomManagementScreen(),
    BookingManagementScreen(),
    UserManagementScreen(),
    StatisticsScreen(),
  ];

  User? get _user => FirebaseAuth.instance.currentUser;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _adminStream() {
    final u = _user;
    if (u == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(u.uid).snapshots();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  String _titleByIndex(int idx) {
    switch (idx) {
      case 0:
        return "Quản lý phòng";
      case 1:
        return "Quản lý đặt phòng";
      case 2:
        return "Quản lý người dùng";
      default:
        return "Thống kê";
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleByIndex(_index)),
        backgroundColor: Colors.blueAccent,
        actions: [
          // ✅ NÚT: mở trang duyệt đơn owner
          IconButton(
            tooltip: "Duyệt đăng ký Owner",
            icon: const Icon(Icons.assignment_turned_in_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminOwnerRequestsScreen(),
                ),
              );
            },
          ),

          IconButton(
            tooltip: "Hồ sơ",
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserProfileScreen()),
              );
            },
          ),
        ],
      ),

      drawer: Drawer(
        child: u == null
            ? ListView(
          children: const [
            DrawerHeader(child: Text("Chưa đăng nhập")),
          ],
        )
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _adminStream(),
          builder: (context, snap) {
            final data = snap.data?.data() ?? {};

            final name = (data['name'] ?? u.displayName ?? "Admin").toString();
            final email = (u.email ?? data['email'] ?? "admin@gmail.com").toString();
            final avatarUrl = (data['avatarUrl'] ?? u.photoURL ?? "").toString().trim();

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(name),
                  accountEmail: Text(email),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? const Icon(Icons.admin_panel_settings, size: 40, color: Colors.blueAccent)
                        : null,
                  ),
                  decoration: const BoxDecoration(color: Colors.blueAccent),
                ),

                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("Hồ sơ Admin"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                    );
                  },
                ),

                // ✅ THÊM MỤC: Duyệt đơn Owner trong Drawer
                ListTile(
                  leading: const Icon(Icons.assignment_turned_in),
                  title: const Text("Duyệt đăng ký Owner"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminOwnerRequestsScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.meeting_room),
                  title: const Text("Quản lý phòng"),
                  selected: _index == 0,
                  onTap: () {
                    setState(() => _index = 0);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.book_online),
                  title: const Text("Quản lý đặt phòng"),
                  selected: _index == 1,
                  onTap: () {
                    setState(() => _index = 1);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text("Quản lý người dùng"),
                  selected: _index == 2,
                  onTap: () {
                    setState(() => _index = 2);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text("Thống kê"),
                  selected: _index == 3,
                  onTap: () {
                    setState(() => _index = 3);
                    Navigator.pop(context);
                  },
                ),

                const Divider(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: generateSampleHotelData,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text("Tạo dữ liệu mẫu"),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
                  onTap: logout,
                ),
              ],
            );
          },
        ),
      ),

      body: _screens[_index],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: "Phòng"),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: "Đặt phòng"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Người dùng"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Thống kê"),
        ],
      ),
    );
  }
}
