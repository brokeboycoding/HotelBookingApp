import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../profile/user_profile_screen.dart';

class OwnerRequestScreen extends StatefulWidget {
  const OwnerRequestScreen({super.key});

  @override
  State<OwnerRequestScreen> createState() => _OwnerRequestScreenState();
}

class _OwnerRequestScreenState extends State<OwnerRequestScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _hotelNameCtrl = TextEditingController();
  final TextEditingController _hotelAddressCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  bool _submitting = false;

  // ảnh mới chọn (chưa upload)
  final List<_PickedFile> _attachments = <_PickedFile>[];

  // request hiện tại (đã lưu firestore)
  Map<String, dynamic>? _currentRequest;

  @override
  void initState() {
    super.initState();
    _loadExistingRequest();
    _prefillFromUser();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _hotelNameCtrl.dispose();
    _hotelAddressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _trim(dynamic v) => (v ?? '').toString().trim();

  bool get _isPending => _trim(_currentRequest?['status']) == 'pending';

  Future<void> _prefillFromUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final displayName = _trim(user.displayName);
    if (displayName.isNotEmpty) _fullNameCtrl.text = displayName;

    // ưu tiên users/{uid}.name
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final name = _trim(doc.data()?['name']);
      if (name.isNotEmpty) _fullNameCtrl.text = name;
    } catch (_) {}
  }

  Future<void> _loadExistingRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('owner_requests').doc(user.uid).get();
      if (!mounted) return;

      if (!doc.exists) {
        setState(() => _currentRequest = null);
        return;
      }

      final data = doc.data();
      setState(() => _currentRequest = data);

      final fullName = _trim(data?['fullName']);
      final phone = _trim(data?['phone']);
      final hotelName = _trim(data?['hotelName']);
      final hotelAddress = _trim(data?['hotelAddress']);
      final note = _trim(data?['note']);

      if (fullName.isNotEmpty) _fullNameCtrl.text = fullName;
      if (phone.isNotEmpty) _phoneCtrl.text = phone;
      if (hotelName.isNotEmpty) _hotelNameCtrl.text = hotelName;
      if (hotelAddress.isNotEmpty) _hotelAddressCtrl.text = hotelAddress;
      if (note.isNotEmpty) _noteCtrl.text = note;
    } catch (_) {}
  }

  Future<void> _pickImages() async {
    if (_submitting || _isPending) return;

    final picker = ImagePicker();
    try {
      final files = await picker.pickMultiImage(imageQuality: 85);
      if (files.isEmpty) return;

      final add = <_PickedFile>[];
      for (final f in files) {
        final bytes = await f.readAsBytes();
        add.add(_PickedFile(name: f.name, bytes: bytes));
      }

      if (!mounted) return;
      setState(() => _attachments.addAll(add));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn ảnh: $e')),
      );
    }
  }

  void _removeAttachmentAt(int index) {
    if (_submitting || _isPending) return;
    setState(() => _attachments.removeAt(index));
  }

  String _contentTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập lại.')),
      );
      return;
    }

    if (_isPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đã có đơn đang chờ duyệt.')),
      );
      return;
    }

    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final oldUrls = (_currentRequest?['attachments'] is List)
        ? List<String>.from(_currentRequest!['attachments'])
        : <String>[];

    if (_attachments.isEmpty && oldUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đính kèm ít nhất 1 ảnh giấy tờ.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final reqRef = FirebaseFirestore.instance.collection('owner_requests').doc(user.uid);
      final existed = await reqRef.get();

      final urls = <String>[];

      if (_attachments.isNotEmpty) {
        for (final file in _attachments) {
          final safeName = file.name.isNotEmpty ? file.name : 'image.jpg';
          final path = 'owner_requests/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$safeName';
          final storageRef = FirebaseStorage.instance.ref().child(path);

          final snap = await storageRef.putData(
            file.bytes,
            SettableMetadata(contentType: _contentTypeFromName(safeName)),
          );
          urls.add(await snap.ref.getDownloadURL());
        }
      } else {
        urls.addAll(oldUrls);
      }

      final payload = <String, dynamic>{
        'userId': user.uid,
        'email': _trim(user.email),
        'fullName': _fullNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'hotelName': _hotelNameCtrl.text.trim(),
        'hotelAddress': _hotelAddressCtrl.text.trim(),
        'note': _noteCtrl.text.trim(),
        'attachments': urls,
        'status': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existed.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await reqRef.set(payload, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _attachments.clear());

      await _loadExistingRequest();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi đơn! Vui lòng chờ duyệt.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi đơn thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Color _statusColor(String status) {
    if (status == 'approved') return const Color(0xFF16A34A);
    if (status == 'rejected') return const Color(0xFFEF4444);
    return const Color(0xFFF59E0B);
  }

  String _statusText(String status) {
    if (status == 'approved') return 'Đã duyệt';
    if (status == 'rejected') return 'Từ chối';
    return 'Đang chờ duyệt';
  }

  Widget _statusBanner() {
    final status = _trim(_currentRequest?['status']);
    if (status.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.verified, color: _statusColor(status)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trạng thái đơn: ${_statusText(status)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPending
                      ? 'Đang chờ duyệt. Bạn tạm thời không thể gửi lại.'
                      : 'Nếu bị từ chối, bạn có thể chỉnh sửa và gửi lại.',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBox({required Widget child, double height = 52}) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _oldImages() {
    final oldUrls = (_currentRequest?['attachments'] is List)
        ? List<String>.from(_currentRequest!['attachments'])
        : <String>[];

    if (oldUrls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          'Ảnh đã gửi:',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black.withValues(alpha: 0.70),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(oldUrls.length, (i) {
            final url = oldUrls[i];
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                width: 86,
                height: 86,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 86,
                  height: 86,
                  color: Colors.black.withValues(alpha: 0.06),
                  child: const Center(child: Icon(Icons.image_not_supported)),
                ),


              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _newImages() {
    if (_attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          'Ảnh mới chọn:',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black.withValues(alpha: 0.70),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_attachments.length, (i) {
            final file = _attachments[i];
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    file.bytes,
                    width: 86,
                    height: 86,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: InkWell(
                    onTap: (_isPending || _submitting) ? null : () => _removeAttachmentAt(i),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 650;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Đăng ký Chủ khách sạn'),
        backgroundColor: const Color(0xFF3F7CFF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 0, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  _statusBanner(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Thông tin đăng ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 14),

                          const Text('Họ tên', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          _inputBox(
                            child: TextFormField(
                              controller: _fullNameCtrl,
                              enabled: !_isPending && !_submitting,
                              decoration: const InputDecoration(hintText: 'Nhập họ tên', border: InputBorder.none),
                              validator: (v) => _trim(v).isEmpty ? 'Vui lòng nhập họ tên' : null,
                            ),
                          ),

                          const SizedBox(height: 12),
                          const Text('Số điện thoại', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          _inputBox(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              enabled: !_isPending && !_submitting,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(hintText: 'Ví dụ: 09xxxxxxxx', border: InputBorder.none),
                              validator: (v) {
                                final t = _trim(v);
                                if (t.isEmpty) return 'Vui lòng nhập số điện thoại';
                                if (t.length < 9) return 'Số điện thoại không hợp lệ';
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 12),
                          const Text('Tên khách sạn', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          _inputBox(
                            child: TextFormField(
                              controller: _hotelNameCtrl,
                              enabled: !_isPending && !_submitting,
                              decoration: const InputDecoration(hintText: 'Ví dụ: Tiền Luxury Hotel', border: InputBorder.none),
                              validator: (v) => _trim(v).isEmpty ? 'Vui lòng nhập tên khách sạn' : null,
                            ),
                          ),

                          const SizedBox(height: 12),
                          const Text('Địa chỉ khách sạn', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          _inputBox(
                            child: TextFormField(
                              controller: _hotelAddressCtrl,
                              enabled: !_isPending && !_submitting,
                              decoration: const InputDecoration(
                                hintText: 'Số nhà, đường, quận/huyện, tỉnh/thành',
                                border: InputBorder.none,
                              ),
                              validator: (v) => _trim(v).isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                            ),
                          ),

                          const SizedBox(height: 12),
                          const Text('Ghi chú', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          _inputBox(
                            height: 120,
                            child: TextFormField(
                              controller: _noteCtrl,
                              enabled: !_isPending && !_submitting,
                              minLines: 3,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                hintText: 'Ví dụ: Tôi gửi kèm CCCD + giấy phép kinh doanh...',
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Text('Giấy tờ/Ảnh đính kèm', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: (_isPending || _submitting) ? null : _pickImages,
                                icon: const Icon(Icons.add_photo_alternate),
                                label: const Text('Thêm ảnh'),
                              ),
                            ],
                          ),

                          _oldImages(),
                          _newImages(),

                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: (_isPending || _submitting) ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.send),
                              label: Text(_submitting ? 'Đang gửi...' : 'Gửi đơn đăng ký', style: const TextStyle(fontWeight: FontWeight.w900)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3F7CFF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                          Text(
                            'Sau khi duyệt, tài khoản của bạn sẽ được nâng quyền thành Chủ khách sạn.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.45), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
                      icon: const Icon(Icons.person),
                      label: const Text('Xem hồ sơ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3F7CFF),
                        side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickedFile {
  final String name;
  final Uint8List bytes;
  _PickedFile({required this.name, required this.bytes});
}
