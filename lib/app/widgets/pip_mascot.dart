import 'package:flutter/material.dart';

import '../theme/toch_theme.dart';

enum PipExpression { happy, proud, thinking, wait, surprise }

class PipMascot extends StatelessWidget {
  const PipMascot({
    this.expression = PipExpression.happy,
    this.size = 128,
    super.key,
  });

  final PipExpression expression;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pip',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _PipPainter(expression: expression)),
      ),
    );
  }
}

class _PipPainter extends CustomPainter {
  const _PipPainter({required this.expression});

  final PipExpression expression;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200;
    canvas.scale(scale);

    final shadow = Paint()
      ..color = const Color(0xFF19211C).withValues(alpha: .12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(const Rect.fromLTWH(42, 198, 116, 18), shadow);

    final body = Paint()..color = TochColors.green;
    final bodyDark = Paint()..color = const Color(0xFF184A36);
    final tint = Paint()..color = TochColors.green100;
    final amber = Paint()..color = TochColors.orange;
    final white = Paint()..color = TochColors.card;

    final bodyPath = Path()
      ..moveTo(62, 198)
      ..quadraticBezierTo(44, 170, 50, 123)
      ..quadraticBezierTo(56, 70, 100, 54)
      ..quadraticBezierTo(144, 70, 150, 123)
      ..quadraticBezierTo(156, 170, 138, 198)
      ..quadraticBezierTo(103, 214, 62, 198)
      ..close();
    canvas.drawPath(bodyPath, body);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(58, 84, 84, 92),
        const Radius.circular(36),
      ),
      tint,
    );

    canvas.drawCircle(const Offset(100, 75), 50, body);
    canvas.drawCircle(const Offset(100, 77), 36, tint);

    _drawEyes(canvas, bodyDark);
    _drawMouth(canvas, bodyDark);

    canvas.drawCircle(const Offset(146, 130), 13, amber);
    canvas.drawCircle(
      const Offset(149, 127),
      5,
      Paint()..color = TochColors.orangeSoft.withValues(alpha: .75),
    );

    if (expression == PipExpression.proud ||
        expression == PipExpression.happy) {
      _drawArm(canvas, from: const Offset(58, 122), to: const Offset(29, 96));
    }
    if (expression == PipExpression.wait ||
        expression == PipExpression.thinking) {
      canvas.drawCircle(const Offset(65, 152), 7, white);
      canvas.drawCircle(const Offset(135, 152), 7, white);
    }
    if (expression == PipExpression.surprise) {
      canvas.drawCircle(const Offset(100, 104), 9, bodyDark);
    }
  }

  void _drawEyes(Canvas canvas, Paint paint) {
    final leftY = expression == PipExpression.thinking ? 88.0 : 92.0;
    final rightY = expression == PipExpression.thinking ? 94.0 : 92.0;
    if (expression == PipExpression.wait) {
      _drawClosedEye(canvas, const Offset(84, 92), paint);
      _drawClosedEye(canvas, const Offset(116, 92), paint);
      return;
    }
    canvas.drawCircle(Offset(84, leftY), 5, paint);
    canvas.drawCircle(Offset(116, rightY), 5, paint);
  }

  void _drawClosedEye(Canvas canvas, Offset center, Paint paint) {
    final path = Path()
      ..moveTo(center.dx - 8, center.dy)
      ..quadraticBezierTo(center.dx, center.dy + 6, center.dx + 8, center.dy);
    canvas.drawPath(
      path,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    paint.style = PaintingStyle.fill;
  }

  void _drawMouth(Canvas canvas, Paint paint) {
    if (expression == PipExpression.surprise) {
      return;
    }
    final mouth = Path()
      ..moveTo(82, 112)
      ..quadraticBezierTo(
        100,
        expression == PipExpression.proud ? 132 : 126,
        120,
        112,
      );
    canvas.drawPath(
      mouth,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawArm(Canvas canvas, {required Offset from, required Offset to}) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = TochColors.green
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(to, 10, Paint()..color = TochColors.green100);
  }

  @override
  bool shouldRepaint(covariant _PipPainter oldDelegate) {
    return oldDelegate.expression != expression;
  }
}
