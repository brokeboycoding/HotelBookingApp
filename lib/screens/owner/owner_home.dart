import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../login/login_screen.dart';
import '../profile/user_profile_screen.dart';
import 'owner_rooms_screen.dart';

class OwnerHome extends StatefulWidget {
  const OwnerHome({super.key});

  @override
  State<OwnerHome> createState() => _OwnerHomeState();
}

class _OwnerHomeState extends State<OwnerHome> {
  int _index = 0;

  User? get _user => FirebaseAuth.instance.currentUser;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _ownerStream() {
    final u = _user;
    if (u == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(u.uid).snapshots();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  String _titleByIndex(int i) {
    switch (i) {
      case 0:
        return "Tổng quan";
      case 1:
        return "Phòng";
      case 2:
        return "Đặt phòng";
      default:
        return "Doanh thu";
    }
  }

  // ✅ CHỈ GIỮ 1 LIST
  final List<Widget> _screens = const [
    Center(child: Text("Tổng quan Owner", style: TextStyle(fontSize: 20))),
    OwnerRoomsScreen(), // ✅ tab Phòng
    Center(child: Text("Quản lý đặt phòng (Owner)", style: TextStyle(fontSize: 20))),
    Center(child: Text("Doanh thu/Thống kê (Owner)", style: TextStyle(fontSize: 20))),
  ];

  @override
  Widget build(BuildContext context) {
    final u = _user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleByIndex(_index)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: "Hồ sơ",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Đăng xuất",
            onPressed: _logout,
          ),
        ],
      ),

      drawer: Drawer(
        child: u == null
            ? ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(child: Text("Chưa đăng nhập")),
          ],
        )
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _ownerStream(),
          builder: (context, snap) {
            final data = snap.data?.data() ?? {};
            final name = (data['name'] ?? u.displayName ?? "Chủ khách sạn").toString();
            final email = (u.email ?? data['email'] ?? "").toString();
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
                        ? const Icon(Icons.business, size: 38, color: Colors.deepOrange)
                        : null,
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text("Hồ sơ"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                    );
                  },
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text("Tổng quan"),
                  selected: _index == 0,
                  onTap: () {
                    setState(() => _index = 0);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.meeting_room),
                  title: const Text("Phòng"),
                  selected: _index == 1,
                  onTap: () {
                    setState(() => _index = 1);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.book_online),
                  title: const Text("Đặt phòng"),
                  selected: _index == 2,
                  onTap: () {
                    setState(() => _index = 2);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text("Doanh thu"),
                  selected: _index == 3,
                  onTap: () {
                    setState(() => _index = 3);
                    Navigator.pop(context);
                  },
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
                  onTap: _logout,
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Tổng quan"),
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: "Phòng"),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: "Đặt phòng"),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: "Doanh thu"),
        ],
      ),
    );
  }
}
