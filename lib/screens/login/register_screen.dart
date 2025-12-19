import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPass = TextEditingController();

  bool loading = false;
  bool obscure = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    fullName.dispose();
    email.dispose();
    password.dispose();
    confirmPass.dispose();
    super.dispose();
  }

  // ---------- UI helpers ----------
  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.35)),
      border: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
    );
  }

  Widget _softField({required Widget child}) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  // ---------- Firestore: luôn là customer ----------
  Future<void> saveUserFirestore({
    required String uid,
    required String userEmail,
    required String name,
  }) async {
    final doc = FirebaseFirestore.instance.collection("users").doc(uid);
    final snap = await doc.get();

    if (!snap.exists) {
      await doc.set({
        "email": userEmail,
        "name": name,
        "role": "customer", // ✅ luôn khách hàng
        "avatarUrl": "",
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } else {
      // Nếu đã có user rồi: cập nhật nhẹ, KHÔNG đổi role
      await doc.set({
        "email": userEmail,
        "name": name,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> register() async {
    if (loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      final user = cred.user!;
      final name = fullName.text.trim();

      // update displayName
      try {
        await user.updateDisplayName(name);
      } catch (_) {}

      // ✅ Lưu Firestore role=customer
      await saveUserFirestore(
        uid: user.uid,
        userEmail: email.text.trim(),
        name: name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thành công!")),
      );

      // ✅ quay lại Login an toàn (không lỗi)
      Navigator.of(context).maybePop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String msg = e.message ?? e.code;
      if (e.code == 'email-already-in-use') msg = 'Email đã được sử dụng.';
      if (e.code == 'invalid-email') msg = 'Email không hợp lệ.';
      if (e.code == 'weak-password') msg = 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $msg")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final isMobile = size.width < 650;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 20 : 0,
              14,
              isMobile ? 20 : 0,
              18 + mq.viewInsets.bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 0 : 18,
                    vertical: isMobile ? 0 : 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isMobile ? 0 : 18),
                    boxShadow: isMobile
                        ? const []
                        : [
                      BoxShadow(
                        blurRadius: 24,
                        color: Colors.black.withValues(alpha: 0.06),
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            Navigator.of(context).maybePop(); // ✅ back an toàn
                          },
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          splashRadius: 22,
                        ),
                        const SizedBox(height: 6),

                        const Center(
                          child: Text(
                            "Create Account",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            "Let’s get you started in seconds",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.black.withValues(alpha: 0.45),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        const Text(
                          "Full Name",
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        _softField(
                          child: TextFormField(
                            controller: fullName,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            decoration: _decoration("Enter your name"),
                            validator: (v) {
                              final t = (v ?? "").trim();
                              if (t.isEmpty) return "Vui lòng nhập họ tên";
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          "E-mail",
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        _softField(
                          child: TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: _decoration("Enter your email"),
                            validator: (v) {
                              final t = (v ?? "").trim();
                              if (t.isEmpty) return "Vui lòng nhập email";
                              if (!t.contains("@")) return "Email không hợp lệ";
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          "Password",
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        _softField(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: password,
                                  obscureText: obscure,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.newPassword],
                                  decoration: _decoration("Enter your password"),
                                  validator: (v) {
                                    final t = (v ?? "").trim();
                                    if (t.isEmpty) return "Vui lòng nhập mật khẩu";
                                    if (t.length < 6) return "Tối thiểu 6 ký tự";
                                    return null;
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => obscure = !obscure),
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                                splashRadius: 18,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          "Confirm Password",
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        _softField(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: confirmPass,
                                  obscureText: obscureConfirm,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => register(),
                                  autofillHints: const [AutofillHints.newPassword],
                                  decoration: _decoration("Confirm your password"),
                                  validator: (v) {
                                    final t = (v ?? "").trim();
                                    if (t.isEmpty) return "Vui lòng nhập lại mật khẩu";
                                    if (t != password.text.trim()) return "Mật khẩu không khớp";
                                    return null;
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    setState(() => obscureConfirm = !obscureConfirm),
                                icon: Icon(
                                  obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                                splashRadius: 18,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: loading ? null : register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F64D6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: loading
                                ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              "Create An Account",
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: const Text(
                              "Already have an account? Sign In",
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF2F64D6),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Center(
                          child: Text(
                            "By signing up you agree to our Terms\nand Conditions of Use",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.black.withValues(alpha: 0.45),
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
