import 'package:booking_app/models/hotel_model.dart';
import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:booking_app/widgets/location_map.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoomDetailsScreen extends StatefulWidget {
  const RoomDetailsScreen({super.key}); // ✅ super parameter

  static const routeName = '/room-details';

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState(); // ✅ public type
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  HotelModel? _khachSan;
  RoomModel? _phong;

  bool _dangTai = true;
  bool _daTaiDuLieu = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ chặn gọi lại nhiều lần
    if (_daTaiDuLieu) return;
    _daTaiDuLieu = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is RoomModel) {
      _phong = args;
      _taiThongTinKhachSan(args.hotelId);
    } else {
      setState(() => _dangTai = false);
    }
  }

  Future<void> _taiThongTinKhachSan(String hotelId) async {
    final hotelProvider = context.read<HotelProvider>();
    try {
      final hotel = await hotelProvider.getHotelById(hotelId);
      if (!mounted) return;
      setState(() {
        _khachSan = hotel;
        _dangTai = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _dangTai = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final room = _phong;
    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết phòng')),
        body: Center(
          child: Text(
            'Không nhận được dữ liệu phòng.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
          ),
        ),
      );
    }

    final anh = room.images.isNotEmpty ? room.images.first.trim() : '';
    final coAnh = anh.isNotEmpty;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Ảnh nền (nửa màn hình)
          Hero(
            tag: 'room_image_${room.roomId}',
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.52,
              width: double.infinity,
              child: coAnh
                  ? Image.network(
                anh,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _anhLoi(cs),
              )
                  : _anhLoi(cs),
            ),
          ),

          // Nút quay lại
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _nutTron(
              cs: cs,
              icon: Icons.arrow_back,
              tooltip: 'Quay lại',
              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          // Nút báo cáo
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: _nutTron(
              cs: cs,
              icon: Icons.report,
              tooltip: 'Báo cáo',
              onTap: () {
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

          // Sheet kéo lên
          DraggableScrollableSheet(
            initialChildSize: 0.62,
            minChildSize: 0.62,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // thanh kéo
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),

                      if (_dangTai)
                        const Center(child: CircularProgressIndicator())
                      else if (_khachSan == null)
                        Center(
                          child: Text(
                            'Không tìm thấy thông tin khách sạn.',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        )
                      else
                        _noiDungChiTiet(theme, cs, room, _khachSan!),
                    ],
                  ),
                ),
              );
            },
          ),

          // Nút đặt phòng (dưới)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.92),
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/booking', arguments: room);
                    },
                    child: const Text(
                      'Đặt phòng ngay',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noiDungChiTiet(
      ThemeData theme,
      ColorScheme cs,
      RoomModel room,
      HotelModel hotel,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tên phòng + giá
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                room.type,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${room.price.toStringAsFixed(0)} VNĐ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: cs.secondary,
                    ),
                  ),
                  TextSpan(
                    text: ' / đêm',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Icon(Icons.location_on, color: cs.onSurface.withValues(alpha: 0.55), size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hotel.name,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Mô tả
        Text(
          'Mô tả',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          room.description.trim().isEmpty ? 'Chưa có mô tả.' : room.description,
          style: TextStyle(
            fontSize: 15.5,
            height: 1.5,
            color: cs.onSurface.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 22),

        // Tiện nghi
        Text(
          'Tiện nghi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        if (room.amenities.isEmpty)
          Text(
            'Chưa cập nhật tiện nghi.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: room.amenities
                .map(
                  (t) => Chip(
                label: Text(t),
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.55),
                ),
                backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
              ),
            )
                .toList(),
          ),

        const SizedBox(height: 22),

        // Bản đồ
        Text(
          'Vị trí',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        LocationMap(location: hotel.location, hotelName: hotel.name),
      ],
    );
  }

  Widget _nutTron({
    required ColorScheme cs,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cs.surface.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: cs.onSurface),
        ),
      ),
    );
  }

  Widget _anhLoi(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: cs.onSurfaceVariant,
        size: 36,
      ),
    );
  }
}
