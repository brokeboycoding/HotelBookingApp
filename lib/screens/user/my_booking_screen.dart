import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/booking_model.dart';
import '../../providers/booking_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/theme_provider.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final uid = authProvider.currentUser?.uid;

      if (uid != null && uid.isNotEmpty) {
        context.read<BookingProvider>().loadUserBookings(uid);
      }
    });
  }

  void _moHopThoaiDangXuat() {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AuthProvider>().signOut(context);
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final themeProvider = context.watch<ThemeProvider>();
    final dangToi = themeProvider.isDark(context); // ✅ đúng theo provider mới

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn đặt phòng của tôi'),
        actions: [
          // ✅ nút đổi sáng/tối (theo ROLE hiện tại)
          IconButton(
            tooltip: dangToi ? 'Chuyển sang sáng' : 'Chuyển sang tối',
            icon: Icon(dangToi ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => context.read<ThemeProvider>().toggle(context), // ✅ cần context
          ),

          // ✅ nút đăng xuất
          IconButton(
            tooltip: 'Đăng xuất',
            icon: Icon(Icons.logout, color: cs.error),
            onPressed: _moHopThoaiDangXuat,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, _) {
          if (bookingProvider.isLoading && bookingProvider.bookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bookingProvider.bookings.isEmpty) {
            return Center(
              child: Text(
                'Bạn chưa có đơn đặt phòng nào.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookingProvider.bookings.length,
            itemBuilder: (context, index) {
              final booking = bookingProvider.bookings[index];
              return BookingListItem(booking: booking);
            },
          );
        },
      ),
    );
  }
}

class BookingListItem extends StatelessWidget {
  final BookingModel booking;

  const BookingListItem({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final dinhDangNgay = DateFormat('dd/MM/yyyy');
    final dinhDangTien = NumberFormat('#,###', 'vi_VN');

    final (mauTrangThai, tenTrangThai) = _trangThaiUi(context, booking.bookingStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cs.surface,
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: Container(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.hotel_outlined,
                        color: cs.onSurfaceVariant,
                        size: 34,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Khách sạn: ${booking.hotelId}',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phòng: ${booking.roomId}',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 16,
                            color: cs.onSurface.withValues(alpha: 0.65),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${dinhDangNgay.format(booking.checkInDate)}  →  ${dinhDangNgay.format(booking.checkOutDate)}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: cs.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.35)),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: mauTrangThai.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: mauTrangThai.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    tenTrangThai,
                    style: TextStyle(
                      color: mauTrangThai,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                Text(
                  '${dinhDangTien.format(booking.totalPrice)} VNĐ',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),

            if (booking.bookingStatus == BookingStatus.checkedOut) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/add-review',
                      arguments: {
                        'roomId': booking.roomId,
                        'hotelId': booking.hotelId,
                      },
                    );
                  },
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Viết đánh giá'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.secondary),
                    foregroundColor: cs.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, String) _trangThaiUi(BuildContext context, BookingStatus status) {
    final cs = Theme.of(context).colorScheme;

    switch (status) {
      case BookingStatus.pending:
        return (cs.tertiary, 'Chờ xác nhận');
      case BookingStatus.confirmed:
        return (cs.primary, 'Đã xác nhận');
      case BookingStatus.checkedIn:
        return (cs.secondary, 'Đã nhận phòng');
      case BookingStatus.checkedOut:
        return (cs.onSurfaceVariant, 'Hoàn tất');
      case BookingStatus.cancelled:
        return (cs.error, 'Đã hủy');
    }
  }
}
