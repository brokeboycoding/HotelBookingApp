import 'package:booking_app/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _hoTenCtrl;
  late final TextEditingController _soDienThoaiCtrl;

  @override
  void initState() {
    super.initState();

    final user = context.read<AuthProvider>().currentUser;
    _hoTenCtrl = TextEditingController(text: (user?.name ?? '').trim());
    _soDienThoaiCtrl = TextEditingController(text: (user?.phone ?? '').trim());
  }

  @override
  void dispose() {
    _hoTenCtrl.dispose();
    _soDienThoaiCtrl.dispose();
    super.dispose();
  }

  void _thongBao(String noiDung, {bool laLoi = false}) {
    final cs = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          noiDung,
          style: TextStyle(
            color: laLoi ? cs.onErrorContainer : cs.onTertiaryContainer,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: laLoi ? cs.errorContainer : cs.tertiaryContainer,
      ),
    );
  }

  Future<void> _luuThongTin() async {
    FocusScope.of(context).unfocus(); // ✅ ẩn bàn phím
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.updateProfile(
        name: _hoTenCtrl.text.trim(),
        phone: _soDienThoaiCtrl.text.trim(),
      );

      if (!mounted) return;

      _thongBao('Đã cập nhật hồ sơ thành công!');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;

      _thongBao(
        authProvider.errorMessage ??
            'Không thể cập nhật hồ sơ. Vui lòng thử lại.',
        laLoi: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: cs.surface,
                elevation: isDark ? 0 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: cs.outlineVariant
                        .withValues(alpha: isDark ? 0.25 : 0.6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _hoTenCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên',
                          hintText: 'Nhập họ và tên của bạn',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập họ và tên';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _soDienThoaiCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _luuThongTin(),
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại (không bắt buộc)',
                          hintText: 'Ví dụ: 0901234567',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return FilledButton.icon(
                    onPressed: authProvider.isLoading ? null : _luuThongTin,
                    icon: authProvider.isLoading
                        ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      authProvider.isLoading ? 'Đang lưu…' : 'Lưu thay đổi',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
