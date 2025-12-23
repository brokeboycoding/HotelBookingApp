import 'package:booking_app/providers/booking_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RevenueStatsScreen extends StatefulWidget {
  const RevenueStatsScreen({super.key});

  @override
  State<RevenueStatsScreen> createState() => _RevenueStatsScreenState();
}

class _RevenueStatsScreenState extends State<RevenueStatsScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    final bookingProvider = context.read<BookingProvider>();

    // TODO: thay 'h1' bằng hotelId thật của chủ khách sạn
    const hotelId = 'h1';

    final revenue = await bookingProvider.calculateRevenue(hotelId: hotelId);
    final statistics = await bookingProvider.getStatistics(hotelId: hotelId);

    return <String, dynamic>{
      'revenue': revenue,
      'stats': statistics,
    };
  }

  void _reload() {
    setState(() {
      _statsFuture = _fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doanh thu & Thống kê'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Không thể tải thống kê.'));
          }

          final data = snapshot.data!;
          final double totalRevenue = (data['revenue'] as num?)?.toDouble() ?? 0;
          final Map<String, int> stats =
              (data['stats'] as Map<String, int>?) ?? <String, int>{};

          final int totalBookings = stats['total'] ?? 0;
          final int confirmed = stats['confirmed'] ?? 0;
          final int cancelled = stats['cancelled'] ?? 0;

          final double averageRevenue =
          totalBookings > 0 ? totalRevenue / totalBookings : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryCard(
                  context: context,
                  title: 'Tổng doanh thu',
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
                      context: context,
                      title: 'Tổng lượt đặt',
                      value: totalBookings.toString(),
                      icon: Icons.bookmark_border,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Đã xác nhận',
                      value: confirmed.toString(),
                      icon: Icons.check_circle_outline,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Doanh thu TB',
                      value: '${currencyFormatter.format(averageRevenue)} VNĐ',
                      icon: Icons.monetization_on_outlined,
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Đã huỷ',
                      value: cancelled.toString(),
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
    required BuildContext context,
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
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Colors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
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

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 36, color: theme.colorScheme.secondary),
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
