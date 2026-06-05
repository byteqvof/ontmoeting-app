import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class HomeAvatarStack extends StatelessWidget {
  const HomeAvatarStack({required this.initials, super.key});

  final List<String> initials;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final visible = initials.take(4).toList();

    return SizedBox(
      width: 22.0 + (visible.length * 21.0),
      height: 30,
      child: Stack(
        children: [
          for (var index = 0; index < visible.length; index++)
            Positioned(
              left: index * 21,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.card, width: 2.4),
                ),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: visible[index].startsWith('+')
                      ? colors.card
                      : index.isEven
                      ? colors.green
                      : colors.categoryVisel,
                  child: Text(
                    visible[index],
                    style: TextStyle(
                      color: visible[index].startsWith('+')
                          ? colors.green700.withValues(alpha: .72)
                          : Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
