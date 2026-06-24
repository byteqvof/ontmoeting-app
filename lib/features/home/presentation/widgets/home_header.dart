import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.locationName,
    required this.onLocationTap,
    required this.hasActiveFilters,
    required this.onFilterTap,
    super.key,
  });

  final String locationName;
  final VoidCallback onLocationTap;
  final bool hasActiveFilters;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wat is er te doen in',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.green700.withValues(alpha: .70),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                TextButton.icon(
                  onPressed: onLocationTap,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.ink,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    Icons.location_on_outlined,
                    color: colors.green,
                    size: 20,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colors.green700.withValues(alpha: .72),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: TochSpacing.sm),
          Row(
            children: [
              IconButton(
                tooltip: 'Zoeken',
                onPressed: () {},
                style: IconButton.styleFrom(
                  backgroundColor: colors.card,
                  foregroundColor: colors.green,
                  side: BorderSide(color: colors.line),
                  fixedSize: const Size.square(42),
                ),
                icon: const Icon(Icons.search_rounded),
              ),
              const SizedBox(width: TochSpacing.xs),
              _HeaderFilterButton(
                hasActiveFilters: hasActiveFilters,
                onPressed: onFilterTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderFilterButton extends StatelessWidget {
  const _HeaderFilterButton({
    required this.hasActiveFilters,
    required this.onPressed,
  });

  final bool hasActiveFilters;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Filters',
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: hasActiveFilters ? colors.green : colors.card,
            foregroundColor: hasActiveFilters ? Colors.white : colors.green,
            side: BorderSide(
              color: hasActiveFilters ? colors.green : colors.line,
            ),
            fixedSize: const Size.square(42),
          ),
          icon: _FilterSvgIcon(
            color: hasActiveFilters ? Colors.white : colors.green,
          ),
        ),
        if (hasActiveFilters)
          Positioned(
            top: 5,
            right: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: colors.card, width: 1.4),
              ),
              child: const SizedBox.square(dimension: 9),
            ),
          ),
      ],
    );
  }
}

class _FilterSvgIcon extends StatelessWidget {
  const _FilterSvgIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(22),
      painter: _FilterSvgPainter(color),
    );
  }
}

class _FilterSvgPainter extends CustomPainter {
  const _FilterSvgPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final y1 = size.height * .26;
    final y2 = size.height * .50;
    final y3 = size.height * .74;
    canvas.drawLine(
      Offset(size.width * .12, y1),
      Offset(size.width * .88, y1),
      stroke,
    );
    canvas.drawCircle(Offset(size.width * .35, y1), 2.7, fill);
    canvas.drawLine(
      Offset(size.width * .12, y2),
      Offset(size.width * .88, y2),
      stroke,
    );
    canvas.drawCircle(Offset(size.width * .66, y2), 2.7, fill);
    canvas.drawLine(
      Offset(size.width * .12, y3),
      Offset(size.width * .88, y3),
      stroke,
    );
    canvas.drawCircle(Offset(size.width * .48, y3), 2.7, fill);
  }

  @override
  bool shouldRepaint(covariant _FilterSvgPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
