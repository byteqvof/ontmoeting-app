import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class CreateActivityChoiceChips extends StatelessWidget {
  const CreateActivityChoiceChips({
    required this.options,
    required this.selectedOption,
    required this.onSelected,
    this.icon,
    this.expand = false,
    super.key,
  });

  final List<String> options;
  final String selectedOption;
  final ValueChanged<String> onSelected;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final children = [
      for (final option in options)
        _CreateActivityChip(
          label: option,
          icon: icon,
          selected: selectedOption == option,
          onPressed: () => onSelected(option),
          expanded: expand,
        ),
    ];

    if (expand) {
      return Row(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            Expanded(child: children[index]),
            if (index != children.length - 1) const SizedBox(width: 8),
          ],
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _CreateActivityChip extends StatelessWidget {
  const _CreateActivityChip({
    required this.label,
    required this.selected,
    required this.onPressed,
    required this.expanded,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final bool expanded;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final style = TextButton.styleFrom(
      foregroundColor: selected
          ? colors.green
          : colors.green700.withValues(alpha: .68),
      backgroundColor: selected ? colors.card : colors.green100,
      minimumSize: Size(expanded ? double.infinity : 0, 38),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: const StadiumBorder(),
      side: BorderSide(color: selected ? colors.green200 : Colors.transparent),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
    );

    return SizedBox(
      height: 38,
      child: icon == null
          ? TextButton(onPressed: onPressed, style: style, child: labelWidget)
          : TextButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 15),
              label: labelWidget,
              style: style,
            ),
    );
  }
}
