import 'package:booking_app/models/review_model.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({Key? key}) : super(key: key);

  @override
  _ReviewsScreenState createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Hardcoded hotelId for now
      Provider.of<HotelProvider>(context, listen: false).loadHotelReviews('h1');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Reviews'),
      ),
      body: Consumer<HotelProvider>(
        builder: (context, hotelProvider, child) {
          if (hotelProvider.isLoading && hotelProvider.reviews.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hotelProvider.reviews.isEmpty) {
            return const Center(
              child: Text('No reviews yet.'),
            );
          }

          final reviews = hotelProvider.reviews;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Card(
                color: Theme.of(context).colorScheme.surface,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(review.userAvatarUrl),
                            onBackgroundImageError: (_, __) {},
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              review.userName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                review.rating.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.star,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        review.comment,
                        style: const TextStyle(color: Colors.white70, height: 1.5),
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
