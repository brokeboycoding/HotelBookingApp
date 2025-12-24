import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/hotel_providers.dart';
import '../../models/room_model.dart';

class AdminRoomDetailScreen extends StatelessWidget {
  final String hotelId;
  final String? hotelName;
  final RoomModel room;

  const AdminRoomDetailScreen({
    super.key,
    required this.hotelId,
    this.hotelName,
    required this.room,
  });

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

  Color _statusColor(String statusText) {
    final s = statusText.toLowerCase();
    if (s.contains('đã')) return Colors.orange;
    if (s.contains('từ')) return Colors.red;
    if (s.contains('bảo')) return Colors.blueGrey;
    if (s.contains('chờ')) return Colors.amber;
    return Colors.green;
  }

  String _money(num vnd) => NumberFormat.decimalPattern('vi').format(vnd);

  Future<void> _hoiXacNhanXoa(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc muốn xóa phòng này không?\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final provider = context.read<HotelProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await provider.deleteRoom(room.roomId);
      if (!context.mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Đã xóa phòng thành công.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.tertiaryContainer,
        ),
      );

      Navigator.pop(context); // quay lại danh sách
    } catch (_) {
      if (!context.mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Không thể xóa phòng.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.errorContainer,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final images = (room.images).map((e) => e.toString()).toList();
    final statusText = _statusLabel(room.status);
    final statusColor = _statusColor(statusText);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          hotelName?.trim().isNotEmpty == true
              ? 'Chi tiết phòng - $hotelName'
              : 'Chi tiết phòng',
        ),
        actions: [
          IconButton(
            tooltip: 'Sửa phòng',
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/edit-room',
                arguments: {
                  'hotelId': hotelId,
                  'hotelName': hotelName,
                  'room': room,
                },
              );
            },
          ),
          IconButton(
            tooltip: 'Xóa phòng',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _hoiXacNhanXoa(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Ảnh =====
          if (images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (_, i) => Image.network(
                    images[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: cs.onSurfaceVariant,
                        size: 44,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.image_not_supported_outlined,
                color: cs.onSurfaceVariant,
                size: 44,
              ),
            ),

          const SizedBox(height: 16),

          // ===== Tên phòng + trạng thái =====
          Row(
            children: [
              Expanded(
                child: Text(
                  'Phòng ${room.roomNumber} • ${room.type}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: isDark ? 0.45 : 0.35),
                  ),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            '${_money(room.price)} VNĐ/đêm • Khách: ${room.maxGuests}',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),
          Divider(color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6)),
          const SizedBox(height: 10),

          // ===== Mô tả đầy đủ =====
          Text(
            'Mô tả',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            room.description.trim().isEmpty ? 'Chưa có mô tả.' : room.description,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),
          Divider(color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6)),
          const SizedBox(height: 10),

          // ===== Thông tin =====
          _infoRow(context, 'Mã phòng', room.roomId),
          _infoRow(context, 'HotelId', hotelId),
          _infoRow(context, 'Loại phòng', room.type),
          _infoRow(context, 'Số khách tối đa', '${room.maxGuests}'),
          _infoRow(context, 'Giá / đêm', '${_money(room.price)} VNĐ'),
          _infoRow(context, 'Trạng thái', statusText),

          const SizedBox(height: 24),

          // ===== Nút hành động =====
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Sửa'),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/edit-room',
                      arguments: {
                        'hotelId': hotelId,
                        'hotelName': hotelName,
                        'room': room,
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Xóa'),
                  style: FilledButton.styleFrom(backgroundColor: cs.error),
                  onPressed: () => _hoiXacNhanXoa(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    );
  }
}
