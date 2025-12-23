import 'package:booking_app/providers/hotel_providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddReviewScreen extends StatefulWidget {
  final String roomId;
  final String hotelId;

  const AddReviewScreen({
    super.key,
    required this.roomId,
    required this.hotelId,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _binhLuanCtrl = TextEditingController();

  double _soSao = 3.0;

  @override
  void dispose() {
    _binhLuanCtrl.dispose();
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
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: laLoi ? cs.errorContainer : cs.tertiaryContainer,
      ),
    );
  }

  Future<void> _guiDanhGia() async {
    FocusScope.of(context).unfocus();

    if (_soSao < 1) {
      _thongBao('Vui lòng chọn số sao (tối thiểu 1 sao).', laLoi: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final hotelProvider = context.read<HotelProvider>();

    try {
      await hotelProvider.addReview(
        roomId: widget.roomId,
        hotelId: widget.hotelId,
        rating: _soSao,
        comment: _binhLuanCtrl.text.trim(),
      );

      if (!mounted) return;
      _thongBao('Cảm ơn bạn đã đánh giá!');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      _thongBao(
        hotelProvider.errorMessage ?? 'Không thể gửi đánh giá. Vui lòng thử lại.',
        laLoi: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Viết đánh giá'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                color: cs.surface,
                elevation: isDark ? 0 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Bạn cảm thấy thế nào về phòng này?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 14),

                      // ⭐ chọn sao
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final active = index < _soSao;
                          return IconButton(
                            tooltip: 'Chọn ${index + 1} sao',
                            icon: Icon(
                              active ? Icons.star : Icons.star_border,
                              color: cs.secondary,
                              size: 40,
                            ),
                            onPressed: () => setState(
                                  () => _soSao = (index + 1).toDouble(),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 6),

                      // Badge số sao
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.secondary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: cs.secondary.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          'Số sao đã chọn: ${_soSao.toInt()}/5',
                          style: TextStyle(
                            color: cs.secondary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 📝 bình luận
                      TextFormField(
                        controller: _binhLuanCtrl,
                        decoration: InputDecoration(
                          labelText: 'Bình luận của bạn',
                          hintText: 'Ví dụ: Phòng sạch sẽ, nhân viên thân thiện…',
                          alignLabelWithHint: true,
                          prefixIcon: const Icon(Icons.chat_bubble_outline),
                          suffixIcon: _binhLuanCtrl.text.trim().isEmpty
                              ? null
                              : IconButton(
                            tooltip: 'Xóa',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _binhLuanCtrl.clear();
                              setState(() {});
                            },
                          ),
                        ),
                        maxLines: 5,
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập bình luận';
                          }
                          if (value.trim().length < 5) {
                            return 'Bình luận quá ngắn (tối thiểu 5 ký tự).';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: Consumer<HotelProvider>(
                  builder: (context, provider, _) {
                    return ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _guiDanhGia,
                      icon: provider.isLoading
                          ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                          : const Icon(Icons.send),
                      label: Text(provider.isLoading ? 'Đang gửi…' : 'Gửi đánh giá'),
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
            ],
          ),
        ),
      ),
    );
  }
}
