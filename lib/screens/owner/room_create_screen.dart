import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RoomCreateScreen extends StatefulWidget {
  const RoomCreateScreen({super.key});

  @override
  State<RoomCreateScreen> createState() => _RoomCreateScreenState();
}

class _RoomCreateScreenState extends State<RoomCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _roomNoCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _bedsCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amenitiesCtrl = TextEditingController();
  final _imageUrlsCtrl = TextEditingController(); // neu muon nhap URL thu cong

  String _type = "Standard";
  bool _isActive = true;
  bool _saving = false;

  final ImagePicker _picker = ImagePicker();

  // ✅ luu anh duoi dang bytes de chay duoc ca Web + Android
  final List<Uint8List> _pickedBytes = [];
  final List<String> _pickedNames = [];

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomNoCtrl.dispose();
    _priceCtrl.dispose();
    _capacityCtrl.dispose();
    _bedsCtrl.dispose();
    _areaCtrl.dispose();
    _descCtrl.dispose();
    _amenitiesCtrl.dispose();
    _imageUrlsCtrl.dispose();
    super.dispose();
  }

  double _parseDouble(String s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;
  int _parseInt(String s) => int.tryParse(s.trim()) ?? 0;

  List<String> _parseAmenities(String s) {
    return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  List<String> _parseManualImageUrls(String s) {
    return s.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> _pickFromGallery() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;

    for (final f in files) {
      final bytes = await f.readAsBytes();
      _pickedBytes.add(bytes);
      _pickedNames.add(f.name);
    }
    setState(() {});
  }

  Future<void> _takePhoto() async {
    final f = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (f == null) return;

    final bytes = await f.readAsBytes();
    setState(() {
      _pickedBytes.add(bytes);
      _pickedNames.add(f.name);
    });
  }

  void _removePickedAt(int index) {
    setState(() {
      _pickedBytes.removeAt(index);
      _pickedNames.removeAt(index);
    });
  }

  Future<List<String>> _uploadPickedImages({
    required String ownerId,
    required String roomId,
  }) async {
    if (_pickedBytes.isEmpty) return [];

    final List<String> urls = [];
    for (int i = 0; i < _pickedBytes.length; i++) {
      final name = _pickedNames[i];
      final ext = name.contains('.') ? name.split('.').last : 'jpg';
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_$i.$ext";

      final ref = FirebaseStorage.instance.ref().child("rooms/$ownerId/$roomId/$fileName");

      await ref.putData(
        _pickedBytes[i],
        SettableMetadata(contentType: "image/jpeg"),
      );

      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _save() async {
    final u = _user;
    if (u == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ban chua dang nhap.")),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final roomRef = FirebaseFirestore.instance.collection("rooms").doc();
      final roomId = roomRef.id;

      final uploadedUrls = await _uploadPickedImages(ownerId: u.uid, roomId: roomId);
      final manualUrls = _parseManualImageUrls(_imageUrlsCtrl.text);

      final now = FieldValue.serverTimestamp();

      final data = <String, dynamic>{
        "ownerId": u.uid,
        "name": _nameCtrl.text.trim(),
        "roomNo": _roomNoCtrl.text.trim(),
        "type": _type,
        "pricePerNight": _parseDouble(_priceCtrl.text),
        "capacity": _parseInt(_capacityCtrl.text),
        "beds": _parseInt(_bedsCtrl.text),
        "area": _parseDouble(_areaCtrl.text),
        "description": _descCtrl.text.trim(),
        "amenities": _parseAmenities(_amenitiesCtrl.text),
        "imageUrls": [...uploadedUrls, ...manualUrls],
        "isActive": _isActive,
        "createdAt": now,
        "updatedAt": now,
      };

      await roomRef.set(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tao phong thanh cong!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Loi tao phong: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;

    return Scaffold(
      appBar: AppBar(title: const Text("Tao phong")),
      body: u == null
          ? const Center(child: Text("Ban chua dang nhap"))
          : SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Ten phong *",
                  prefixIcon: Icon(Icons.meeting_room),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Nhap ten phong" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _roomNoCtrl,
                decoration: const InputDecoration(
                  labelText: "So phong (tuy chon)",
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                key: ValueKey(_type),
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: "Loai phong",
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Standard", child: Text("Tieu chuan")),
                  DropdownMenuItem(value: "Deluxe", child: Text("Cao cap")),
                  DropdownMenuItem(value: "Suite", child: Text("Hang sang")),
                  DropdownMenuItem(value: "Family", child: Text("Gia dinh")),
                ],
                onChanged: (v) => setState(() => _type = v ?? "Standard"),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Gia/ dem (VND) *",
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => _parseDouble(v ?? "") <= 0 ? "Gia phai > 0" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _capacityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Suc chua *",
                        prefixIcon: Icon(Icons.people_alt_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => _parseInt(v ?? "") <= 0 ? "Suc chua phai > 0" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _amenitiesCtrl,
                decoration: const InputDecoration(
                  labelText: "Tien ich (cach nhau boi dau phay)",
                  hintText: "wifi, tv, minibar, dieu hoa...",
                  prefixIcon: Icon(Icons.list_alt_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _takePhoto,
                      icon: const Icon(Icons.photo_camera),
                      label: const Text("Chup anh"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickFromGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text("Chon anh"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_pickedBytes.isNotEmpty) ...[
                Text("Da chon: ${_pickedBytes.length} anh"),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_pickedBytes.length, (index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _pickedBytes[index],
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: InkWell(
                            onTap: _saving ? null : () => _removePickedAt(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 12),
              ],

              TextFormField(
                controller: _imageUrlsCtrl,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: "Anh (URL) - moi dong 1 URL (tuy chon)",
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: "Mo ta",
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text("Kich hoat phong"),
                subtitle: const Text("Tat neu muon an phong tam thoi"),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.save),
                  label: Text(_saving ? "Dang luu..." : "Luu phong"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
