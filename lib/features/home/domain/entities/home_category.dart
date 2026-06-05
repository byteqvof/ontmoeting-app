import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class HomeCategory extends Equatable {
  const HomeCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  List<Object?> get props => [id, label, icon, color, backgroundColor];
}
