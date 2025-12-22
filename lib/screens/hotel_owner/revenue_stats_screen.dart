import 'package:booking_app/providers/booking_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RevenueStatsScreen extends StatefulWidget {
  const RevenueStatsScreen({Key? key}) : super(key: key);

  @override
  _RevenueStatsScreenState createState() => _RevenueStatsScreenState();
}

class _RevenueStatsScreenState extends State<RevenueStatsScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    // Hardcoded hotelId for now
    const hotelId = 'h1';

    final revenue =
        await bookingProvider.calculateRevenue(hotelId: hotelId);
    final statistics = await bookingProvider.getStatistics(hotelId: hotelId);

    return {'revenue': revenue, 'stats': statistics};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue & Statistics'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Could not load statistics.'));
          }

          final data = snapshot.data!;
          final double totalRevenue = data['revenue'];
          final Map<String, int> stats = data['stats'];
          final int totalBookings = stats['total'] ?? 0;
          final double averageRevenue =
              totalBookings > 0 ? totalRevenue / totalBookings : 0.0;

          final currencyFormatter = NumberFormat('#,###', 'vi_VN');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryCard(
                  title: 'Total Revenue',
                  value: '${currencyFormatter.format(totalRevenue)} VNĐ',
                  icon: Icons.attach_money,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                      title: 'Total Bookings',
                      value: totalBookings.toString(),
                      icon: Icons.bookmark_border,
                    ),
                    _buildStatCard(
                      title: 'Confirmed',
                      value: (stats['confirmed'] ?? 0).toString(),
                      icon: Icons.check_circle_outline,
                    ),
                    _buildStatCard(
                      title: 'Avg. Revenue',
                      value: '${currencyFormatter.format(averageRevenue)} VNĐ',
                      icon: Icons.monetization_on_outlined,
                    ),
                    _buildStatCard(
                      title: 'Cancelled',
                      value: (stats['cancelled'] ?? 0).toString(),
                      icon: Icons.cancel_outlined,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Colors.black),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
