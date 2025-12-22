import 'package:booking_app/providers/booking_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MonitorBookingsScreen extends StatefulWidget {
  const MonitorBookingsScreen({Key? key}) : super(key: key);

  @override
  _MonitorBookingsScreenState createState() => _MonitorBookingsScreenState();
}

class _MonitorBookingsScreenState extends State<MonitorBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).loadAllBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi đặt phòng'),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading && bookingProvider.bookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bookingProvider.bookings.isEmpty) {
            return const Center(
              child: Text('Chưa có đơn đặt phòng nào.'),
            );
          }

          final bookings = bookingProvider.bookings;

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (ctx, i) {
              final booking = bookings[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                child: ListTile(
                  title: Text('Booking ID: ${booking.bookingId}'),
                  subtitle: Text(
                      'Room ${booking.roomId} - Hotel ${booking.hotelId}\nStatus: ${booking.bookingStatus.name}'),
                  isThreeLine: true,
                  trailing: Text(
                      DateFormat('dd/MM/yy').format(booking.checkInDate)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
