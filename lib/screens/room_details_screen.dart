import 'package:booking_app/models/hotel_model.dart';
import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:booking_app/widgets/location_map.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoomDetailsScreen extends StatefulWidget {
  const RoomDetailsScreen({Key? key}) : super(key: key);

  static const routeName = '/room-details';

  @override
  _RoomDetailsScreenState createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  HotelModel? _hotel;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchHotelDetails();
  }

  Future<void> _fetchHotelDetails() async {
    final room = ModalRoute.of(context)!.settings.arguments as RoomModel;
    final hotelProvider = Provider.of<HotelProvider>(context, listen: false);

    try {
      final hotel = await hotelProvider.getHotelById(room.hotelId);
      if (mounted) {
        setState(() {
          _hotel = hotel;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Optionally show an error message
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final RoomModel room =
        ModalRoute.of(context)!.settings.arguments as RoomModel;
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Hero(
            tag: 'room_image_${room.roomId}',
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(room.images.isNotEmpty ? room.images.first : 'https://via.placeholder.com/150'),
                  fit: BoxFit.cover,
                  onError: (e, s) {},
                ),
              ),
            ),
          ),
          // Back Button
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          // Report Button
          Positioned(
            top: 40,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.report, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/add-report',
                    arguments: {
                      'hotelId': room.hotelId,
                      'roomId': room.roomId,
                    },
                  );
                },
              ),
            ),
          ),
          // Details Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24.0),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _hotel == null
                          ? const Center(child: Text('Hotel details not found.'))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title and Price
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        room.type,
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                '${room.price.toStringAsFixed(0)} VNĐ',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.secondary,
                                            ),
                                          ),
                                          const TextSpan(
                                            text: ' / night',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.grey, size: 16),
                                    const SizedBox(width: 4),
                                    Text(_hotel!.name, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Description
                                const Text(
                                  'Description',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  room.description,
                                  style: const TextStyle(
                                      fontSize: 16, height: 1.5, color: Colors.white70),
                                ),
                                const SizedBox(height: 24),
                                // Amenities
                                const Text(
                                  'Amenities',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12.0,
                                  runSpacing: 12.0,
                                  children: room.amenities
                                      .map((amenity) => Chip(
                                            label: Text(amenity),
                                            backgroundColor:
                                                theme.colorScheme.surface,
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 24),
                                // Map
                                const Text(
                                  'Location',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                LocationMap(location: _hotel!.location, hotelName: _hotel!.name),
                              ],
                            ),
                ),
              );
            },
          ),
          // Book Now Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: theme.scaffoldBackgroundColor.withOpacity(0.8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/booking', arguments: room);
                },
                child: const Text('Book Now'),
              ),
            ),
          )
        ],
      ),
    );
  }
}
