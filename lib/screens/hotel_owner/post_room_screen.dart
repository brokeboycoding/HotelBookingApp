import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/cloudinary_service.dart';

class PostRoomScreen extends StatefulWidget {
  final String hotelId;
  final String? hotelName;
  final RoomModel? room;

  const PostRoomScreen({
    super.key,
    required this.hotelId,
    this.hotelName,
    this.room,
  });

  @override
  State<PostRoomScreen> createState() => _PostRoomScreenState();
}

class _PostRoomScreenState extends State<PostRoomScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _roomNumberCtrl;
  late final TextEditingController _typeCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _maxGuestsCtrl;
  late final TextEditingController _descCtrl;

  final TextEditingController _amenityCtrl = TextEditingController();

  // ✅ bytes images
  final List<CloudinaryBytesFile> _newImages = <CloudinaryBytesFile>[];
  final List<String> _imageUrls = <String>[];
  final Set<String> _amenities = <String>{};

  bool _submitting = false;

  static const List<String> _presetAmenities = <String>[
    'Wifi',
    'Điều hòa',
    'TV',
    'Tủ lạnh',
    'Nước nóng',
    'Ban công',
    'Bồn tắm',
    'Máy sấy tóc',
    'Bàn làm việc',
  ];

  bool get _isEdit => widget.room != null;

  @override
  void initState() {
    super.initState();

    final r = widget.room;

    _roomNumberCtrl = TextEditingController(text: r?.roomNumber ?? '');
    _typeCtrl = TextEditingController(text: (r?.type ?? '').trim());
    _priceCtrl = TextEditingController(
      text: r == null ? '' : (r.price == 0 ? '' : r.price.toStringAsFixed(0)),
    );
    _maxGuestsCtrl = TextEditingController(
      text: r == null ? '1' : r.maxGuests.toString(),
    );
    _descCtrl = TextEditingController(text: r?.description ?? '');

    if (r != null) {
      _amenities.addAll(r.amenities);
      _imageUrls.addAll(r.images);
    }
  }

  @override
  void dispose() {
    _roomNumberCtrl.dispose();
    _typeCtrl.dispose();
    _priceCtrl.dispose();
    _maxGuestsCtrl.dispose();
    _descCtrl.dispose();
    _amenityCtrl.dispose();
    super.dispose();
  }

  String _basename(String path) {
    final p = path.replaceAll('\\', '/');
    final parts = p.split('/');
    return parts.isNotEmpty ? parts.last : 'image.jpg';
  }

  String? _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return null;
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    final files = <CloudinaryBytesFile>[];
    for (final x in picked) {
      final bytes = await x.readAsBytes();
      final name = _basename(x.path);
      files.add(
        CloudinaryBytesFile(
          bytes: bytes,
          fileName: name,
          mimeType: _guessMimeType(name),
        ),
      );
    }

    if (!mounted) return;
    setState(() => _newImages.addAll(files));
  }

  void _removeNewImage(int index) => setState(() => _newImages.removeAt(index));
  void _removeUrlImage(int index) => setState(() => _imageUrls.removeAt(index));

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

  double _parsePrice(String s) {
    final t = s.trim().replaceAll(',', '');
    return double.tryParse(t) ?? 0;
  }

  int _parseInt(String s, {int fallback = 1}) {
    return int.tryParse(s.trim()) ?? fallback;
  }

  // ✅ Upload ảnh mới bằng Cloudinary bytes
  Future<List<String>> _uploadNewImages() async {
    if (_newImages.isEmpty) return [];

    final cloudinary = CloudinaryService();
    final urls = await cloudinary.uploadManyBytes(
      _newImages,
      folder: 'hotel_rooms/rooms/${widget.hotelId}',
    );

    return urls;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final messenger = ScaffoldMessenger.of(context);
    final cs = Theme.of(context).colorScheme;

    try {
      final provider = context.read<HotelProvider>();

      // upload ảnh mới -> lấy url
      final uploadedUrls = await _uploadNewImages();
      final finalImageUrls = <String>[
        ..._imageUrls,     // ảnh cũ còn giữ
        ...uploadedUrls,   // ảnh mới upload
      ];

      final roomNumber = _roomNumberCtrl.text.trim();
      final type = _typeCtrl.text.trim();
      final price = _parsePrice(_priceCtrl.text);
      final maxGuests = _parseInt(_maxGuestsCtrl.text, fallback: 1);
      final desc = _descCtrl.text.trim();

      if (_isEdit) {
        final r = widget.room!;
        await provider.updateRoom(
          roomId: r.roomId,
          roomNumber: roomNumber,
          type: type,
          price: price,
          description: desc,
          maxGuests: maxGuests,
          amenities: _amenities.toList(),
          imageUrls: finalImageUrls,
        );
      } else {
        await provider.createRoom(
          hotelId: widget.hotelId,
          roomNumber: roomNumber,
          type: type,
          price: price,
          description: desc,
          maxGuests: maxGuests,
          amenities: _amenities.toList(),
          imageUrls: finalImageUrls,
        );
      }

      // ✅ clear ảnh local sau khi upload/lưu xong
      _newImages.clear();

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEdit ? '✅ Đã cập nhật phòng.' : '✅ Đã tạo phòng.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.tertiaryContainer,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Chỉnh sửa phòng' : 'Đăng phòng mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.hotelName?.trim().isNotEmpty == true
                    ? 'Khách sạn: ${widget.hotelName}'
                    : 'hotelId: ${widget.hotelId}',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _roomNumberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Số phòng / Mã phòng',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
                validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Nhập số phòng' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _typeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Loại phòng (Standard/Deluxe/Suite...)',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá / đêm (VND)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (v) {
                  final p = _parsePrice(v ?? '');
                  if (p <= 0) return 'Giá phải > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _maxGuestsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số khách tối đa',
                  prefixIcon: Icon(Icons.people_outline),
                ),
                validator: (v) {
                  final n = _parseInt(v ?? '', fallback: 0);
                  if (n <= 0) return 'Phải >= 1';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // ===== Images =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ảnh phòng',
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: _submitting ? null : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Chọn ảnh'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ảnh đã có (khi sửa)
              if (_imageUrls.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_imageUrls.length, (i) {
                    final url = _imageUrls[i];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            width: 110,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 110,
                              height: 80,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: InkWell(
                            onTap: _submitting ? null : () => _removeUrlImage(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),

              // ảnh mới chọn (bytes)
              if (_newImages.isNotEmpty) ...[
                if (_imageUrls.isNotEmpty) const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_newImages.length, (i) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _newImages[i].bytes,
                            width: 110,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: InkWell(
                            onTap: _submitting ? null : () => _removeNewImage(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],

              const SizedBox(height: 16),

              // ===== Amenities =====
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
                    onSelected: _submitting ? null : (_) => _toggleAmenity(a),
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
                    onPressed: _submitting ? null : _addCustomAmenity,
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
                      onDeleted: _submitting ? null : () => _toggleAmenity(a),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.save),
                  label: Text(_submitting
                      ? 'Đang lưu...'
                      : (_isEdit ? 'Cập nhật phòng' : 'Tạo phòng')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
