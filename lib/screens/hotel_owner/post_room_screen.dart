import 'package:flutter/material.dart';
import 'package:booking_app/models/room_model.dart';

class PostRoomScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isEdit = room != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Chỉnh sửa phòng' : 'Đăng phòng mới'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            isEdit
                ? 'Edit room: ${room!.roomNumber}\n(hotelId=$hotelId)'
                : 'Create room for hotelId=$hotelId',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
