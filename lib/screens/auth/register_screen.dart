import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_providers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  final hoTenCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final sdtCtrl = TextEditingController();
  final matKhauCtrl = TextEditingController();
  final nhapLaiMatKhauCtrl = TextEditingController();

  bool anMatKhau = true;
  UserRole vaiTroChon = UserRole.user;

  @override
  void dispose() {
    hoTenCtrl.dispose();
    emailCtrl.dispose();
    sdtCtrl.dispose();
    matKhauCtrl.dispose();
    nhapLaiMatKhauCtrl.dispose();
    super.dispose();
  }

  void thongBao(String noiDung, {bool laLoi = false}) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noiDung),
        behavior: SnackBarBehavior.floating,
        backgroundColor: laLoi ? cs.errorContainer : cs.tertiaryContainer,
      ),
    );
  }

  Future<void> dangKy() async {
    if (!formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.signUp(
        email: emailCtrl.text.trim(),
        password: matKhauCtrl.text,
        name: hoTenCtrl.text.trim(),
        role: vaiTroChon,
        phone: sdtCtrl.text.trim().isEmpty ? null : sdtCtrl.text.trim(),
      );

      if (!mounted) return;
      thongBao('✅ Đăng ký thành công!');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      thongBao(authProvider.errorMessage ?? '❌ Đăng ký thất bại: $e', laLoi: true);
    }
  }

  InputDecoration inputDeco(BuildContext context, String goiY) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final vien = cs.outlineVariant.withValues(alpha: isDark ? 0.30 : 0.45);

    return InputDecoration(
      hintText: goiY,
      filled: true,
      fillColor: isDark
          ? cs.surface.withValues(alpha: 0.18)
          : cs.surface.withValues(alpha: 0.85),
      hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.70)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: vien),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: vien),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.secondary, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final nenPhu = isDark
        ? cs.scrim.withValues(alpha: 0.65)
        : cs.scrim.withValues(alpha: 0.35);

    final nenThe = isDark
        ? cs.surface.withValues(alpha: 0.20)
        : cs.surface.withValues(alpha: 0.70);

    final vienThe = isDark
        ? cs.outlineVariant.withValues(alpha: 0.30)
        : cs.outlineVariant.withValues(alpha: 0.45);

    final mauChuChinh = cs.onSurface;
    final mauChuPhu = cs.onSurface.withValues(alpha: 0.75);

    return Scaffold(
      body: Stack(
        children: [
          // Ảnh nền
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://picsum.photos/seed/register/1920/1080'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Lớp phủ theo theme
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: nenPhu))),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: nenThe,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: vienThe),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 24,
                            color: cs.shadow.withValues(alpha: isDark ? 0.25 : 0.15),
                          ),
                        ],
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Tạo tài khoản',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: mauChuChinh,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bắt đầu hành trình đặt phòng của bạn',
                              style: theme.textTheme.titleMedium?.copyWith(color: mauChuPhu),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Họ tên
                            TextFormField(
                              controller: hoTenCtrl,
                              style: TextStyle(color: mauChuChinh),
                              decoration: inputDeco(context, 'Họ và tên'),
                              validator: (value) {
                                final v = (value ?? '').trim();
                                if (v.isEmpty) return 'Vui lòng nhập họ và tên';
                                if (v.length < 2) return 'Họ và tên quá ngắn';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Email
                            TextFormField(
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: mauChuChinh),
                              decoration: inputDeco(context, 'Email'),
                              validator: (value) {
                                final v = (value ?? '').trim();
                                if (v.isEmpty) return 'Vui lòng nhập email';
                                if (!v.contains('@')) return 'Email không hợp lệ';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // SĐT
                            TextFormField(
                              controller: sdtCtrl,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(color: mauChuChinh),
                              decoration: inputDeco(context, 'Số điện thoại (không bắt buộc)'),
                            ),
                            const SizedBox(height: 14),

                            // Mật khẩu
                            TextFormField(
                              controller: matKhauCtrl,
                              obscureText: anMatKhau,
                              style: TextStyle(color: mauChuChinh),
                              decoration: inputDeco(context, 'Mật khẩu').copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    anMatKhau
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: mauChuPhu,
                                  ),
                                  onPressed: () => setState(() => anMatKhau = !anMatKhau),
                                ),
                              ),
                              validator: (value) {
                                final v = value ?? '';
                                if (v.isEmpty) return 'Vui lòng nhập mật khẩu';
                                if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Nhập lại mật khẩu
                            TextFormField(
                              controller: nhapLaiMatKhauCtrl,
                              obscureText: true,
                              style: TextStyle(color: mauChuChinh),
                              decoration: inputDeco(context, 'Nhập lại mật khẩu'),
                              validator: (value) {
                                if ((value ?? '') != matKhauCtrl.text) {
                                  return 'Mật khẩu nhập lại không khớp';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            Text(
                              'Bạn là...',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: mauChuChinh,
                              ),
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: nutChonVaiTro(
                                    context,
                                    tieuDe: 'Khách đặt phòng',
                                    role: UserRole.user,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: nutChonVaiTro(
                                    context,
                                    tieuDe: 'Chủ khách sạn',
                                    role: UserRole.hotelOwner,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            Consumer<AuthProvider>(
                              builder: (context, authProvider, _) {
                                final dangTai = authProvider.isLoading;
                                return ElevatedButton(
                                  onPressed: dangTai ? null : dangKy,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cs.secondary,
                                    foregroundColor: cs.onSecondary,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: dangTai
                                      ? SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.6,
                                      color: cs.onSecondary,
                                    ),
                                  )
                                      : const Text('Đăng ký'),
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Đã có tài khoản? ',
                                  style: TextStyle(color: mauChuPhu),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: cs.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget nutChonVaiTro(
      BuildContext context, {
        required String tieuDe,
        required UserRole role,
      }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final duocChon = vaiTroChon == role;

    final vien = duocChon
        ? cs.secondary
        : cs.outlineVariant.withValues(alpha: theme.brightness == Brightness.dark ? 0.30 : 0.45);

    final nen = duocChon ? cs.secondary.withValues(alpha: 0.16) : null;

    final mauChu = duocChon ? cs.secondary : cs.onSurface.withValues(alpha: 0.75);

    return OutlinedButton(
      onPressed: () => setState(() => vaiTroChon = role),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: nen,
        side: BorderSide(color: vien),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        tieuDe,
        textAlign: TextAlign.center,
        style: TextStyle(color: mauChu, fontWeight: FontWeight.w800),
      ),
    );
  }
}
