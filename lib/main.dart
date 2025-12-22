import 'package:booking_app/models/room_model.dart';
import 'package:booking_app/providers/auth_providers.dart';
import 'package:booking_app/providers/booking_providers.dart';
import 'package:booking_app/providers/chat_providers.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:booking_app/providers/report_providers.dart';
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
import 'package:booking_app/screens/room_details_screen.dart';
import 'package:booking_app/screens/search/search_screen.dart';
import 'package:booking_app/screens/user/add_report_screen.dart';
import 'package:booking_app/screens/user/add_review_screen.dart';
import 'package:booking_app/screens/user/booking_screen.dart';
import 'package:booking_app/screens/user/edit_profile_screen.dart';
import 'package:booking_app/screens/user/my_booking_screen.dart';
import 'package:booking_app/screens/user/profile_screen.dart';
import 'package:booking_app/services/firebase_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HotelProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Booking App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
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
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF2D3B51),
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFFF0B90B),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1A2B47),
            selectedItemColor: Color(0xFFF0B90B),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/search': (context) => const SearchScreen(),
          '/my-bookings': (context) => const MyBookingsScreen(),
          '/chat-list': (context) => const ChatListScreen(),
          '/post-room': (context) => const PostRoomScreen(),
          '/manage-rooms': (context) => const ManageRoomsScreen(),
          '/reviews': (context) => const ReviewsScreen(),
          '/revenue-stats': (context) => const RevenueStatsScreen(),
          '/approve-rooms': (context) => const ApproveRoomsScreen(),
          '/monitor-bookings': (context) => const MonitorBookingsScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/add-review': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments as Map<String, String>;
            return AddReviewScreen(
              roomId: args['roomId']!,
              hotelId: args['hotelId']!,
            );
          },
          '/add-report': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments as Map<String, String>;
            return AddReportScreen(
              hotelId: args['hotelId']!,
              roomId: args['roomId'],
            );
          },
          '/chat': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments as Map<String, String>;
            return ChatScreen(
              chatId: args['chatId']!,
              currentUserId: args['currentUserId']!,
              otherUserName: args['otherUserName']!,
            );
          },
          '/booking': (context) {
            final room =
                ModalRoute.of(context)!.settings.arguments as RoomModel;
            return BookingScreen(room: room);
          },
          RoomDetailsScreen.routeName: (context) => const RoomDetailsScreen(),
          '/edit-room': (context) {
            final room =
                ModalRoute.of(context)!.settings.arguments as RoomModel;
            return PostRoomScreen(room: room);
          },
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (auth.isLoggedIn && auth.currentUser != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}