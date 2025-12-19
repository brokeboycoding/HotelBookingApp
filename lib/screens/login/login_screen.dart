import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'register_screen.dart';
import '../../main.dart'; // RoleWrapper

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  bool obscure = true;
  bool rememberMe = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> saveUserToFirestore(User user) async {
    final doc = FirebaseFirestore.instance.collection("users").doc(user.uid);
    final snap = await doc.get();

    if (!snap.exists) {
      await doc.set({
        "email": user.email,
        "name": user.displayName ?? "",
        "role": "customer",
        "avatarUrl": user.photoURL ?? "",
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } else {
      await doc.set({
        "email": user.email,
        "name": user.displayName ?? "",
        "avatarUrl": user.photoURL ?? "",
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> signInWithGoogle() async {
    if (loading) return;
    setState(() => loading = true);

    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope("email")
          ..setCustomParameters({"prompt": "select_account"});

        final userCredential =
        await FirebaseAuth.instance.signInWithPopup(provider);

        await saveUserToFirestore(userCredential.user!);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleWrapper()),
        );
        return;
      }

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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleWrapper()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi Google: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> login() async {
    if (loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      await saveUserToFirestore(userCredential.user!);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleWrapper()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String msg = e.message ?? e.code;
      if (e.code == 'user-not-found') msg = 'Email không tồn tại.';
      if (e.code == 'wrong-password') msg = 'Sai mật khẩu.';
      if (e.code == 'invalid-email') msg = 'Email không hợp lệ.';

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

  Future<void> forgotPassword() async {
    final mail = email.text.trim();

    if (mail.isEmpty || !mail.contains('@')) {
      final controller = TextEditingController(text: mail);
      final result = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Forgot Password"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: "Enter your email"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text("Next"),
            ),
          ],
        ),
      );

      if (result == null || result.isEmpty || !result.contains('@')) return;
      await _sendResetEmail(result);
      return;
    }

    await _sendResetEmail(mail);
  }

  Future<void> _sendResetEmail(String mail) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: mail);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã gửi email đặt lại mật khẩu.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

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
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          splashRadius: 22,
                        ),
                        const SizedBox(height: 6),

                        const Center(
                          child: Text(
                            "Let’s Sign you in",
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
                            "Welcome back, you’ve been missed!",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.black.withValues(alpha: 0.45),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        const Text(
                          "Email Address",
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),

                        _softField(
                          child: TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username, AutofillHints.email],
                            decoration: _decoration("Enter your email address"),
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return "Vui lòng nhập email";
                              if (!t.contains('@')) return "Email không hợp lệ";
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
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => login(),
                                  autofillHints: const [AutofillHints.password],
                                  decoration: _decoration("Enter your password"),
                                  validator: (v) {
                                    final t = (v ?? '').trim();
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

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            InkWell(
                              onTap: () => setState(() => rememberMe = !rememberMe),
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: rememberMe
                                              ? const Color(0xFF2F64D6)
                                              : Colors.black26,
                                          width: 1.3,
                                        ),
                                        color: rememberMe
                                            ? const Color(0xFF2F64D6)
                                            : Colors.transparent,
                                      ),
                                      child: rememberMe
                                          ? const Icon(Icons.check,
                                          size: 12, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Remember Me",
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.black.withValues(alpha: 0.55),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: forgotPassword,
                              child: const Text(
                                "Forgot Password",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: loading ? null : login,
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
                              "Sign In",
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don’t have an account? ",
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.black.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF2F64D6),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            const Expanded(
                                child: Divider(color: Colors.black12, height: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                "Or continue with",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withValues(alpha: 0.45),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Expanded(
                                child: Divider(color: Colors.black12, height: 1)),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ✅ CHỈ GOOGLE (đã bỏ Facebook)
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: loading ? null : signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
                              backgroundColor: const Color(0xFFF4F6FA),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  "https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg",
                                  width: 18,
                                  height: 18,
                                  errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.g_mobiledata, size: 24),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "Continue with Google",
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Center(
                          child: Text(
                            "By signing in you agree to our Terms\nand Conditions of Use",
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
