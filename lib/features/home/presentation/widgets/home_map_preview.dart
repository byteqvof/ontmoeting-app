import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class HomeMapPreview extends StatelessWidget {
  const HomeMapPreview({required this.activityCount, super.key});

  final int activityCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TochRadius.lg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFEAEDE4),
            border: Border.all(color: colors.line),
          ),
          child: SizedBox(
            height: 132,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _MapPainter())),
                Center(
                  child: Transform.translate(
                    offset: const Offset(0, -12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.green.withValues(alpha: .16),
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox.square(dimension: 56),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -42),
                          child: Transform.rotate(
                            angle: .785398,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.green,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(22),
                                  topRight: Radius.circular(22),
                                  bottomLeft: Radius.circular(4),
                                  bottomRight: Radius.circular(22),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.ink.withValues(alpha: .18),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Transform.rotate(
                                angle: -.785398,
                                child: const SizedBox.square(
                                  dimension: 38,
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.white,
                                    size: 21,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(TochRadius.pill),
                      boxShadow: [
                        BoxShadow(
                          color: colors.ink.withValues(alpha: .08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            color: colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$activityCount vlakbij',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final landPaint = Paint()..color = const Color(0xFFE7EBE0);
    final parkPaint = Paint()..color = const Color(0xFFDBE6CC);
    final waterPaint = Paint()..color = const Color(0xFFCFE0E6);
    final roadPaint = Paint()
      ..color = const Color(0xFFD8DACE)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final smallRoadPaint = Paint()
      ..color = const Color(0xFFE0E2D6)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = const Color(0x801E5740);

    canvas.drawRect(Offset.zero & size, landPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .05, size.height * .08, 86, 64),
        const Radius.circular(10),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .68, size.height * .58, 96, 80),
        const Radius.circular(12),
      ),
      parkPaint,
    );

    final river = Path()
      ..moveTo(-10, size.height * .25)
      ..cubicTo(
        size.width * .22,
        size.height * .38,
        size.width * .31,
        size.height * .63,
        size.width * .56,
        size.height * .67,
      )
      ..cubicTo(
        size.width * .78,
        size.height * .72,
        size.width * .92,
        size.height * .9,
        size.width + 20,
        size.height * .84,
      )
      ..lineTo(size.width + 20, size.height + 20)
      ..lineTo(-10, size.height + 20)
      ..close();
    canvas.drawPath(river, waterPaint);

    for (final line in [
      [
        Offset(size.width * .12, -10),
        Offset(size.width * .34, size.height + 20),
      ],
      [
        Offset(size.width * .42, -10),
        Offset(size.width * .58, size.height + 20),
      ],
      [
        Offset(-10, size.height * .3),
        Offset(size.width + 10, size.height * .12),
      ],
      [
        Offset(-10, size.height * .55),
        Offset(size.width * .7, size.height * .42),
      ],
    ]) {
      canvas.drawLine(line.first, line.last, roadPaint);
    }

    for (final line in [
      [
        Offset(size.width * .24, -10),
        Offset(size.width * .42, size.height + 20),
      ],
      [
        Offset(-10, size.height * .78),
        Offset(size.width + 10, size.height * .64),
      ],
    ]) {
      canvas.drawLine(line.first, line.last, smallRoadPaint);
    }

    for (final point in [
      Offset(size.width * .18, size.height * .25),
      Offset(size.width * .34, size.height * .55),
      Offset(size.width * .48, size.height * .36),
      Offset(size.width * .62, size.height * .66),
    ]) {
      canvas.drawCircle(point, 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => false;
}
