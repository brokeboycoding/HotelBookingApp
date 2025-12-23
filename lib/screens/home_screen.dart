import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_providers.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

import 'room_details_screen.dart';
import 'notifications/notifications_screen.dart';

// ✅ NEW: màn chọn khách sạn (để có hotelId trước khi đi manage/post)
import 'hotel_owner/select_hotel_screen.dart';

/// ✅ Bộ icon đẹp (Material Rounded) – đổi 1 nơi, cả app đổi theo
class AppIcons {
  // AppBar
  static const notify = Icons.notifications_none_rounded;
  static const themeDark = Icons.dark_mode_rounded;
  static const themeLight = Icons.light_mode_rounded;
  static const logout = Icons.logout_rounded;
  static const chevron = Icons.chevron_right_rounded;

  // User - Search tabs
  static const stay = Icons.hotel_rounded;
  static const flight = Icons.flight_takeoff_rounded;
  static const car = Icons.directions_car_filled_rounded;
  static const experience = Icons.local_activity_rounded;
  static const search = Icons.travel_explore_rounded;

  // Bottom nav - common
  static const home = Icons.home_rounded;
  static const profile = Icons.account_circle_rounded;

  // User bottom nav
  static const bookings = Icons.event_available_rounded;

  // Owner bottom nav
  static const dashboard = Icons.space_dashboard_rounded;
  static const rooms = Icons.meeting_room_rounded;
  static const chat = Icons.forum_rounded;

  // Admin bottom nav + tiles
  static const approve = Icons.fact_check_rounded;
  static const manage = Icons.domain_rounded;
  static const reports = Icons.report_problem_rounded;
  static const monitorBookings = Icons.event_note_rounded;
  static const settings = Icons.settings_rounded;

  // Owner tiles
  static const postRoom = Icons.add_home_work_rounded;
  static const stats = Icons.query_stats_rounded;
  static const reviews = Icons.rate_review_rounded;

  // Others
  static const imageFallback = Icons.broken_image_outlined;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _chiMucDuoi = 0;
  UserRole? _lastRole;

  String? _roleToString(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.hotelOwner:
        return 'hotelOwner';
      case UserRole.user:
        return 'user';
      default:
        return null;
    }
  }

  // ✅ NEW: mở màn chọn khách sạn trước khi đi route cần hotelId
  void _moChonKhachSan({
    required String targetRoute,
    required String title,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectHotelScreen(
          targetRoute: targetRoute,
          title: title,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;

      // ✅ set theme role cho ThemeProvider
      context.read<ThemeProvider>().setCurrentRole(user?.role);

      // ✅ start listener thông báo (để badge cập nhật realtime)
      if (user != null) {
        context.read<NotificationProvider>().startUnreadListener(
          userId: user.uid, // nếu user.id của bạn là uid
          role: _roleToString(user.role),
        );
      }

      // load rooms cho user
      if (user?.role == UserRole.user) {
        context.read<HotelProvider>().fetchAllRooms();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final role = context.read<AuthProvider>().currentUser?.role;
    if (role != _lastRole) {
      _lastRole = role;
      context.read<ThemeProvider>().setCurrentRole(role);
    }
  }

  void _chonTab(UserRole role, int index) {
    if (index == _chiMucDuoi) return;

    setState(() => _chiMucDuoi = index);

    if (role == UserRole.user) {
      switch (index) {
        case 0:
          return;
        case 1:
          Navigator.pushNamed(context, '/search');
          return;
        case 2:
          Navigator.pushNamed(context, '/my-bookings');
          return;
        case 3:
          Navigator.pushNamed(context, '/profile');
          return;
      }
    }

    if (role == UserRole.hotelOwner) {
      switch (index) {
        case 0:
          return;
        case 1:
        // ✅ FIX: trước đây pushNamed('/manage-rooms') => thiếu hotelId
          _moChonKhachSan(
            targetRoute: '/manage-rooms',
            title: 'Chọn khách sạn để quản lý phòng',
          );
          return;
        case 2:
          Navigator.pushNamed(context, '/chat-list');
          return;
        case 3:
          Navigator.pushNamed(context, '/profile');
          return;
      }
    }

    // Admin
    switch (index) {
      case 0:
        return;
      case 1:
        Navigator.pushNamed(context, '/approve-rooms');
        return;
      case 2:
        Navigator.pushNamed(context, '/reports');
        return;
      case 3:
        Navigator.pushNamed(context, '/profile');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ✅ theme theo role + icon đúng
    final themeProvider = context.watch<ThemeProvider>();
    final dangToi = themeProvider.isDark(context);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        toolbarHeight: 82,
        title: _tieuDeAppBar(user),
        automaticallyImplyLeading: false,
        actions: [
          // ✅ NÚT SÁNG/TỐI (lưu riêng theo role)
          IconButton(
            tooltip: dangToi ? 'Chuyển sang sáng' : 'Chuyển sang tối',
            icon: Icon(dangToi ? AppIcons.themeLight : AppIcons.themeDark),
            onPressed: () => context.read<ThemeProvider>().toggle(context),
          ),

          // ✅ Đăng xuất
          IconButton(
            tooltip: 'Đăng xuất',
            icon: Icon(AppIcons.logout, color: cs.error),
            onPressed: () => _hopThoaiDangXuat(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _noiDungTheoVaiTro(context, user.role, user),
      bottomNavigationBar: _thanhDieuHuongDuoi(user.role),
    );
  }

  // =========================
  // AppBar
  // =========================
  Widget _tieuDeAppBar(UserModel user) {
    final cs = Theme.of(context).colorScheme;

    final ten = user.name.trim();
    final roleStr = _roleToString(user.role);

    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed('/profile'),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Icon(AppIcons.profile, color: cs.primary),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào,',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.65),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ten.isNotEmpty ? ten : 'Người dùng',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const Spacer(),

        // ✅ Chuông + badge số chưa đọc
        StreamBuilder<List<AppNotification>>(
          stream: context.read<NotificationProvider>().streamNotifications(
            userId: user.uid, // uid
            role: roleStr,
            onlyUnread: true,
          ),
          builder: (context, snapshot) {
            final unread = snapshot.data?.length ?? 0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Thông báo',
                  icon: Icon(
                    AppIcons.notify,
                    size: 28,
                    color: cs.onSurface,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      NotificationsScreen.routeName,
                    );
                  },
                ),
                if (unread > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.error,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: cs.surface, width: 2),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        unread > 99 ? '99+' : unread.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cs.onError,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // =========================
  // Body theo vai trò
  // =========================
  Widget _noiDungTheoVaiTro(
      BuildContext context, UserRole role, UserModel user) {
    switch (role) {
      case UserRole.admin:
        return _bangDieuKhienAdmin(context);
      case UserRole.hotelOwner:
        return _bangDieuKhienChuKS(context);
      case UserRole.user:
        return _bangTrangChuNguoiDung(context);
    }
  }

  // -------------------------
  // USER
  // -------------------------
  Widget _bangTrangChuNguoiDung(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              'Bạn muốn đi đâu\nhôm nay?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
          _theTimKiem(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Gợi ý nổi bật',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ),
          _danhSachGoiY(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _theTimKiem() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _tabTimKiem('Lưu trú', AppIcons.stay, isChon: true),
              _tabTimKiem('Chuyến bay', AppIcons.flight),
              _tabTimKiem('Xe', AppIcons.car),
              _tabTimKiem('Trải nghiệm', AppIcons.experience),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/search'),
              icon: const Icon(AppIcons.search),
              label: const Text('Tìm kiếm'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabTimKiem(String tieuDe, IconData icon, {bool isChon = false}) {
    final cs = Theme.of(context).colorScheme;
    final mau = isChon ? cs.secondary : cs.onSurface.withValues(alpha: 0.55);

    return Column(
      children: [
        Icon(icon, color: mau, size: 28),
        const SizedBox(height: 4),
        Text(
          tieuDe,
          style: TextStyle(
            color: mau,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _danhSachGoiY() {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 220,
      child: Consumer<HotelProvider>(
        builder: (context, hotelProvider, child) {
          if (hotelProvider.isLoading && hotelProvider.rooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hotelProvider.rooms.isEmpty) {
            return Center(
              child: Text(
                'Chưa có gợi ý nào.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.65)),
              ),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: hotelProvider.rooms.length,
            itemBuilder: (context, index) {
              final room = hotelProvider.rooms[index];
              return _theKhachSan(room);
            },
          );
        },
      ),
    );
  }

  Widget _theKhachSan(RoomModel room) {
    final cs = Theme.of(context).colorScheme;

    final anh = room.images.isNotEmpty ? room.images.first.trim() : '';
    final coAnh = anh.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        RoomDetailsScreen.routeName,
        arguments: room,
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: coAnh
                    ? Image.network(
                  anh,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _anhLoi(),
                )
                    : _anhLoi(),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    cs.onSurface.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.surface,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mã KS: ${room.hotelId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.surface.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _anhLoi() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
      alignment: Alignment.center,
      child: Icon(AppIcons.imageFallback, color: cs.onSurfaceVariant),
    );
  }

  // -------------------------
  // OWNER
  // -------------------------
  Widget _bangDieuKhienChuKS(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _mucBangDieuKhien(
          icon: AppIcons.postRoom,
          tieuDe: 'Đăng phòng',
          moTa: 'Thêm phòng mới cho khách sạn của bạn',
          // ✅ FIX: mở chọn khách sạn -> rồi mới vào /post-room
          onTap: () => _moChonKhachSan(
            targetRoute: '/post-room',
            title: 'Chọn khách sạn để đăng phòng',
          ),
        ),
        _mucBangDieuKhien(
          icon: AppIcons.manage,
          tieuDe: 'Quản lý phòng',
          moTa: 'Chỉnh sửa hoặc xoá các phòng đã đăng',
          // ✅ FIX: mở chọn khách sạn -> rồi mới vào /manage-rooms
          onTap: () => _moChonKhachSan(
            targetRoute: '/manage-rooms',
            title: 'Chọn khách sạn để quản lý phòng',
          ),
        ),
        _mucBangDieuKhien(
          icon: AppIcons.stats,
          tieuDe: 'Thống kê',
          moTa: 'Xem doanh thu và các chỉ số',
          onTap: () => Navigator.of(context).pushNamed('/revenue-stats'),
        ),
        _mucBangDieuKhien(
          icon: AppIcons.reviews,
          tieuDe: 'Đánh giá',
          moTa: 'Xem đánh giá từ khách hàng',
          onTap: () => Navigator.of(context).pushNamed('/reviews'),
        ),
      ],
    );
  }

  // -------------------------
  // ADMIN
  // -------------------------
  Widget _bangDieuKhienAdmin(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _mucBangDieuKhien(
          icon: AppIcons.approve,
          tieuDe: 'Duyệt phòng',
          moTa: 'Phê duyệt các phòng chờ đăng',
          onTap: () => Navigator.of(context).pushNamed('/approve-rooms'),
        ),
        _mucBangDieuKhien(
          icon: AppIcons.manage,
          tieuDe: 'Quản lý phòng',
          moTa: 'Xem / sửa / xoá tất cả phòng',
          // ✅ FIX: admin cũng cần chọn khách sạn (vì route /manage-rooms yêu cầu hotelId)
          onTap: () => _moChonKhachSan(
            targetRoute: '/manage-rooms',
            title: 'Chọn khách sạn để quản lý phòng',
          ),
        ),
        _mucBangDieuKhien(
          icon: AppIcons.reports,
          tieuDe: 'Báo cáo',
          moTa: 'Xem báo cáo vi phạm từ người dùng',
          onTap: () => Navigator.of(context).pushNamed('/reports'),
        ),
        _mucBangDieuKhien(
          icon: AppIcons.monitorBookings,
          tieuDe: 'Theo dõi đặt phòng',
          moTa: 'Xem tất cả đơn đặt phòng',
          onTap: () => Navigator.of(context).pushNamed('/monitor-bookings'),
        ),
      ],
    );
  }

  Widget _mucBangDieuKhien({
    required IconData icon,
    required String tieuDe,
    required String moTa,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: cs.surface,
      elevation: isDark ? 0 : 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
        ),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        leading: Icon(icon, size: 40, color: cs.secondary),
        title: Text(
          tieuDe,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: cs.onSurface,
          ),
        ),
        subtitle: Text(
          moTa,
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.65)),
        ),
        trailing: Icon(
          AppIcons.chevron,
          size: 22,
          color: cs.onSurface.withValues(alpha: 0.55),
        ),
        onTap: onTap,
      ),
    );
  }

  // =========================
  // Bottom Navigation
  // =========================
  Widget _thanhDieuHuongDuoi(UserRole role) {
    if (role == UserRole.user) {
      return BottomNavigationBar(
        currentIndex: _chiMucDuoi,
        onTap: (i) => _chonTab(role, i),
        items: const [
          BottomNavigationBarItem(icon: Icon(AppIcons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(AppIcons.search), label: 'Tìm kiếm'),
          BottomNavigationBarItem(
              icon: Icon(AppIcons.bookings), label: 'Đặt phòng'),
          BottomNavigationBarItem(icon: Icon(AppIcons.profile), label: 'Cá nhân'),
        ],
      );
    }

    if (role == UserRole.hotelOwner) {
      return BottomNavigationBar(
        currentIndex: _chiMucDuoi,
        onTap: (i) => _chonTab(role, i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(AppIcons.dashboard), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(AppIcons.rooms), label: 'Phòng'),
          BottomNavigationBarItem(icon: Icon(AppIcons.chat), label: 'Tin nhắn'),
          BottomNavigationBarItem(icon: Icon(AppIcons.profile), label: 'Cá nhân'),
        ],
      );
    }

    return BottomNavigationBar(
      currentIndex: _chiMucDuoi,
      onTap: (i) => _chonTab(role, i),
      items: const [
        BottomNavigationBarItem(
            icon: Icon(AppIcons.dashboard), label: 'Tổng quan'),
        BottomNavigationBarItem(icon: Icon(AppIcons.approve), label: 'Duyệt'),
        BottomNavigationBarItem(icon: Icon(AppIcons.reports), label: 'Báo cáo'),
        BottomNavigationBarItem(icon: Icon(AppIcons.settings), label: 'Cài đặt'),
      ],
    );
  }

  // =========================
  // Logout Dialog
  // =========================
  void _hopThoaiDangXuat(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthProvider>().signOut(context);
            },
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: Text('Đăng xuất', style: TextStyle(color: cs.onError)),
          ),
        ],
      ),
    );
  }
}
