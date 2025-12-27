import 'package:booking_app/models/hotel_model.dart';
import 'package:booking_app/models/user_model.dart';
import 'package:booking_app/providers/auth_providers.dart';
import 'package:booking_app/services/hotel_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'create_hotel_screen.dart';

class SelectHotelScreen extends StatefulWidget {
  final String targetRoute; // '/manage-rooms' hoặc '/post-room'
  final String title;

  const SelectHotelScreen({
    super.key,
    required this.targetRoute,
    required this.title,
  });

  @override
  State<SelectHotelScreen> createState() => _SelectHotelScreenState();
}

class _SelectHotelScreenState extends State<SelectHotelScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Stream<List<HotelModel>> _streamHotels(UserModel user) {
    if (user.role == UserRole.hotelOwner) {
      return HotelService().getOwnerHotels(user.uid);
    }

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
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isOwner ? () => _openCreateHotel(context) : null,
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Thêm khách sạn'),
            ),
          ),
        ),
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

          final q = _searchCtrl.text.trim().toLowerCase();
          final filtered = q.isEmpty
              ? hotels
              : hotels.where((h) {
            final s = '${h.name} ${h.address}'.toLowerCase();
            return s.contains(q);
          }).toList(growable: false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên khách sạn…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.55),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cs.primary, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (hotels.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text(
                      'Bạn chưa có khách sạn nào.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text(
                      'Không tìm thấy khách sạn.',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                ...filtered.map((h) {
                  final thumbUrl = (h.images.isNotEmpty ? h.images.first : '').trim();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.55),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: thumbUrl.isNotEmpty
                              ? Image.network(
                            thumbUrl,
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 54,
                              height: 54,
                              color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                              alignment: Alignment.center,
                              child: const Icon(Icons.apartment_rounded),
                            ),
                          )
                              : Container(
                            width: 54,
                            height: 54,
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                            alignment: Alignment.center,
                            child: const Icon(Icons.apartment_rounded),
                          ),
                        ),
                        title: Text(
                          h.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
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
                            widget.targetRoute,
                            arguments: {
                              'hotelId': h.hotelId,
                              'hotelName': h.name,
                            },
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
            ],
          );
        },
      ),
    );
  }
}
