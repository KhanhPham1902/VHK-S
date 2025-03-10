import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TrianglePainter extends CustomPainter {
    @override
    void paint(Canvas canvas, Size size) {
        Paint paint = Paint()..color = Colors.white;
        Path path = Path();

        // Vẽ tam giác cân hướng xuống dưới
        path.moveTo(0, 0); // Góc trái
        path.lineTo(size.width / 2, size.height); // Đỉnh dưới
        path.lineTo(size.width, 0); // Góc phải
        path.close();

        canvas.drawPath(path, paint);
    }

    @override
    bool shouldRepaint(CustomPainter oldDelegate) => false;
}

