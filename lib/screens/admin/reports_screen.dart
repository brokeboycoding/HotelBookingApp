import 'package:booking_app/providers/report_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/report_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key}); // ✅ super parameter

  @override
  State<ReportsScreen> createState() => _ReportsScreenState(); // ✅ public type
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadReports();
    });
  }

  Future<void> _capNhatTrangThai(String maBaoCao, ReportStatus trangThaiMoi) async {
    final reportProvider = context.read<ReportProvider>();
    try {
      await reportProvider.updateReportStatus(maBaoCao, trangThaiMoi);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã cập nhật trạng thái báo cáo.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật trạng thái thất bại: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  String _trangThaiVi(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Chờ xử lý';
      case ReportStatus.resolved:
        return 'Đã xử lý';
      case ReportStatus.dismissed:
        return 'Bỏ qua';
    }
  }

  Color _mauTrangThai(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.dismissed:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo từ người dùng'),
      ),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, child) {
          if (reportProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reportProvider.reports.isEmpty) {
            return Center(
              child: Text(
                'Không có báo cáo nào.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: reportProvider.reports.length,
            itemBuilder: (ctx, i) {
              final report = reportProvider.reports[i];

              final ngayGui = DateFormat('dd/MM/yyyy').format(report.createdAt);
              final tenTrangThai = _trangThaiVi(report.status);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                elevation: isDark ? 0 : 2,
                color: cs.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lý do: ${report.reason}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mã khách sạn: ${report.reportedHotelId}',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
                      ),
                      if (report.reportedRoomId != null)
                        Text(
                          'Mã phòng: ${report.reportedRoomId}',
                          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        'Người báo cáo: ${report.reporterUserId}',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
                      ),
                      const Divider(height: 18),
                      Text(
                        report.description,
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.85)),
                      ),
                      const Divider(height: 18),

                      Row(
                        children: [
                          Chip(
                            label: Text(
                              tenTrangThai,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: _mauTrangThai(report.status).withValues(alpha: 0.20),
                            side: BorderSide(color: _mauTrangThai(report.status)),
                          ),
                          const Spacer(),
                          Text(
                            ngayGui,
                            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),

                      if (report.status == ReportStatus.pending) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('Đánh dấu đã xử lý'),
                                onPressed: () => _capNhatTrangThai(
                                  report.reportId,
                                  ReportStatus.resolved,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.close),
                                label: const Text('Bỏ qua báo cáo'),
                                onPressed: () => _capNhatTrangThai(
                                  report.reportId,
                                  ReportStatus.dismissed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
