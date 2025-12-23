import 'package:booking_app/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key}); // ✅ super.key

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ')),
        body: Center(
          child: Text(
            'Không tìm thấy thông tin người dùng.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
          ),
        ),
      );
    }

    final ten = (user.name).toString().trim();
    final email = (user.email).toString().trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 54,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: cs.surface,
                    child: Icon(
                      Icons.person,
                      size: 52,
                      color: cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tên
                Text(
                  ten.isNotEmpty ? ten : 'Người dùng',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),

                // Email
                Text(
                  email.isNotEmpty ? email : 'Chưa có email',
                  style: TextStyle(
                    fontSize: 15.5,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.35),
          ),

          const SizedBox(height: 6),

          _mucMenu(
            context: context,
            icon: Icons.edit_outlined,
            tieuDe: 'Chỉnh sửa hồ sơ',
            onTap: () => Navigator.of(context).pushNamed('/edit-profile'),
          ),

          _mucMenu(
            context: context,
            icon: Icons.lock_outline,
            tieuDe: 'Đổi mật khẩu',
            ghiChu: 'Sắp có',
            onTap: () {
              // TODO: điều hướng sang màn Đổi mật khẩu
            },
          ),

          _mucMenu(
            context: context,
            icon: Icons.notifications_outlined,
            tieuDe: 'Thông báo',
            ghiChu: 'Sắp có',
            onTap: () {
              // TODO: điều hướng sang cài đặt thông báo
            },
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Card(
              color: cs.surface,
              elevation: isDark ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
                ),
              ),
              child: ListTile(
                leading: Icon(Icons.logout, color: cs.error),
                title: Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: cs.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () => authProvider.signOut(context),
              ),
            ),
          ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _mucMenu({
    required BuildContext context,
    required IconData icon,
    required String tieuDe,
    String? ghiChu,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Card(
        color: cs.surface,
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
          ),
        ),
        child: ListTile(
          leading: Icon(icon, color: cs.secondary),
          title: Text(
            tieuDe,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          subtitle: (ghiChu != null && ghiChu.trim().isNotEmpty)
              ? Text(
            ghiChu,
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.65)),
          )
              : null,
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
