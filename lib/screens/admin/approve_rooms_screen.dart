import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ApproveRoomsScreen extends StatefulWidget {
  const ApproveRoomsScreen({Key? key}) : super(key: key);

  @override
  _ApproveRoomsScreenState createState() => _ApproveRoomsScreenState();
}

class _ApproveRoomsScreenState extends State<ApproveRoomsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HotelProvider>(context, listen: false).loadPendingRooms();
    });
  }

  Future<void> _approveRoom(String roomId) async {
    final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
    try {
      await hotelProvider.updateRoomStatus(roomId, RoomStatus.available);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã duyệt phòng.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hotelProvider.errorMessage ?? 'Có lỗi xảy ra.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRoom(String roomId) async {
    final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
    try {
      await hotelProvider.updateRoomStatus(roomId, RoomStatus.rejected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã từ chối phòng.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hotelProvider.errorMessage ?? 'Có lỗi xảy ra.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt phòng chờ'),
      ),
      body: Consumer<HotelProvider>(
        builder: (context, hotelProvider, child) {
          if (hotelProvider.isLoading && hotelProvider.rooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hotelProvider.rooms.isEmpty) {
            return const Center(
              child: Text('Không có phòng nào chờ duyệt.'),
            );
          }

          final pendingRooms = hotelProvider.rooms;

          return ListView.builder(
            itemCount: pendingRooms.length,
            itemBuilder: (ctx, i) {
              final room = pendingRooms[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(room.roomNumber),
                  ),
                  title: Text(room.type),
                  subtitle: Text(
                      'Hotel ID: ${room.hotelId}\nGiá: ${room.price.toStringAsFixed(0)} VNĐ'),
                  isThreeLine: true,
                  trailing: SizedBox(
                    width: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _approveRoom(room.roomId),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _rejectRoom(room.roomId),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
