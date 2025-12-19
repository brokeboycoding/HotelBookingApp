import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../login/login_screen.dart';
import 'user_edit_profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? currentUser;
  bool loggingOut = false;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _refresh() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      await u.reload();
    }
    if (!mounted) return;
    setState(() {
      currentUser = FirebaseAuth.instance.currentUser;
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .snapshots();
  }

  Future<void> _logout() async {
    if (loggingOut) return;

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
    } finally {
      if (mounted) setState(() => loggingOut = false);
    }
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
          'Hồ sơ tài khoản',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: "Tải lại",
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text('Không tìm thấy tài khoản đang đăng nhập'))
          : RefreshIndicator(
        onRefresh: _refresh,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userDocStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
              return const Center(child: Text('Không tìm thấy dữ liệu người dùng'));
            }

            final data = snapshot.data!.data() ?? {};

            // Auth (để luôn có email/avatar mới nhất sau khi reload)
            final authEmail = FirebaseAuth.instance.currentUser?.email;
            final authPhoto = FirebaseAuth.instance.currentUser?.photoURL;
            final authName = FirebaseAuth.instance.currentUser?.displayName;

            final role = (data['role'] ?? 'customer').toString();

            final name =
            (data['name'] ?? authName ?? _defaultNameForRole(role)).toString();

            final email =
            (authEmail ?? data['email'] ?? widgetFallbackEmail()).toString();

            // avatar ưu tiên: Firestore avatarUrl -> Auth photoURL
            final avatarUrl =
            (data['avatarUrl'] as String?)?.trim().isNotEmpty == true
                ? (data['avatarUrl'] as String).trim()
                : (authPhoto ?? '').trim();

            final pendingEmail = (data['pendingEmail'] ?? '').toString().trim();

            final createdAt = data['createdAt'];
            String createdText = 'Không rõ';
            if (createdAt is Timestamp) {
              final dt = createdAt.toDate();
              createdText = '${dt.day}/${dt.month}/${dt.year}';
            }

            final roleStyle = _roleStyle(role);

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                        backgroundColor: roleStyle.avatarBg,
                        backgroundImage:
                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? Icon(roleStyle.icon, size: 40, color: roleStyle.mainColor)
                            : null,
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
                          roleStyle.label.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: roleStyle.mainColor,
                      ),

                      // ✅ pending email
                      if (pendingEmail.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'Đang chờ xác nhận đổi email: $pendingEmail\n'
                                'Hãy kiểm tra hộp thư và bấm link xác nhận, rồi nhấn “Tải lại”.',
                            style: const TextStyle(fontSize: 13.5),
                          ),
                        ),
                      ],
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Tên hiển thị', name),
                      const Divider(height: 24),
                      _buildInfoRow('Email', email),
                      const Divider(height: 24),
                      _buildInfoRow('Vai trò', roleStyle.label),
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
                                builder: (_) => UserEditProfileScreen(
                                  currentName: name,
                                  currentEmail: email,
                                  currentAvatarUrl: avatarUrl,
                                ),
                              ),
                            );

                            if (updated == true && mounted) {
                              // reload auth + rebuild stream UI
                              await _refresh();
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Chỉnh sửa hồ sơ'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
            );
          },
        ),
      ),
    );
  }

  // fallback khi dữ liệu thiếu
  String widgetFallbackEmail() {
    return currentUser?.email ?? 'Không có email';
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 15)),
        ),
      ],
    );
  }

  String _defaultNameForRole(String role) {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'owner':
        return 'Chủ khách sạn';
      default:
        return 'Khách hàng';
    }
  }

  _RoleStyle _roleStyle(String role) {
    switch (role) {
      case 'admin':
        return _RoleStyle(
          label: 'Quản trị viên',
          mainColor: Colors.deepPurpleAccent,
          avatarBg: Colors.deepPurpleAccent.withValues(alpha: 0.15),
          icon: Icons.admin_panel_settings,
        );
      case 'owner':
        return _RoleStyle(
          label: 'Chủ khách sạn',
          mainColor: Colors.deepOrange,
          avatarBg: Colors.deepOrange.withValues(alpha: 0.15),
          icon: Icons.business,
        );
      default:
        return _RoleStyle(
          label: 'Khách hàng',
          mainColor: Colors.teal,
          avatarBg: Colors.teal.withValues(alpha: 0.15),
          icon: Icons.person,
        );
    }
  }
}

class _RoleStyle {
  final String label;
  final Color mainColor;
  final Color avatarBg;
  final IconData icon;

  _RoleStyle({
    required this.label,
    required this.mainColor,
    required this.avatarBg,
    required this.icon,
  });
}
