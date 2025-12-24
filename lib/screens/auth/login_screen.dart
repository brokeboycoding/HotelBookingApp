import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../providers/auth_providers.dart';
import '../../providers/theme_provider.dart'; // ✅ theme theo vai trò
import '../home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();

  final emailCtrl = TextEditingController();
  final matKhauCtrl = TextEditingController();

  bool anMatKhau = true;
  bool dangXuLy = false;

  @override
  void initState() {
    super.initState();

    // ✅ trước đăng nhập = guest (role null)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ThemeProvider>().setCurrentRole(null);
    });
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    matKhauCtrl.dispose();
    super.dispose();
  }

  Future<void> luuNguoiDungFirestore(fb_auth.User user) async {
    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await doc.get();

    final duLieuCoBan = <String, dynamic>{
      'email': user.email ?? '',
      'name': user.displayName ?? '',
      'avatarUrl': user.photoURL ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snap.exists) {
      await doc.set({
        ...duLieuCoBan,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } else {
      await doc.set(duLieuCoBan, SetOptions(merge: true));
    }
  }

  void hienThongBao(String noiDung, {bool laLoi = true}) {
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

  Future<void> diSauDangNhap() async {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> dangNhapBangEmail() async {
    if (dangXuLy) return;
    if (!formKey.currentState!.validate()) return;

    setState(() => dangXuLy = true);
    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.signIn(
        email: emailCtrl.text.trim(),
        password: matKhauCtrl.text,
      );

      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await luuNguoiDungFirestore(user);
      }

      await diSauDangNhap();
    } catch (e) {
      hienThongBao(authProvider.errorMessage ?? 'Đăng nhập thất bại: $e');
    } finally {
      if (mounted) setState(() => dangXuLy = false);
    }
  }

  Future<void> dangNhapBangGoogle() async {
    if (dangXuLy) return;

    setState(() => dangXuLy = true);

    try {
      fb_auth.UserCredential userCredential;

      if (kIsWeb) {
        final provider = fb_auth.GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});

        userCredential =
        await fb_auth.FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;

        final googleAuth = await googleUser.authentication;
        final credential = fb_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential =
        await fb_auth.FirebaseAuth.instance.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user != null) {
        await luuNguoiDungFirestore(user);
      }

      await diSauDangNhap();
    } catch (e) {
      hienThongBao('Lỗi đăng nhập Google: $e');
    } finally {
      if (mounted) setState(() => dangXuLy = false);
    }
  }

  Future<void> quenMatKhau() async {
    final emailHienTai = emailCtrl.text.trim();

    String? emailCanGui = emailHienTai;
    if (emailCanGui.isEmpty || !emailCanGui.contains('@')) {
      final nhapCtrl = TextEditingController(text: emailHienTai);

      emailCanGui = await showDialog<String>(
        context: context,
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            title: const Text('Quên mật khẩu'),
            content: TextField(
              controller: nhapCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Nhập email của bạn'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, nhapCtrl.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.secondary,
                  foregroundColor: cs.onSecondary,
                ),
                child: const Text('Gửi'),
              ),
            ],
          );
        },
      );
    }

    if (emailCanGui == null ||
        emailCanGui.isEmpty ||
        !emailCanGui.contains('@')) {
      return;
    }

    try {
      await fb_auth.FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailCanGui);
      hienThongBao('✅ Đã gửi email đặt lại mật khẩu.', laLoi: false);
    } catch (e) {
      hienThongBao('Không thể gửi email: $e');
    }
  }

  Widget nutGoc({
    required IconData icon,
    required VoidCallback? onTap,
    required ColorScheme cs,
    required bool isDark,
    String? tooltip,
  }) {
    final enabled = onTap != null;
    final iconColor =
    enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.45);

    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: cs.surface.withValues(alpha: isDark ? 0.35 : 0.65),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: iconColor),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final authProvider = context.watch<AuthProvider>();
    final voHieuHoa = dangXuLy || authProvider.isLoading;

    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark(context);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final lopPhu = isDark
        ? cs.scrim.withValues(alpha: 0.65)
        : cs.scrim.withValues(alpha: 0.35);

    final nenThe = isDark
        ? cs.surface.withValues(alpha: 0.20)
        : cs.surface.withValues(alpha: 0.78);

    final vienThe = isDark
        ? cs.outlineVariant.withValues(alpha: 0.30)
        : cs.outlineVariant.withValues(alpha: 0.50);

    final mauChuChinh = cs.onSurface;
    final mauChuPhu = cs.onSurface.withValues(alpha: 0.75);

    InputDecoration inputDeco(String goiY) {
      return InputDecoration(
        hintText: goiY,
        filled: true,
        fillColor: isDark
            ? cs.surface.withValues(alpha: 0.18)
            : cs.surface.withValues(alpha: 0.92),
        hintStyle: TextStyle(color: mauChuPhu),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: vienThe),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: vienThe),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.secondary, width: 1.6),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image:
                  NetworkImage('https://picsum.photos/seed/hotel/1920/1080'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // ✅ FIX 1: overlay không ăn touch
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(color: lopPhu),
              ),
            ),
          ),

          // CONTENT (form) - nằm dưới
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxCardWidth =
                constraints.maxWidth >= 520 ? 420.0 : double.infinity;

                return Center(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxCardWidth),
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
                                  color: cs.shadow.withValues(
                                      alpha: isDark ? 0.25 : 0.12),
                                ),
                              ],
                            ),
                            child: Form(
                              key: formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Chào mừng quay lại',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: mauChuChinh,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Đăng nhập để tiếp tục',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(color: mauChuPhu),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    style: TextStyle(color: mauChuChinh),
                                    decoration: inputDeco('Email'),
                                    validator: (value) {
                                      final v = (value ?? '').trim();
                                      if (v.isEmpty) return 'Vui lòng nhập email';
                                      if (!v.contains('@')) {
                                        return 'Email không hợp lệ';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: matKhauCtrl,
                                    obscureText: anMatKhau,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      if (!voHieuHoa) dangNhapBangEmail();
                                    },
                                    style: TextStyle(color: mauChuChinh),
                                    decoration: inputDeco('Mật khẩu').copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          anMatKhau
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: mauChuPhu,
                                        ),
                                        onPressed: () {
                                          setState(
                                                  () => anMatKhau = !anMatKhau);
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      final v = value ?? '';
                                      if (v.isEmpty) {
                                        return 'Vui lòng nhập mật khẩu';
                                      }
                                      if (v.length < 6) {
                                        return 'Mật khẩu tối thiểu 6 ký tự';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed:
                                      voHieuHoa ? null : quenMatKhau,
                                      child: Text(
                                        'Quên mật khẩu?',
                                        style: TextStyle(color: mauChuPhu),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ElevatedButton(
                                    onPressed:
                                    voHieuHoa ? null : dangNhapBangEmail,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: cs.secondary,
                                      foregroundColor: cs.onSecondary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: voHieuHoa
                                        ? SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.6,
                                        color: cs.onSecondary,
                                      ),
                                    )
                                        : const Text('Đăng nhập'),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: vienThe)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Text(
                                          'HOẶC',
                                          style: TextStyle(color: mauChuPhu),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: vienThe)),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  OutlinedButton(
                                    onPressed: voHieuHoa
                                        ? null
                                        : dangNhapBangGoogle,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: mauChuChinh,
                                      side: BorderSide(color: vienThe),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Image.network(
                                          'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                                          width: 18,
                                          height: 18,
                                          errorBuilder: (c, e, s) {
                                            return Icon(
                                              Icons.g_mobiledata,
                                              size: 22,
                                              color: mauChuChinh,
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 10),
                                        const Text('Tiếp tục với Google'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Chưa có tài khoản? ',
                                        style: TextStyle(color: mauChuPhu),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                              const RegisterScreen(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Đăng ký',
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
                );
              },
            ),
          ),

          // ✅ FIX 2: Đặt 2 nút góc LÊN TRÊN CÙNG (stack child cuối) + Positioned
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    nutGoc(
                      icon: Icons.arrow_back,
                      onTap: voHieuHoa
                          ? null
                          : () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context)
                              .pushReplacementNamed('/intro');
                        }
                      },
                      cs: cs,
                      isDark: isDark,
                      tooltip: 'Quay lại',
                    ),
                    nutGoc(
                      icon: isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      onTap:
                      voHieuHoa ? null : () => themeProvider.toggle(context),
                      cs: cs,
                      isDark: isDark,
                      tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
