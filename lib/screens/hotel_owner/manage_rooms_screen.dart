import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/room_model.dart';
import '../../providers/hotel_providers.dart';

class ManageRoomsScreen extends StatefulWidget {
  const ManageRoomsScreen({Key? key}) : super(key: key);

  @override
  _ManageRoomsScreenState createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Hardcoded hotelId for now
      Provider.of<HotelProvider>(context, listen: false).loadHotelRooms('h1');
    });
  }

  Future<void> _deleteRoom(String roomId) async {
    final hotelProvider = Provider.of<HotelProvider>(context, listen: false);
    try {
      await hotelProvider.deleteRoom(roomId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hotelProvider.errorMessage ?? 'Could not delete room.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(String roomId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this room? This action cannot be undone.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteRoom(roomId);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushNamed('/post-room');
            },
          ),
        ],
      ),
      body: Consumer<HotelProvider>(
        builder: (context, hotelProvider, child) {
          if (hotelProvider.isLoading && hotelProvider.rooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hotelProvider.rooms.isEmpty) {
            return const Center(
              child: Text('You have not posted any rooms yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hotelProvider.rooms.length,
            itemBuilder: (ctx, i) {
              final room = hotelProvider.rooms[i];
              return Card(
                color: Theme.of(context).colorScheme.surface,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                          child: Text(room.roomNumber, style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                        ),
                        title: Text(room.type, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${room.price.toStringAsFixed(0)} VNĐ / night'),
                      ),
                      const Divider(),
                       Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          room.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            onPressed: () {
                               Navigator.of(context).pushNamed('/edit-room', arguments: room);
                            },
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Delete'),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            onPressed: () => _showDeleteConfirmation(room.roomId),
                          ),
                        ],
                      ),
                    ],
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
