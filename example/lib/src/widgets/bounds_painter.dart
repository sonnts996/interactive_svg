/*
 Created by sonnts996 on 15/10/25.
 Copyright (c) 2025 . All rights reserved.
*/

import 'package:flutter/material.dart';

class BoundsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw red border
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paint);

    // Dot paint
    final dotPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Text style
    const textStyle = TextStyle(
      color: Colors.red,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    // Helper to draw dot and text
    void drawDotWithText(Offset offset) {
      canvas.drawCircle(offset, 5, dotPaint);
      final textSpan = TextSpan(
        text:
            '(${offset.dx.toStringAsFixed(1)}, ${offset.dy.toStringAsFixed(1)})',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 100);

      // Default offset: right and down
      var textOffset = offset + const Offset(8, 4);

      // If near right edge, move text to the left
      if (offset.dx >= size.width - 1) {
        textOffset = offset - Offset(textPainter.width + 8, -4);
      }
      // If near bottom edge, move text up
      if (offset.dy >= size.height - 1) {
        textOffset = textOffset - Offset(0, textPainter.height + 8);
      }
      // If both right and bottom, adjust both
      if (offset.dx >= size.width - 1 && offset.dy >= size.height - 1) {
        textOffset =
            offset - Offset(textPainter.width + 8, textPainter.height + 8);
      }

      textPainter.paint(canvas, textOffset);
    }

    // Four corners and center
    final points = [
      Offset.zero, // top-left
      Offset(size.width, 0), // top-right
      Offset(0, size.height), // bottom-left
      Offset(size.width, size.height), // bottom-right
      Offset(size.width / 2, size.height / 2), // center
    ];

    points.forEach(drawDotWithText);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
