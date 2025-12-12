import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login/login_screen.dart';

import 'owner_edit_profile_screen.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  User? currentUser;
  bool loggingOut = false; // ⭐ THÊM: trạng thái đang đăng xuất

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<Map<String, dynamic>?> _loadUserData() async {
    if (currentUser == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  // ⭐ THÊM: Hàm đăng xuất
  Future<void> _logout() async {
    setState(() => loggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng xuất: $e')),
      );
    }
    if (mounted) setState(() => loggingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff2f6ff),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xfff2f6ff),
        foregroundColor: Colors.black87,
        title: const Text(
          'Hồ sơ Chủ khách sạn',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: currentUser == null
          ? const Center(
        child: Text('Không tìm thấy tài khoản đang đăng nhập'),
      )
          : FutureBuilder<Map<String, dynamic>?>(
        future: _loadUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Không tìm thấy dữ liệu người dùng'),
            );
          }

          final data = snapshot.data!;
          final email =
              data['email'] ?? currentUser!.email ?? 'Không có email';
          final role = data['role'] ?? 'owner';
          final name = data['name'] ?? 'Chủ khách sạn';
          final createdAt = data['createdAt'];

          String createdText = 'Không rõ';
          if (createdAt is Timestamp) {
            final dt = createdAt.toDate();
            createdText = '${dt.day}/${dt.month}/${dt.year}';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Column(
              children: [
                // ===== Avatar + tên =====
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.orangeAccent
                            .withValues(alpha: 0.15),
                        child: const Icon(
                          Icons.business,
                          size: 40,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Chip(
                        label: Text(
                          role.toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: Colors.deepOrange,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ===== Thông tin chi tiết =====
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin tài khoản',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Tên hiển thị', name),
                      const Divider(height: 24),
                      _buildInfoRow('Email', email),
                      const Divider(height: 24),
                      _buildInfoRow('Vai trò', role),
                      const Divider(height: 24),
                      _buildInfoRow('Ngày tạo', createdText),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ===== Hành động =====
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OwnerEditProfileScreen(
                                  currentName: name,
                                  currentEmail: email,
                                ),
                              ),
                            );

                            if (updated == true && mounted) {
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Chỉnh sửa hồ sơ'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: loggingOut ? null : _logout,
                          icon: const Icon(Icons.logout),
                          label: loggingOut
                              ? const Text('Đang đăng xuất...')
                              : const Text('Đăng xuất'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}
