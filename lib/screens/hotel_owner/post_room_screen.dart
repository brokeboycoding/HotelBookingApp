import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class PostRoomScreen extends StatefulWidget {
  final RoomModel? room;

  const PostRoomScreen({Key? key, this.room}) : super(key: key);

  @override
  _PostRoomScreenState createState() => _PostRoomScreenState();
}

class _PostRoomScreenState extends State<PostRoomScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _roomNumberController;
  late TextEditingController _typeController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _maxGuestsController;
  final _amenitiesController = TextEditingController();
  final _imagesController = TextEditingController(); // For URL input

  late List<String> _amenities;
  late List<String> _imageUrls;

  bool get _isEditMode => widget.room != null;

  @override
  void initState() {
    super.initState();
    _roomNumberController =
        TextEditingController(text: widget.room?.roomNumber ?? '');
    _typeController = TextEditingController(text: widget.room?.type ?? '');
    _priceController =
        TextEditingController(text: widget.room?.price.toStringAsFixed(0) ?? '');
    _descriptionController =
        TextEditingController(text: widget.room?.description ?? '');
    _maxGuestsController =
        TextEditingController(text: widget.room?.maxGuests.toString() ?? '');
    _amenities = List<String>.from(widget.room?.amenities ?? []);
    _imageUrls = List<String>.from(widget.room?.images ?? []);
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _typeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _maxGuestsController.dispose();
    _amenitiesController.dispose();
    _imagesController.dispose();
    super.dispose();
  }

  void _addAmenity() {
    if (_amenitiesController.text.isNotEmpty) {
      setState(() {
        _amenities.add(_amenitiesController.text.trim());
        _amenitiesController.clear();
      });
    }
  }

  void _addImageUrl() {
    if (_imagesController.text.isNotEmpty) {
      setState(() {
        _imageUrls.add(_imagesController.text.trim());
        _imagesController.clear();
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final hotelProvider = Provider.of<HotelProvider>(context, listen: false);

      try {
        if (_isEditMode) {
          await hotelProvider.updateRoom(
            roomId: widget.room!.roomId,
            roomNumber: _roomNumberController.text,
            type: _typeController.text,
            price: double.parse(_priceController.text),
            description: _descriptionController.text,
            maxGuests: int.parse(_maxGuestsController.text),
            amenities: _amenities,
            imageUrls: _imageUrls,
          );
        } else {
          await hotelProvider.createRoom(
            hotelId: 'h1', // Hardcoded for now
            roomNumber: _roomNumberController.text,
            type: _typeController.text,
            price: double.parse(_priceController.text),
            description: _descriptionController.text,
            maxGuests: int.parse(_maxGuestsController.text),
            amenities: _amenities,
            imageUrls: _imageUrls,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lưu thông tin phòng thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(hotelProvider.errorMessage ?? 'Đã có lỗi xảy ra.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Chỉnh sửa phòng' : 'Đăng phòng mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _roomNumberController,
                decoration: const InputDecoration(labelText: 'Số phòng'),
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập số phòng' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Loại phòng'),
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập loại phòng' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Giá mỗi đêm'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập giá phòng' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập mô tả' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxGuestsController,
                decoration: const InputDecoration(labelText: 'Số khách tối đa'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập số khách' : null,
              ),
              const SizedBox(height: 24),
              _buildListManager(
                title: 'Tiện nghi',
                controller: _amenitiesController,
                items: _amenities,
                onAdd: _addAmenity,
              ),
              const SizedBox(height: 24),
              _buildListManager(
                title: 'Hình ảnh (URL)',
                controller: _imagesController,
                items: _imageUrls,
                onAdd: _addImageUrl,
              ),
              const SizedBox(height: 32),
              Center(
                child: Consumer<HotelProvider>(
                  builder: (context, hotelProvider, _) => ElevatedButton(
                    onPressed: hotelProvider.isLoading ? null : _submitForm,
                    child: hotelProvider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Lưu thông tin'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListManager({
    required String title,
    required TextEditingController controller,
    required List<String> items,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: items
              .map((item) => Chip(
                    label: Text(item),
                    onDeleted: () {
                      setState(() {
                        items.remove(item);
                      });
                    },
                  ))
              .toList(),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(hintText: 'Thêm $title...'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: onAdd,
            ),
          ],
        ),
      ],
    );
  }
}
