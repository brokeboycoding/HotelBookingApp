import 'package:booking_app/providers/hotel_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // TODO: thay 'h1' bằng mã khách sạn thật
      context.read<HotelProvider>().loadHotelReviews('h1');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá của khách'),
      ),
      body: Consumer<HotelProvider>(
        builder: (context, hotelProvider, _) {
          if (hotelProvider.isLoading && hotelProvider.reviews.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hotelProvider.reviews.isEmpty) {
            return Center(
              child: Text(
                'Chưa có đánh giá nào.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
              ),
            );
          }

          final danhSachDanhGia = hotelProvider.reviews;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: danhSachDanhGia.length,
            itemBuilder: (context, index) {
              final dg = danhSachDanhGia[index];

              final ten = (dg.userName).toString().trim();
              final anhDaiDien = (dg.userAvatarUrl).toString().trim();
              final binhLuan = (dg.comment).toString().trim();
              final soSao = dg.rating;

              final kyTuDau = ten.isNotEmpty ? ten[0].toUpperCase() : '•';

              return Card(
                color: cs.surface,
                margin: const EdgeInsets.only(bottom: 16),
                elevation: isDark ? 0 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: cs.secondary.withValues(alpha: 0.20),
                            foregroundColor: cs.secondary,
                            backgroundImage: anhDaiDien.isNotEmpty
                                ? NetworkImage(anhDaiDien)
                                : null,
                            onBackgroundImageError: (error, stackTrace) {},

                            child: anhDaiDien.isNotEmpty
                                ? null
                                : Text(
                              kyTuDau,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ten.isNotEmpty ? ten : 'Khách ẩn danh',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                soSao.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.star,
                                color: cs.secondary,
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        binhLuan.isNotEmpty ? binhLuan : 'Không có nội dung.',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.82),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
