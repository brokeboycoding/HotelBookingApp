import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:booking_app/screens/room_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _tuKhoaCtrl = TextEditingController();

  DateTime? _ngayNhanPhong;
  DateTime? _ngayTraPhong;

  List<RoomModel> _ketQua = <RoomModel>[];
  bool _dangTai = false;

  @override
  void dispose() {
    _tuKhoaCtrl.dispose();
    super.dispose();
  }

  Future<void> _chonNgay(BuildContext context, {required bool laNhanPhong}) async {
    final theme = Theme.of(context);

    final initial = laNhanPhong
        ? (_ngayNhanPhong ?? DateTime.now())
        : (_ngayTraPhong ??
        (_ngayNhanPhong?.add(const Duration(days: 1)) ?? DateTime.now()));

    final first = laNhanPhong
        ? DateTime.now()
        : (_ngayNhanPhong?.add(const Duration(days: 1)) ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.secondary,
              onPrimary: theme.colorScheme.onSecondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (laNhanPhong) {
        _ngayNhanPhong = picked;
        // Nếu ngày trả <= ngày nhận thì reset ngày trả
        if (_ngayTraPhong != null && !_ngayTraPhong!.isAfter(_ngayNhanPhong!)) {
          _ngayTraPhong = null;
        }
      } else {
        _ngayTraPhong = picked;
      }
    });
  }

  bool _chuaDuNgay() => _ngayNhanPhong == null || _ngayTraPhong == null;

  bool _coChua(String text, String keyword) {
    final t = text.toLowerCase();
    final k = keyword.toLowerCase();
    return t.contains(k);
  }

  List<RoomModel> _locTheoTuKhoa(List<RoomModel> ds, String keyword) {
    final k = keyword.trim();
    if (k.isEmpty) return ds;

    return ds.where((r) {
      final type = r.type.toString();
      final desc = r.description.toString();
      final hotelId = r.hotelId.toString();
      final roomNumber = r.roomNumber.toString();

      final amenities = (r.amenities).join(' ');
      return _coChua(type, k) ||
          _coChua(desc, k) ||
          _coChua(hotelId, k) ||
          _coChua(roomNumber, k) ||
          _coChua(amenities, k);
    }).toList();
  }

  Future<void> _timKiem() async {
    final cs = Theme.of(context).colorScheme;

    if (_chuaDuNgay()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn đủ ngày nhận phòng và ngày trả phòng.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.errorContainer,
        ),
      );
      return;
    }

    setState(() => _dangTai = true);

    final hotelProvider = context.read<HotelProvider>();
    final tuKhoa = _tuKhoaCtrl.text.trim(); // ✅ giờ đã dùng

    try {
      final results = await hotelProvider.searchRooms(
        checkIn: _ngayNhanPhong!,
        checkOut: _ngayTraPhong!,
      );

      // ✅ Lọc theo từ khóa (client-side) để khỏi báo "keyword isn't used"
      final loc = _locTheoTuKhoa(results, tuKhoa);

      if (!mounted) return;
      setState(() => _ketQua = loc);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tìm kiếm: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tìm phòng')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _tuKhoaCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _timKiem(),
                  decoration: InputDecoration(
                    hintText: 'Nhập từ khóa (VIP, view biển, 2 giường...)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _tuKhoaCtrl.text.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Xóa từ khóa',
                      onPressed: () {
                        _tuKhoaCtrl.clear();
                        setState(() {});
                      },
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _chipNgay(
                        context: context,
                        nhan: 'Nhận phòng',
                        ngay: _ngayNhanPhong,
                        onTap: () => _chonNgay(context, laNhanPhong: true),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.arrow_forward, color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                    Expanded(
                      child: _chipNgay(
                        context: context,
                        nhan: 'Trả phòng',
                        ngay: _ngayTraPhong,
                        onTap: () => _chonNgay(context, laNhanPhong: false),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (!_chuaDuNgay() && !_dangTai) ? _timKiem : null,
                    child: const Text('Tìm kiếm'),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: _dangTai
                ? const Center(child: CircularProgressIndicator())
                : (_ketQua.isNotEmpty)
                ? ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _ketQua.length,
              itemBuilder: (context, index) {
                final room = _ketQua[index];
                return RoomListItem(room: room);
              },
            )
                : Center(
              child: Text(
                'Chưa có phòng phù hợp trong khoảng ngày này.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipNgay({
    required BuildContext context,
    required String nhan,
    required DateTime? ngay,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nhan,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.65),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ngay == null ? 'Chọn ngày' : DateFormat('dd/MM').format(ngay),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomListItem extends StatelessWidget {
  const RoomListItem({super.key, required this.room});

  final RoomModel room;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final imageUrl = room.images.isNotEmpty ? room.images.first : '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          RoomDetailsScreen.routeName,
          arguments: room,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: imageUrl.isEmpty
                    ? Container(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                  child: Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        color: cs.onSurfaceVariant),
                  ),
                )
                    : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                    child: Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ),

            // Thông tin
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.type,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mã khách sạn: ${room.hotelId}',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.65),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: cs.secondary, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '4,8',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${room.price.toStringAsFixed(0)} VNĐ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: cs.secondary,
                              ),
                            ),
                            TextSpan(
                              text: ' / đêm',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
