import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/hotel_providers.dart';
import '../../models/room_model.dart';

class ManageRoomsScreen extends StatefulWidget {
  final String hotelId;
  final String? hotelName;

  const ManageRoomsScreen({
    super.key,
    required this.hotelId,
    this.hotelName,
  });

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  String _statusLabel(dynamic status) {
    final s = (status is Enum)
        ? status.name.toLowerCase()
        : (status ?? '').toString().toLowerCase();

    switch (s) {
      case 'pending':
        return 'Chờ duyệt';
      case 'available':
        return 'Còn phòng';
      case 'booked':
        return 'Đã đặt';
      case 'maintenance':
        return 'Bảo trì';
      case 'rejected':
        return 'Từ chối';
      default:
        return s.isEmpty ? '—' : s;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HotelProvider>().loadHotelRooms(widget.hotelId);
    });
  }

  Future<void> _reload() async {
    await context.read<HotelProvider>().loadHotelRooms(widget.hotelId);
  }

  Future<void> _xoaPhong(String maPhong) async {
    final hotelProvider = context.read<HotelProvider>();

    final messenger = ScaffoldMessenger.of(context);
    final cs = Theme.of(context).colorScheme;

    try {
      await hotelProvider.deleteRoom(maPhong);
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Đã xóa phòng thành công.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.tertiaryContainer,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(hotelProvider.errorMessage ?? 'Không thể xóa phòng.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.errorContainer,
        ),
      );
    }
  }

  void _hoiXacNhanXoa(String maPhong) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc muốn xóa phòng này không?\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _xoaPhong(maPhong);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.hotelName?.trim().isNotEmpty == true
              ? 'Quản lý phòng - ${widget.hotelName}'
              : 'Quản lý phòng',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Đăng phòng mới',
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/post-room',
                arguments: {
                  'hotelId': widget.hotelId,
                  'hotelName': widget.hotelName,
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<HotelProvider>(
        builder: (context, hotelProvider, _) {
          if (hotelProvider.isLoading && hotelProvider.rooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hotelProvider.rooms.isEmpty) {
            return Center(
              child: Text(
                'Bạn chưa đăng phòng nào.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: hotelProvider.rooms.length,
              itemBuilder: (context, i) {
                final RoomModel phong = hotelProvider.rooms[i];

                final String imageUrl =
                phong.images.isNotEmpty ? phong.images.first.toString() : '';

                final String statusText = _statusLabel(phong.status);

                return Card(
                  color: cs.surface,
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: isDark ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(
                        alpha: isDark ? 0.25 : 0.6,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          // ✅ NEW: bấm vào card để xem chi tiết
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/room-detail',
                              arguments: {
                                'hotelId': widget.hotelId,
                                'hotelName': widget.hotelName,
                                'room': phong,
                              },
                            );
                          },
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 54,
                              height: 54,
                              color: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.55),
                              child: imageUrl.isEmpty
                                  ? Icon(
                                Icons.image_not_supported_outlined,
                                color: cs.onSurfaceVariant,
                              )
                                  : Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) {
                                  return Icon(
                                    Icons.broken_image_outlined,
                                    color: cs.onSurfaceVariant,
                                  );
                                },
                              ),
                            ),
                          ),
                          title: Text(
                            'Phòng ${phong.roomNumber} • ${phong.type}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            '${phong.price.toStringAsFixed(0)} VNĐ/đêm • Khách: ${phong.maxGuests}\n'
                                'Trạng thái: $statusText',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.72),
                              height: 1.25,
                            ),
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            phong.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Sửa'),
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  '/edit-room',
                                  arguments: {
                                    'hotelId': widget.hotelId,
                                    'hotelName': widget.hotelName,
                                    'room': phong,
                                  },
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Xóa'),
                              style: TextButton.styleFrom(
                                foregroundColor: cs.error,
                              ),
                              onPressed: () => _hoiXacNhanXoa(phong.roomId),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
