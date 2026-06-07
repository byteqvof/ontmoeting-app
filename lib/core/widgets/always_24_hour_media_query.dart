import 'package:flutter/widgets.dart';

class Always24HourMediaQuery extends StatelessWidget {
  const Always24HourMediaQuery({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final data = mediaQuery == null
        ? const MediaQueryData(alwaysUse24HourFormat: true)
        : mediaQuery.copyWith(alwaysUse24HourFormat: true);

    return MediaQuery(data: data, child: child);
  }
}
