import 'package:booking_app/providers/report_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddReportScreen extends StatefulWidget {
  final String hotelId;
  final String? roomId;

  const AddReportScreen({Key? key, required this.hotelId, this.roomId})
      : super(key: key);

  @override
  _AddReportScreenState createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      final reportProvider =
          Provider.of<ReportProvider>(context, listen: false);

      try {
        await reportProvider.addReport(
          hotelId: widget.hotelId,
          roomId: widget.roomId,
          reason: _reasonController.text,
          description: _descriptionController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cảm ơn bạn đã gửi báo cáo.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reportProvider.errorMessage ?? 'Không thể gửi báo cáo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo vi phạm'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Báo cáo cho khách sạn: ${widget.hotelId}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (widget.roomId != null)
                Text('Phòng: ${widget.roomId}'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Lý do báo cáo',
                  hintText: 'VD: Thông tin sai sự thật, vấn đề vệ sinh,...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập lý do';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng mô tả chi tiết vấn đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Consumer<ReportProvider>(
                  builder: (context, provider, _) => ElevatedButton(
                    onPressed: provider.isLoading ? null : _submitReport,
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Gửi báo cáo'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
