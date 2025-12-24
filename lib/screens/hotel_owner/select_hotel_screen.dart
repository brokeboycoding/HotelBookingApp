import 'package:booking_app/models/hotel_model.dart';
import 'package:booking_app/models/user_model.dart';
import 'package:booking_app/providers/auth_providers.dart';
import 'package:booking_app/services/hotel_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'create_hotel_screen.dart';

class SelectHotelScreen extends StatelessWidget {
  final String targetRoute; // '/manage-rooms' hoặc '/post-room'
  final String title;

  const SelectHotelScreen({
    super.key,
    required this.targetRoute,
    required this.title,
  });

  Stream<List<HotelModel>> _streamHotels(UserModel user) {
    // Chủ khách sạn -> chỉ lấy hotel của owner
    if (user.role == UserRole.hotelOwner) {
      return HotelService().getOwnerHotels(user.uid);
    }

    // Admin -> lấy tất cả hotels
    return FirebaseFirestore.instance.collection('hotels').snapshots().map(
          (s) => s.docs.map((d) => HotelModel.fromFirestore(d)).toList(),
    );
  }

  void _openCreateHotel(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateHotelScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isOwner = user.role == UserRole.hotelOwner;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (isOwner)
            IconButton(
              tooltip: 'Tạo khách sạn',
              icon: const Icon(Icons.add_business_rounded),
              onPressed: () => _openCreateHotel(context),
            ),
        ],
      ),
      body: StreamBuilder<List<HotelModel>>(
        stream: _streamHotels(user),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Lỗi tải danh sách khách sạn:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final hotels = snapshot.data ?? [];

          // EMPTY STATE: chưa có khách sạn -> gợi ý tạo
          if (hotels.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.apartment_rounded,
                      size: 64,
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Bạn chưa có khách sạn nào.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hãy tạo khách sạn trước rồi quay lại.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // only owner mới có thể tạo
                    if (isOwner)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _openCreateHotel(context),
                          icon: const Icon(Icons.add_business_rounded),
                          label: const Text('Tạo khách sạn ngay'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: hotels.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final h = hotels[i];
              final thumbUrl =
              (h.images.isNotEmpty ? h.images.first : '').trim();

              return Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: thumbUrl.isNotEmpty
                        ? Image.network(
                      thumbUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 52,
                        height: 52,
                        color: cs.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.apartment_rounded),
                      ),
                    )
                        : Container(
                      width: 52,
                      height: 52,
                      color: cs.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.apartment_rounded),
                    ),
                  ),
                  title: Text(
                    h.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    h.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      targetRoute,
                      arguments: {
                        'hotelId': h.hotelId,
                        'hotelName': h.name,
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
