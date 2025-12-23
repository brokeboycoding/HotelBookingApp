import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/room_model.dart';
import '../../providers/booking_providers.dart';
import '../../providers/auth_providers.dart';

// ✅ Nếu bạn đã có provider đổi theme thì import nó ở đây
// Ví dụ: import '../../providers/giao_dien_providers.dart';

class BookingScreen extends StatefulWidget {
  final RoomModel room;

  const BookingScreen({
    super.key,
    required this.room,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // TODO: thay bằng tên khách sạn thật (lấy từ room/hotel collection)
  final String _tenKhachSan = 'Khách sạn';

  DateTime? _ngayNhanPhong;
  DateTime? _ngayTraPhong;

  final _ghiChuCtrl = TextEditingController();

  String _phuongThucThanhToan = 'Thẻ tín dụng';

  final List<String> _dsPhuongThucThanhToan = const [
    'Thẻ tín dụng',
    'Thẻ ghi nợ',
    'Chuyển khoản ngân hàng',
    'Ví điện tử',
    'Tiền mặt',
  ];

  @override
  void dispose() {
    _ghiChuCtrl.dispose();
    super.dispose();
  }

  void _thongBao(String noiDung, {bool laLoi = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          noiDung,
          style: TextStyle(
            color: laLoi ? cs.onErrorContainer : cs.onTertiaryContainer,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: laLoi ? cs.errorContainer : cs.tertiaryContainer,
      ),
    );
  }

  // ✅ Dialog xác nhận đăng xuất
  void _xacNhanDangXuat() {
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              onPressed: () async {
                Navigator.of(ctx).pop();
                // ✅ AuthProvider của bạn đang có signOut(context) ở các màn khác
                await context.read<AuthProvider>().signOut(context);
              },
              child: Text('Đăng xuất', style: TextStyle(color: cs.onError)),
            ),
          ],
        );
      },
    );
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
    if (!mounted) return;

    setState(() {
      if (laNhanPhong) {
        _ngayNhanPhong = picked;
        if (_ngayTraPhong != null && !_ngayTraPhong!.isAfter(_ngayNhanPhong!)) {
          _ngayTraPhong = null;
        }
      } else {
        _ngayTraPhong = picked;
      }
    });
  }

  int get _soDem {
    if (_ngayNhanPhong == null || _ngayTraPhong == null) return 0;
    final nights = _ngayTraPhong!.difference(_ngayNhanPhong!).inDays;
    return nights > 0 ? nights : 0;
  }

  double get _tongTien => widget.room.price * _soDem;

  Future<void> _datPhong() async {
    FocusScope.of(context).unfocus(); // ✅ ẩn bàn phím

    if (_ngayNhanPhong == null || _ngayTraPhong == null || _soDem <= 0) {
      _thongBao('Vui lòng chọn ngày nhận phòng và ngày trả phòng hợp lệ.');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();

    final uid = authProvider.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      _thongBao('Bạn cần đăng nhập để đặt phòng.', laLoi: true);
      return;
    }

    try {
      final bookingId = await bookingProvider.createBooking(
        userId: uid,
        hotelId: widget.room.hotelId,
        roomId: widget.room.roomId,
        checkInDate: _ngayNhanPhong!,
        checkOutDate: _ngayTraPhong!,
        notes: _ghiChuCtrl.text.trim(),
      );

      if (!mounted || bookingId == null) return;

      final thanhToanOk = await bookingProvider.makePayment(
        bookingId: bookingId,
        paymentMethod: _phuongThucThanhToan,
      );

      if (!mounted) return;

      if (thanhToanOk) {
        _hienDialogThanhCong();
      } else {
        throw Exception(bookingProvider.errorMessage ?? 'Thanh toán thất bại');
      }
    } catch (e) {
      if (!mounted) return;
      _thongBao('Không thể đặt phòng: $e', laLoi: true);
    }
  }

  void _hienDialogThanhCong() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Đặt phòng thành công!'),
          content: const Text(
            'Đơn đặt phòng của bạn đã được xác nhận. Bạn có thể xem lại trong mục “Đơn của tôi”.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/my-bookings',
                      (Route<dynamic> route) => route.isFirst,
                );
              },
              child: Text('Xem đơn của tôi', style: TextStyle(color: cs.secondary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận đặt phòng'),
        actions: [
          // ✅ Nút đổi Sáng/Tối (nếu bạn có ThemeProvider)
          IconButton(
            tooltip: isDark ? 'Chuyển sang sáng' : 'Chuyển sang tối',
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () {
              // ⚠️ Đổi dòng này theo provider theme của bạn
              // context.read<GiaoDienProvider>().doiSangToi();

              // Nếu bạn CHƯA có provider đổi theme thì để tạm thông báo:
              _thongBao('Bạn chưa tích hợp Provider đổi Sáng/Tối.', laLoi: true);
            },
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: _xacNhanDangXuat,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _khungThongTinPhong(theme),
            const SizedBox(height: 24),
            _chonNgayNhanTra(context),
            const SizedBox(height: 24),
            TextFormField(
              controller: _ghiChuCtrl,
              decoration: const InputDecoration(
                labelText: 'Ghi chú / Yêu cầu đặc biệt',
                hintText: 'Ví dụ: Nhận phòng muộn, cần thêm gối…',
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // ✅ ĐÃ DÙNG initialValue -> hết lỗi "value deprecated"
            DropdownButtonFormField<String>(
              initialValue: _phuongThucThanhToan,
              decoration: const InputDecoration(
                labelText: 'Phương thức thanh toán',
                prefixIcon: Icon(Icons.payment_outlined),
              ),
              items: _dsPhuongThucThanhToan
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _phuongThucThanhToan = value);
              },
            ),

            const SizedBox(height: 10),
            Text(
              'Lưu ý: Đây là mô phỏng phương thức thanh toán trong ứng dụng.',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.65),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _tongKetGia(theme),
    );
  }

  Widget _khungThongTinPhong(ThemeData theme) {
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final imageUrl = widget.room.images.isNotEmpty ? widget.room.images.first : '';

    return Card(
      color: cs.surface,
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 100,
                height: 100,
                child: imageUrl.isEmpty
                    ? Container(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                  alignment: Alignment.center,
                  child: Icon(Icons.image_not_supported_outlined, color: cs.onSurfaceVariant),
                )
                    : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                    alignment: Alignment.center,
                    child: Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tenKhachSan,
                    style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.room.type,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mã khách sạn: ${widget.room.hotelId}',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _chonNgayNhanTra(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
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
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.65), fontSize: 12.5),
            ),
            const SizedBox(height: 4),
            Text(
              ngay == null ? 'Chọn ngày' : DateFormat('dd/MM/yyyy').format(ngay),
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tongKetGia(ThemeData theme) {
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tienTe = NumberFormat('#,###', 'vi_VN');

    return Container(
      padding: const EdgeInsets.all(20).copyWith(top: 18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng ($_soDem đêm)',
                style: TextStyle(fontSize: 16, color: cs.onSurface.withValues(alpha: 0.7)),
              ),
              Text(
                '${tienTe.format(_tongTien)} VNĐ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Consumer<BookingProvider>(
              builder: (context, bookingProvider, _) {
                return ElevatedButton.icon(
                  onPressed: bookingProvider.isLoading || _soDem <= 0 ? null : _datPhong,
                  icon: bookingProvider.isLoading
                      ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onPrimary,
                    ),
                  )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(bookingProvider.isLoading ? 'Đang xử lý…' : 'Xác nhận & đặt phòng'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
