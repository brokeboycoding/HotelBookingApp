import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'owner_request_screen.dart';
import 'screens/customer_search_screen.dart';
import 'screens/nearby_map_screen.dart';

import 'tabs/customer_home_tab.dart';
import 'tabs/customer_booking_tab.dart';
import 'tabs/customer_message_tab.dart';

import '../profile/user_profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int index = 0;

  String? _name;
  String? _email;

  final List<String> _recentSearches = <String>[];
  final List<String> _recentViewedRoomIds = <String>[];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String _s(dynamic v) => (v ?? '').toString().trim();

  String? _nameFromEmailOrNull(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return null;

    final hasSeparator =
        local.contains('.') || local.contains('_') || local.contains('-');

    if (hasSeparator) {
      final rawTokens =
      local.split(RegExp(r'[._-]+')).where((t) => t.trim().isNotEmpty);

      final tokens = <String>[];
      for (final t in rawTokens) {
        final onlyLetters = t.replaceAll(RegExp(r'\d+'), '').trim();
        if (onlyLetters.length >= 2) tokens.add(onlyLetters);
      }

      if (tokens.isEmpty) return null;

      return tokens.map((w) {
        final s = w.trim();
        return s[0].toUpperCase() + s.substring(1).toLowerCase();
      }).join(' ');
    }

    final onlyLetters = RegExp(r'^[a-zA-Z]+$');
    if (onlyLetters.hasMatch(local) && local.length >= 2) {
      return local[0].toUpperCase() + local.substring(1).toLowerCase();
    }

    return null;
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = _s(user.email);
    final displayName = _s(user.displayName);

    if (mounted) {
      setState(() {
        _email = email.isNotEmpty ? email : null;
        _name = displayName.isNotEmpty ? displayName : null;
      });
    }

    if (_name == null || _name!.trim().isEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        final firestoreName = _s(doc.data()?["name"]);
        if (mounted && firestoreName.isNotEmpty) {
          setState(() => _name = firestoreName);
        }
      } catch (_) {}
    }

    if (mounted && (_name == null || _name!.trim().isEmpty) && email.isNotEmpty) {
      final guess = _nameFromEmailOrNull(email);
      if (guess != null && guess.trim().isNotEmpty) {
        setState(() => _name = guess);
      }
    }
  }

  String get who {
    final n = _s(_name);
    if (n.isNotEmpty) return n;
    final e = _s(_email);
    if (e.isNotEmpty) return e;
    return "bạn";
  }

  void _pushSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerSearchScreen(
          recentSearches: _recentSearches,
          recentViewedRoomIds: _recentViewedRoomIds,
          onAddRecentSearch: (q) {
            final t = q.trim();
            if (t.isEmpty) return;
            _recentSearches.remove(t);
            _recentSearches.insert(0, t);
            if (_recentSearches.length > 10) _recentSearches.removeLast();
            setState(() {});
          },
          onViewedRoom: (roomId) {
            _recentViewedRoomIds.remove(roomId);
            _recentViewedRoomIds.insert(0, roomId);
            if (_recentViewedRoomIds.length > 15) _recentViewedRoomIds.removeLast();
            setState(() {});
          },
        ),
      ),
    );
  }

  void _pushMap(List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NearbyMapScreen(rooms: rooms)),
    );
  }

  void _pushOwnerRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OwnerRequestScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      CustomerHomeTab(
        who: who,
        onOpenSearch: _pushSearch,
        onViewedRoom: (roomId) {
          _recentViewedRoomIds.remove(roomId);
          _recentViewedRoomIds.insert(0, roomId);
          if (_recentViewedRoomIds.length > 15) _recentViewedRoomIds.removeLast();
          setState(() {});
        },
        onOpenMap: _pushMap,
      ),
      const CustomerBookingTab(),
      const CustomerMessageTab(),
      const UserProfileScreen(), // ✅ hồ sơ dùng chung
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: IndexedStack(index: index, children: pages),
      ),

      // ✅ Nối OwnerRequestScreen: chỉ hiện ở tab Profile
      floatingActionButton: index == 3
          ? FloatingActionButton.extended(
        onPressed: _pushOwnerRequest,
        icon: const Icon(Icons.storefront),
        label: const Text('Đăng ký chủ KS'),
      )
          : null,

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF2F6BFF),
          unselectedItemColor: Colors.black.withValues(alpha: 0.45),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: "My Booking"),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: "Message"),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
