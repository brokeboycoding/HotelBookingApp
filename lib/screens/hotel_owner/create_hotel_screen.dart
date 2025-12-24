import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/hotel_providers.dart';
import '../../services/cloudinary_service.dart'; // ✅ THÊM

class CreateHotelScreen extends StatefulWidget {
  const CreateHotelScreen({super.key});

  @override
  State<CreateHotelScreen> createState() => _CreateHotelScreenState();
}

class _CreateHotelScreenState extends State<CreateHotelScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amenityCtrl = TextEditingController();

  // ✅ ĐỔI File -> CloudinaryBytesFile
  final List<CloudinaryBytesFile> _images = <CloudinaryBytesFile>[];
  final Set<String> _amenities = <String>{};

  static const List<String> _presetAmenities = <String>[
    'Wifi',
    'Bãi đỗ xe',
    'Bể bơi',
    'Bữa sáng',
    'Gym',
    'Lễ tân 24/7',
    'Điều hoà',
    'Thang máy',
    'Giặt ủi',
    'Dịch vụ phòng',
    'Cho phép thú cưng',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    _amenityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    // ✅ Convert XFile -> CloudinaryBytesFile (bytes)
    final converted = await Future.wait<CloudinaryBytesFile>(
      picked.map((x) async {
        final bytes = await x.readAsBytes();
        return CloudinaryBytesFile(
          bytes: bytes,
          fileName: x.name,     // ví dụ: IMG_001.jpg
          mimeType: null,       // optional (Cloudinary vẫn upload được)
        );
      }),
    );

    setState(() {
      _images.addAll(converted);
    });
  }

  void _removeImage(int index) => setState(() => _images.removeAt(index));

  void _toggleAmenity(String a) {
    setState(() {
      if (_amenities.contains(a)) {
        _amenities.remove(a);
      } else {
        _amenities.add(a);
      }
    });
  }

  void _addCustomAmenity() {
    final v = _amenityCtrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _amenities.add(v);
      _amenityCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa đăng nhập.')),
      );
      return;
    }

    final location = const GeoPoint(0, 0);

    final ok = await context.read<HotelProvider>().createHotel(
      ownerId: uid,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      location: location,
      amenities: _amenities.toList(),
      images: _images, // ✅ ĐÚNG KIỂU
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đã tạo khách sạn (chờ duyệt).')),
      );
      Navigator.pop(context);
    } else {
      final err = context.read<HotelProvider>().errorMessage ?? 'Tạo thất bại';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $err')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HotelProvider>();
    final loading = provider.isLoading;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm thông tin khách sạn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên khách sạn',
                  prefixIcon: Icon(Icons.apartment),
                ),
                validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Nhập tên khách sạn' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Nhập địa chỉ' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Ảnh
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ảnh khách sạn',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: loading ? null : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Chọn ảnh'),
                  ),
                ],
              ),

              if (_images.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_images.length, (i) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _images[i].bytes, // ✅ preview từ bytes
                            width: 110,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: InkWell(
                            onTap: loading ? null : () => _removeImage(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),

              const SizedBox(height: 16),

              // Tiện nghi
              Text('Tiện nghi', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetAmenities.map((a) {
                  final selected = _amenities.contains(a);
                  return FilterChip(
                    label: Text(a),
                    selected: selected,
                    onSelected: loading ? null : (_) => _toggleAmenity(a),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amenityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Thêm tiện nghi khác (tuỳ chọn)',
                      ),
                      onSubmitted: (_) => _addCustomAmenity(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: loading ? null : _addCustomAmenity,
                    child: const Text('Thêm'),
                  ),
                ],
              ),

              if (_amenities.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _amenities.map((a) {
                    return Chip(
                      label: Text(a),
                      onDeleted: loading ? null : () => _toggleAmenity(a),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : _submit,
                  icon: const Icon(Icons.save),
                  label: Text(loading ? 'Đang lưu...' : 'Tạo khách sạn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.secondary,
                    foregroundColor: cs.onSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
