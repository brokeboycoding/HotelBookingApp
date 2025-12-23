import 'package:booking_app/providers/report_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddReportScreen extends StatefulWidget {
  final String hotelId;
  final String? roomId;

  // ✅ thêm mấy cái này
  final String? hotelName;
  final String? roomLabel; // ví dụ: "Phòng 101" hoặc "Deluxe - 101"

  const AddReportScreen({
    super.key,
    required this.hotelId,
    this.roomId,
    this.hotelName,
    this.roomLabel,
  });

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lyDoCtrl = TextEditingController();
  final _moTaCtrl = TextEditingController();

  @override
  void dispose() {
    _lyDoCtrl.dispose();
    _moTaCtrl.dispose();
    super.dispose();
  }

  void _thongBao(String noiDung, {bool laLoi = false}) {
    final cs = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          noiDung,
          style: TextStyle(
            color: laLoi ? cs.onErrorContainer : cs.onTertiaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: laLoi ? cs.errorContainer : cs.tertiaryContainer,
      ),
    );
  }

  Future<void> _guiBaoCao() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final reportProvider = context.read<ReportProvider>();

    try {
      await reportProvider.addReport(
        hotelId: widget.hotelId,
        roomId: widget.roomId,
        reason: _lyDoCtrl.text.trim(),
        description: _moTaCtrl.text.trim(),
      );

      if (!mounted) return;
      _thongBao('Cảm ơn bạn! Báo cáo đã được gửi.');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      _thongBao(
        reportProvider.errorMessage ?? 'Không thể gửi báo cáo. Vui lòng thử lại.',
        laLoi: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final hotelText = widget.hotelName?.trim().isNotEmpty == true
        ? widget.hotelName!.trim()
        : widget.hotelId;

    final roomText = widget.roomLabel?.trim().isNotEmpty == true
        ? widget.roomLabel!.trim()
        : (widget.roomId ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo vi phạm'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: cs.surface,
                elevation: isDark ? 0 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Khách sạn: $hotelText',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                      if (widget.roomId != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Phòng: $roomText',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: _lyDoCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Lý do báo cáo',
                  hintText: 'Ví dụ: Thông tin sai, vấn đề vệ sinh, lừa đảo…',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  suffixIcon: _lyDoCtrl.text.trim().isEmpty
                      ? null
                      : IconButton(
                    tooltip: 'Xóa',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _lyDoCtrl.clear();
                      setState(() {});
                    },
                  ),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return 'Vui lòng nhập lý do báo cáo';
                  if (v.length < 5) return 'Lý do quá ngắn (tối thiểu 5 ký tự).';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _moTaCtrl,
                decoration: InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  hintText: 'Hãy mô tả rõ sự việc để chúng tôi xử lý nhanh hơn…',
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.description_outlined),
                  suffixIcon: _moTaCtrl.text.trim().isEmpty
                      ? null
                      : IconButton(
                    tooltip: 'Xóa',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _moTaCtrl.clear();
                      setState(() {});
                    },
                  ),
                ),
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return 'Vui lòng mô tả chi tiết vấn đề';
                  if (v.length < 10) return 'Mô tả quá ngắn (tối thiểu 10 ký tự).';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: Consumer<ReportProvider>(
                  builder: (context, provider, _) {
                    return ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _guiBaoCao,
                      icon: provider.isLoading
                          ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                          : const Icon(Icons.report_outlined),
                      label: Text(provider.isLoading ? 'Đang gửi…' : 'Gửi báo cáo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Lưu ý: Báo cáo sẽ được kiểm duyệt. Vui lòng cung cấp thông tin chính xác.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
