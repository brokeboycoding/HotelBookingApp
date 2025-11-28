import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPass = TextEditingController();

  String selectedRole = "customer"; // mặc định
  bool loading = false;

  // ===========================================================
  // ⭐ Lưu user vào Firestore (KHÔNG ghi đè role nếu tồn tại)
  // ===========================================================
  Future<void> saveUserFirestore(String uid, String email, String role) async {
    final doc = FirebaseFirestore.instance.collection("users").doc(uid);
    final snap = await doc.get();

    // Nếu user chưa tồn tại → tạo mới
    if (!snap.exists) {
      await doc.set({
        "email": email,
        "role": role,
        "createdAt": DateTime.now(),
      });
    }
  }

  // ===========================================================
  // ⭐ ĐĂNG KÝ
  // ===========================================================
  Future<void> register() async {
    if (password.text.trim() != confirmPass.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu không khớp!")),
      );
      return;
    }

    if (email.text.trim().isEmpty || password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ email & mật khẩu")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      final user = userCredential.user!;

      // Lưu Firestore
      await saveUserFirestore(
        user.uid,
        email.text.trim(),
        selectedRole,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thành công!")),
      );

      Navigator.pop(context); // quay lại LoginScreen

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }

    if (mounted) setState(() => loading = false);
  }

  // ===========================================================
  // ⭐ UI
  // ===========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký")),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mật khẩu"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: confirmPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Nhập lại mật khẩu"),
            ),
            const SizedBox(height: 20),

            const Text(
              "Chọn quyền:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            DropdownButton<String>(
              value: selectedRole,
              items: const [
                DropdownMenuItem(
                    value: "customer", child: Text("Khách hàng")),
                DropdownMenuItem(
                    value: "owner", child: Text("Chủ khách sạn")),
                // ❌ KHÔNG CHO CHỌN ADMIN
              ],
              onChanged: (value) {
                setState(() => selectedRole = value!);
              },
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : register,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Đăng ký"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
