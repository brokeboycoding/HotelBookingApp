import 'package:flutter/material.dart';

class FakeMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // nền map
    final bg = Paint()..color = const Color(0xFFF3F6FF);
    canvas.drawRect(Offset.zero & size, bg);

    // vài đường “đường phố” giả
    final road = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final thin = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // đường ngang
    for (int i = 0; i < 5; i++) {
      final y = (size.height / 6) * (i + 1);
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), road);
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), thin);
    }

    // đường dọc
    for (int i = 0; i < 4; i++) {
      final x = (size.width / 5) * (i + 1);
      canvas.drawLine(Offset(x, 16), Offset(x, size.height - 16), road);
      canvas.drawLine(Offset(x, 16), Offset(x, size.height - 16), thin);
    }

    // vài “pin” giả
    final pinFill = Paint()..color = const Color(0xFF3F7CFF);
    final pinStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    void drawPin(Offset c) {
      canvas.drawCircle(c, 10, pinFill);
      canvas.drawCircle(c, 10, pinStroke);
    }

    drawPin(Offset(size.width * 0.25, size.height * 0.30));
    drawPin(Offset(size.width * 0.55, size.height * 0.55));
    drawPin(Offset(size.width * 0.78, size.height * 0.35));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
