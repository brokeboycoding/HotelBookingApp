import 'package:booking_app/providers/report_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/report_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).loadReports();
    });
  }

  void _updateStatus(String reportId, ReportStatus newStatus) {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    reportProvider.updateReportStatus(reportId, newStatus).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            return const Center(child: Text('Không có báo cáo nào.'));
          }

          return ListView.builder(
            itemCount: reportProvider.reports.length,
            itemBuilder: (ctx, i) {
              final report = reportProvider.reports[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lý do: ${report.reason}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Khách sạn: ${report.reportedHotelId}'),
                      if (report.reportedRoomId != null)
                        Text('Phòng: ${report.reportedRoomId}'),
                      const SizedBox(height: 4),
                      Text('Người báo cáo: ${report.reporterUserId}'),
                      const Divider(),
                      Text(report.description),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(report.status.name),
                            backgroundColor:
                                _getStatusColor(report.status),
                          ),
                          Text(DateFormat('dd/MM/yy')
                              .format(report.createdAt)),
                          if (report.status == ReportStatus.pending)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  child: const Text('Resolve'),
                                  onPressed: () => _updateStatus(
                                      report.reportId, ReportStatus.resolved),
                                ),
                                TextButton(
                                  child: const Text('Dismiss'),
                                  onPressed: () => _updateStatus(
                                      report.reportId, ReportStatus.dismissed),
                                ),
                              ],
                            ),
                        ],
                      )
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

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.dismissed:
        return Colors.grey;
    }
  }
}
