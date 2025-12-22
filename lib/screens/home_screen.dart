import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_providers.dart';
import '../models/user_model.dart';
import 'room_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentUser;
      if (user?.role == UserRole.user) {
        Provider.of<HotelProvider>(context, listen: false).fetchAllRooms();
      }
    });
  }

  void _onItemTapped(int index) {
    if (index == _currentIndex && index != 0) return;

    switch (index) {
      case 0:
        // Already on home, do nothing.
        break;
      case 1:
        Navigator.pushNamed(context, '/search');
        break;
      case 2:
        Navigator.pushNamed(context, '/my-bookings');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: _buildAppBar(user),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: _buildBody(context, user.role, user),
      bottomNavigationBar: _buildBottomNavigationBar(user.role),
    );
  }

  Widget _buildAppBar(UserModel user) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed('/profile'),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey.shade800,
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome,',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            Text(
              user.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 28),
          onPressed: () {
            // TODO: Implement notifications
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, UserRole role, UserModel user) {
    switch (role) {
      case UserRole.admin:
        return _buildAdminDashboard(context, user);
      case UserRole.hotelOwner:
        return _buildHotelOwnerDashboard(context, user);
      case UserRole.user:
      default:
        return _buildUserDashboard(context, user);
    }
  }

  Widget _buildUserDashboard(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Where do you want\nto go?',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          _buildSearchCard(),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Popular Hotels',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          _buildPopularHotelsList(),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSearchTab('Stays', Icons.hotel, isSelected: true),
              _buildSearchTab('Flights', Icons.flight, isSelected: false),
              _buildSearchTab('Cars', Icons.directions_car, isSelected: false),
              _buildSearchTab(
                'Things to do',
                Icons.local_see,
                isSelected: false,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/search'),
            icon: const Icon(Icons.search),
            label: const Text('Search'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab(
    String title,
    IconData icon, {
    bool isSelected = false,
  }) {
    final color = isSelected
        ? Theme.of(context).colorScheme.secondary
        : Colors.grey;
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _buildPopularHotelsList() {
    return SizedBox(
      height: 220,
      child: Consumer<HotelProvider>(
        builder: (context, hotelProvider, child) {
          if (hotelProvider.isLoading && hotelProvider.rooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (hotelProvider.rooms.isEmpty) {
            return const Center(child: Text('No popular hotels found.'));
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: hotelProvider.rooms.length,
            itemBuilder: (context, index) {
              final room = hotelProvider.rooms[index];
              return _buildHotelCard(room);
            },
          );
        },
      ),
    );
  }

  Widget _buildHotelCard(RoomModel room) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(RoomDetailsScreen.routeName, arguments: room);
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(room.images.isNotEmpty ? room.images.first : 'https://via.placeholder.com/150'),
            fit: BoxFit.cover,
            onError: (e, s) {},
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Colors.transparent, Colors.black54],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.type,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Hotel ID: ${room.hotelId}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHotelOwnerDashboard(BuildContext context, UserModel user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDashboardListItem(
          context: context,
          icon: Icons.add_business,
          title: 'Đăng phòng',
          subtitle: 'Thêm phòng mới cho khách sạn của bạn',
          onTap: () => Navigator.of(context).pushNamed('/post-room'),
        ),
        _buildDashboardListItem(
          context: context,
          icon: Icons.business,
          title: 'Quản lý phòng',
          subtitle: 'Chỉnh sửa hoặc xóa các phòng đã đăng',
          onTap: () => Navigator.of(context).pushNamed('/manage-rooms'),
        ),
        _buildDashboardListItem(
          context: context,
          icon: Icons.analytics,
          title: 'Thống kê',
          subtitle: 'Xem doanh thu và các chỉ số hoạt động',
          onTap: () => Navigator.of(context).pushNamed('/revenue-stats'),
        ),
        _buildDashboardListItem(
          context: context,
          icon: Icons.reviews,
          title: 'Đánh giá',
          subtitle: 'Xem đánh giá từ khách hàng',
          onTap: () => Navigator.of(context).pushNamed('/reviews'),
        ),
      ],
    );
  }

  Widget _buildAdminDashboard(BuildContext context, UserModel user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDashboardListItem(
          context: context,
          icon: Icons.approval,
          title: 'Duyệt phòng',
          subtitle: 'Phê duyệt các phòng chờ đăng',
          onTap: () => Navigator.of(context).pushNamed('/approve-rooms'),
        ),
        _buildDashboardListItem(
          context: context,
          icon: Icons.business,
          title: 'Quản lý phòng',
          subtitle: 'Xem, sửa, xóa tất cả các phòng',
          onTap: () => Navigator.of(context).pushNamed('/manage-rooms'),
        ),
        _buildDashboardListItem(
          context: context,
          icon: Icons.report,
          title: 'Báo cáo',
          subtitle: 'Xem các báo cáo vi phạm từ người dùng',
          onTap: () => Navigator.of(context).pushNamed('/reports'),
        ),
        _buildDashboardListItem(
          context: context,
          icon: Icons.monitor,
          title: 'Theo dõi đặt phòng',
          subtitle: 'Xem tất cả các đơn đặt phòng trên hệ thống',
          onTap: () => Navigator.of(context).pushNamed('/monitor-bookings'),
        ),
      ],
    );
  }

  Widget _buildDashboardListItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 16,
        ),
        leading: Icon(
          icon,
          size: 40,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBottomNavigationBar(UserRole role) {
    if (role != UserRole.user) {
      return BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: _getAdminHotelOwnerNavItems(role),
      );
    }
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_border),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  List<BottomNavigationBarItem> _getAdminHotelOwnerNavItems(UserRole role) {
    if (role == UserRole.hotelOwner) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Tổng quan',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Phòng'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Tin nhắn'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
      ];
    }
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.approval), label: 'Duyệt'),
      BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Báo cáo'),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
    ];
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Provider.of<AuthProvider>(context, listen: false).signOut(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
