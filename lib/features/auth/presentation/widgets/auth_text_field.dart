import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    required this.label,
    required this.keyboardType,
    required this.validator,
    this.obscureText = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final String? Function(String?) validator;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      cursorColor: colors.green,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: colors.ink,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.green,
          fontWeight: FontWeight.w900,
        ),
        filled: true,
        fillColor: colors.card,
        contentPadding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: colors.green, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFC0492F)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFC0492F), width: 2),
        ),
      ),
    );
  }
}
