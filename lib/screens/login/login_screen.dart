import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'register_screen.dart';
import '../../main.dart'; // ⭐ Để dùng RoleWrapper

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  // ===========================================================
  // ⭐ Lưu user vào Firestore — tạo mới nếu chưa tồn tại
  // ===========================================================
  Future<void> saveUserToFirestore(User user) async {
    final doc = FirebaseFirestore.instance.collection("users").doc(user.uid);
    final snap = await doc.get();

    if (!snap.exists) {
      await doc.set({
        "email": user.email,
        "role": "customer",
      });
    }
  }

  // ===========================================================
  // ⭐ ĐĂNG NHẬP GOOGLE — Web + Android
  // ===========================================================
  Future<void> signInWithGoogle() async {
    try {
      // ---------------- WEB LOGIN ----------------
      if (kIsWeb) {
        GoogleAuthProvider provider = GoogleAuthProvider();
        provider.addScope("email");
        provider.setCustomParameters({"prompt": "select_account"});

        final userCredential =
        await FirebaseAuth.instance.signInWithPopup(provider);

        await saveUserToFirestore(userCredential.user!);

        if (!mounted) return;

        // ⭐ Điều hướng
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleWrapper()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng nhập Google Web thành công")),
        );
        return;
      }

      // ---------------- ANDROID LOGIN ----------------
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      await saveUserToFirestore(userCredential.user!);

      if (!mounted) return;

      // ⭐ Điều hướng
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleWrapper()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng nhập Google Android thành công")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi Google: $e")),
      );
    }
  }

  // ===========================================================
  // ⭐ ĐĂNG NHẬP EMAIL + PASSWORD
  // ===========================================================
  Future<void> login() async {
    setState(() => loading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      await saveUserToFirestore(userCredential.user!);

      if (!mounted) return;

      // ⭐ Điều hướng sau login thành công
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleWrapper()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng nhập thành công")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }

    if (mounted) setState(() => loading = false);
  }

  // ===========================================================
  // ⭐ UI
  // ===========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff2f6ff),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(28),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Chào mừng trở lại!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Đăng nhập để tiếp tục",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 30),

                // EMAIL
                TextField(
                  controller: email,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // PASSWORD
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Mật khẩu",
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text("Chưa có tài khoản? Đăng ký ngay"),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Đăng nhập",
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text("Hoặc", style: TextStyle(fontSize: 15)),
                const SizedBox(height: 20),

                // GOOGLE LOGIN
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: signInWithGoogle,
                    icon: Image.network(
                      "https://upload.wikimedia.org/wikipedia/commons/0/09/IOS_Google_icon.png",
                      width: 26,
                      height: 26,
                    ),
                    label: const Text(
                      "Đăng nhập bằng Google",
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
