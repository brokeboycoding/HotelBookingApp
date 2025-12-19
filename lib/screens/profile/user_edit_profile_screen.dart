import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserEditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentAvatarUrl;

  const UserEditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentEmail,
    this.currentAvatarUrl = '',
  });

  @override
  State<UserEditProfileScreen> createState() => _UserEditProfileScreenState();
}

class _UserEditProfileScreenState extends State<UserEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  bool saving = false;

  Uint8List? _pickedAvatarBytes;

  // ✅ Upload progress
  double _uploadProgress = 0.0;
  StreamSubscription<TaskSnapshot>? _uploadSub;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _uploadSub?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65, // ✅ giảm thêm để upload nhanh hơn
      maxWidth: 1024,
      maxHeight: 1024,  // ✅ thêm maxHeight
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() => _pickedAvatarBytes = bytes);
  }

  Future<String> _uploadAvatarToStorage(String uid) async {
    if (_pickedAvatarBytes == null) throw Exception("Chưa chọn ảnh avatar");

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('avatars')
        .child(uid)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    _uploadSub?.cancel();
    setState(() => _uploadProgress = 0);

    final task = storageRef.putData(
      _pickedAvatarBytes!,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    _uploadSub = task.snapshotEvents.listen((snap) {
      final total = snap.totalBytes;
      if (!mounted) return;
      if (total > 0) {
        setState(() => _uploadProgress = snap.bytesTransferred / total);
      }
    });

    await task;
    await _uploadSub?.cancel();
    _uploadSub = null;

    return await storageRef.getDownloadURL();
  }

  ImageProvider? _buildAvatarImage() {
    if (_pickedAvatarBytes != null) return MemoryImage(_pickedAvatarBytes!);
    if (widget.currentAvatarUrl.trim().isNotEmpty) {
      return NetworkImage(widget.currentAvatarUrl.trim());
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy tài khoản đăng nhập')),
      );
      return;
    }

    setState(() => saving = true);

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    try {
      // ✅ Bắt đầu upload trước (nếu có ảnh), để chạy song song các bước khác
      final uploadFuture = (_pickedAvatarBytes != null)
          ? _uploadAvatarToStorage(user.uid)
          : Future<String>.value(widget.currentAvatarUrl.trim());

      // ✅ Update displayName có thể làm ngay (không cần chờ upload)
      final updateNameFuture = user.updateDisplayName(newName);

      // ✅ Email verify cũng chạy song song
      bool requestedEmailChange = false;
      String? pendingEmail;
      Future<void> emailFuture = Future.value();

      if (newEmail.isNotEmpty && newEmail != user.email) {
        emailFuture = user.verifyBeforeUpdateEmail(newEmail).then((_) {
          requestedEmailChange = true;
          pendingEmail = newEmail;
        }).catchError((e) {
          // đừng throw để không làm hỏng cả flow lưu profile
          if (!mounted) return;
          final msg = (e is FirebaseAuthException)
              ? (e.code == 'requires-recent-login'
              ? 'Để đổi email, vui lòng đăng xuất và đăng nhập lại rồi thử lại.'
              : 'Không gửi được email xác nhận: ${e.message ?? e.code}')
              : 'Không gửi được email xác nhận: $e';

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        });
      }

      // ✅ Chờ các việc song song
      await Future.wait([updateNameFuture, emailFuture]);

      // ✅ Chờ upload xong để có URL (bước này thường lâu nhất)
      final avatarUrl = await uploadFuture;

      // ✅ Update photoURL sau khi có avatarUrl
      try {
        if (avatarUrl.isNotEmpty) {
          await user.updatePhotoURL(avatarUrl);
        }
      } catch (_) {}

      // ✅ Update Firestore
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await docRef.set(
        {
          'name': newName,
          'avatarUrl': avatarUrl,
          'email': user.email ?? widget.currentEmail,
          if (pendingEmail != null) 'pendingEmail': pendingEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            requestedEmailChange
                ? 'Đã lưu hồ sơ. Vui lòng kiểm tra email để xác nhận đổi email đăng nhập.'
                : 'Cập nhật hồ sơ thành công',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu hồ sơ: $e')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = _buildAvatarImage();
    final showProgress = saving && _pickedAvatarBytes != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? const Icon(Icons.person, size: 46)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: saving ? null : _pickAvatar,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Chọn ảnh avatar'),
                    ),

                    if (showProgress) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: _uploadProgress),
                      const SizedBox(height: 6),
                      Text(
                        'Đang tải ảnh: ${(100 * _uploadProgress).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Vui lòng nhập tên hiển thị' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (đổi sẽ cần xác nhận qua mail)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email';
                  if (!value.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : _saveProfile,
                  child: saving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Lưu thay đổi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
