import 'package:flutter/material.dart';

import '../../../../app/widgets/toch_design_system.dart';
import '../../../../core/utils/toch_category_icons.dart';
import '../../domain/entities/home_category.dart';

extension HomeCategoryStyleX on HomeCategory {
  IconData get icon => tochCategoryIcon(id: id, label: label, iconKey: iconKey);

  Color get color {
    return _colorFromHex(colorHex) ?? tochCategorySkin(_styleKey).color;
  }

  Color get backgroundColor {
    return _colorFromHex(backgroundColorHex) ??
        tochCategorySkin(_styleKey).tint;
  }

  String get _styleKey {
    final key = iconKey?.trim();
    if (key != null && key.isNotEmpty) {
      return '$id $label $key';
    }
    return '$id $label';
  }
}

Color? _colorFromHex(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  final hex = normalized.startsWith('#') ? normalized.substring(1) : normalized;
  if (hex.length != 6 && hex.length != 8) {
    return null;
  }

  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) {
    return null;
  }

  if (hex.length == 6) {
    return Color(0xFF000000 | parsed);
  }
  return Color(parsed);
}
