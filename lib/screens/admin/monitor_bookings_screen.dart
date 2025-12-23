import 'package:booking_app/providers/booking_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MonitorBookingsScreen extends StatefulWidget {
  const MonitorBookingsScreen({super.key});

  @override
  State<MonitorBookingsScreen> createState() => _MonitorBookingsScreenState();
}

class _MonitorBookingsScreenState extends State<MonitorBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadAllBookings();
    });
  }

  // ✅ Map trạng thái sang tiếng Việt (bạn chỉnh lại đúng enum bạn đang dùng)
  String _statusVi(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'checkedin':
      case 'checkin':
        return 'Đã nhận phòng';
      case 'checkedout':
      case 'checkout':
        return 'Đã trả phòng';
      case 'cancelled':
      case 'canceled':
        return 'Đã hủy';
      case 'completed':
        return 'Hoàn tất';
      case 'rejected':
        return 'Bị từ chối';
      default:
        return statusName; // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            return Center(
              child: Text(
                'Chưa có đơn đặt phòng nào.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
              ),
            );
          }

          final bookings = bookingProvider.bookings;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: bookings.length,
            itemBuilder: (ctx, i) {
              final booking = bookings[i];

              final ngayNhanPhong = DateFormat('dd/MM/yyyy').format(booking.checkInDate);
              final trangThai = _statusVi(booking.bookingStatus.name);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                elevation: isDark ? 0 : 2,
                color: cs.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
                  ),
                ),
                child: ListTile(
                  title: Text(
                    'Mã đặt phòng: ${booking.bookingId}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Mã phòng: ${booking.roomId} - Mã khách sạn: ${booking.hotelId}\n'
                        'Trạng thái: $trangThai',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    ngayNhanPhong,
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
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
