import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:booking_app/models/room_model.dart';

import 'package:booking_app/providers/auth_providers.dart';
import 'package:booking_app/providers/booking_providers.dart';
import 'package:booking_app/providers/chat_providers.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:booking_app/providers/notification_provider.dart';
import 'package:booking_app/providers/report_providers.dart';
import 'package:booking_app/providers/theme_provider.dart';

import 'package:booking_app/screens/admin/approve_rooms_screen.dart';
import 'package:booking_app/screens/admin/monitor_bookings_screen.dart';
import 'package:booking_app/screens/admin/reports_screen.dart';

import 'package:booking_app/screens/auth/login_screen.dart';
import 'package:booking_app/screens/auth/register_screen.dart';

import 'package:booking_app/screens/chat/chat_list_screen.dart';
import 'package:booking_app/screens/chat/chat_screen.dart';

import 'package:booking_app/screens/home_screen.dart';

import 'package:booking_app/screens/hotel_owner/manage_rooms_screen.dart';
import 'package:booking_app/screens/hotel_owner/post_room_screen.dart';
import 'package:booking_app/screens/hotel_owner/revenue_stats_screen.dart';
import 'package:booking_app/screens/hotel_owner/reviews_screen.dart';
import 'package:booking_app/screens/admin/room_detail_admin_screen.dart';

// ✅ NEW: màn chọn khách sạn
import 'package:booking_app/screens/hotel_owner/select_hotel_screen.dart';

import 'package:booking_app/screens/notifications/notifications_screen.dart';

import 'package:booking_app/screens/room_details_screen.dart';
import 'package:booking_app/screens/search/search_screen.dart';

import 'package:booking_app/screens/user/add_report_screen.dart';
import 'package:booking_app/screens/user/add_review_screen.dart';
import 'package:booking_app/screens/user/booking_screen.dart';
import 'package:booking_app/screens/user/edit_profile_screen.dart';
import 'package:booking_app/screens/user/my_booking_screen.dart';
import 'package:booking_app/screens/user/profile_screen.dart';

import 'package:booking_app/services/firebase_services.dart';

import 'package:booking_app/intro/splash_screen.dart';
import 'package:booking_app/intro/home_before_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();

  final themeProvider = ThemeProvider();
  await themeProvider.loadAll();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HotelProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ===================== Helpers =====================
  static Widget _routeError(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lỗi điều hướng')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  static String? _readHotelId(dynamic args) {
    if (args is String) return args.trim();
    if (args is Map && args['hotelId'] != null) {
      return args['hotelId'].toString().trim();
    }
    return null;
  }

  static String? _readHotelName(dynamic args) {
    if (args is Map && args['hotelName'] != null) {
      return args['hotelName'].toString().trim();
    }
    return null;
  }

  static RoomModel? _readRoom(dynamic args) {
    if (args is RoomModel) return args;
    if (args is Map && args['room'] is RoomModel) {
      return args['room'] as RoomModel;
    }
    return null;
  }

  // ===================== Themes =====================
  ThemeData _darkTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF1A2B47),
      scaffoldBackgroundColor: const Color(0xFF121E31),
      colorScheme: const ColorScheme.dark().copyWith(
        primary: const Color(0xFF1A2B47),
        secondary: const Color(0xFFF0B90B),
        surface: const Color(0xFF1A2B47),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A2B47),
        selectedItemColor: Color(0xFFF0B90B),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData.light().copyWith(
      primaryColor: const Color(0xFF1A2B47),
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      colorScheme: const ColorScheme.light().copyWith(
        primary: const Color(0xFF1A2B47),
        secondary: const Color(0xFFF0B90B),
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF1A2B47),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    themeProvider.setCurrentRole(auth.currentUser?.role);

    return MaterialApp(
      title: 'Booking App',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.mode,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthWrapper(),
        '/intro': (context) => const HomeBeforeLogin(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/search': (context) => const SearchScreen(),
        '/my-bookings': (context) => const MyBookingsScreen(),
        '/chat-list': (context) => const ChatListScreen(),
        '/approve-rooms': (context) => const ApproveRoomsScreen(),
        '/monitor-bookings': (context) => const MonitorBookingsScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        NotificationsScreen.routeName: (context) => const NotificationsScreen(),
        RoomDetailsScreen.routeName: (context) => const RoomDetailsScreen(),
        '/reviews': (context) => const ReviewsScreen(),
        '/revenue-stats': (context) => const RevenueStatsScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/manage-rooms': {
            final hotelId = _readHotelId(settings.arguments);
            final hotelName = _readHotelName(settings.arguments);

            // ✅ FIX: thiếu hotelId -> đi màn chọn khách sạn
            if (hotelId == null || hotelId.isEmpty) {
              return MaterialPageRoute(
                builder: (_) => const SelectHotelScreen(
                  targetRoute: '/manage-rooms',
                  title: 'Chọn khách sạn để quản lý phòng',
                ),
              );
            }

            return MaterialPageRoute(
              builder: (_) => ManageRoomsScreen(
                hotelId: hotelId,
                hotelName:
                (hotelName != null && hotelName.isNotEmpty) ? hotelName : null,
              ),
            );
          }
          case '/room-detail': {
            final args = settings.arguments;
            final hotelId = _readHotelId(args);
            final hotelName = _readHotelName(args);
            final room = _readRoom(args);

            if (room == null) {
              return MaterialPageRoute(
                builder: (_) => _routeError(
                  "Thiếu RoomModel cho '/room-detail'.\n\n"
                      "Gọi đúng:\n"
                      "Navigator.pushNamed(context, '/room-detail', arguments: {\n"
                      "  'hotelId': hotelId,\n"
                      "  'hotelName': hotelName,\n"
                      "  'room': room,\n"
                      "});",
                ),
              );
            }

            // ✅ lấy hotelId từ args hoặc fallback từ room.hotelId
            final effectiveHotelId = (hotelId != null && hotelId.isNotEmpty)
                ? hotelId
                : room.hotelId;

            if (effectiveHotelId.isEmpty) {
              return MaterialPageRoute(
                builder: (_) => _routeError(
                  "Thiếu hotelId cho '/room-detail'.\n\n"
                      "Hãy truyền Map {'hotelId','hotelName','room'} hoặc đảm bảo room.hotelId có dữ liệu.",
                ),
              );
            }

            return MaterialPageRoute(
              builder: (_) => AdminRoomDetailScreen(
                hotelId: effectiveHotelId,
                hotelName: (hotelName != null && hotelName.isNotEmpty) ? hotelName : null,
                room: room,
              ),
            );
          }

          case '/post-room': {
            final args = settings.arguments;
            final hotelId = _readHotelId(args);
            final hotelName = _readHotelName(args);
            final room = _readRoom(args);

            // ✅ FIX: nếu đang sửa mà thiếu hotelId -> lấy từ room.hotelId
            final effectiveHotelId = (hotelId != null && hotelId.isNotEmpty)
                ? hotelId
                : (room?.hotelId);

            // ✅ tạo mới: cần hotelId -> nếu thiếu thì đi màn chọn khách sạn
            if ((effectiveHotelId == null || effectiveHotelId.isEmpty) &&
                room == null) {
              return MaterialPageRoute(
                builder: (_) => const SelectHotelScreen(
                  targetRoute: '/post-room',
                  title: 'Chọn khách sạn để đăng phòng',
                ),
              );
            }

            // (hiếm) sửa phòng mà vẫn không có hotelId
            if (effectiveHotelId == null || effectiveHotelId.isEmpty) {
              return MaterialPageRoute(
                builder: (_) => _routeError(
                  "Thiếu hotelId cho '/post-room'.\n\n"
                      "Hãy truyền Map {'hotelId','hotelName','room'} hoặc đảm bảo room.hotelId có dữ liệu.",
                ),
              );
            }

            return MaterialPageRoute(
              builder: (_) => PostRoomScreen(
                hotelId: effectiveHotelId,
                hotelName:
                (hotelName != null && hotelName.isNotEmpty) ? hotelName : null,
                room: room,
              ),
            );
          }

          case '/edit-room': {
            final args = settings.arguments;
            final hotelId = _readHotelId(args);
            final hotelName = _readHotelName(args);
            final room = _readRoom(args);

            if (room == null) {
              return MaterialPageRoute(
                builder: (_) => _routeError(
                  "Thiếu RoomModel cho '/edit-room'.\n\n"
                      "Gọi đúng:\n"
                      "Navigator.pushNamed(context, '/edit-room', arguments: {\n"
                      "  'hotelId': hotelId,\n"
                      "  'hotelName': hotelName,\n"
                      "  'room': room,\n"
                      "});",
                ),
              );
            }

            // ✅ hỗ trợ luôn trường hợp chỉ truyền room (lấy hotelId từ room)
            final effectiveHotelId = (hotelId != null && hotelId.isNotEmpty)
                ? hotelId
                : room.hotelId;

            if (effectiveHotelId.isEmpty) {
              return MaterialPageRoute(
                builder: (_) => _routeError(
                  "Thiếu hotelId khi sửa phòng.\n\n"
                      "Hãy truyền Map {'hotelId','hotelName','room'} hoặc đảm bảo room.hotelId có dữ liệu.",
                ),
              );
            }

            return MaterialPageRoute(
              builder: (_) => PostRoomScreen(
                hotelId: effectiveHotelId,
                hotelName:
                (hotelName != null && hotelName.isNotEmpty) ? hotelName : null,
                room: room,
              ),
            );
          }

          case '/booking': {
            final room = settings.arguments as RoomModel;
            return MaterialPageRoute(builder: (_) => BookingScreen(room: room));
          }

          case '/add-review': {
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => AddReviewScreen(
                roomId: args['roomId']!,
                hotelId: args['hotelId']!,
              ),
            );
          }

          case '/add-report': {
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => AddReportScreen(
                hotelId: args['hotelId']!,
                roomId: args['roomId'],
              ),
            );
          }

          case '/chat': {
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: args['chatId']!,
                currentUserId: args['currentUserId']!,
                otherUserName: args['otherUserName']!,
              ),
            );
          }

          default:
            return null;
        }
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => _routeError("Route không tồn tại: ${settings.name}"),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (auth.isLoggedIn && auth.currentUser != null) {
          return const HomeScreen();
        }

        return const HomeBeforeLogin();
      },
    );
  }
}
