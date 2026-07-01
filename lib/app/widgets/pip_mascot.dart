import 'package:flutter/material.dart';

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
      child: Image.asset(
        _assetNameFor(expression),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}

String _assetNameFor(PipExpression expression) {
  return switch (expression) {
    PipExpression.happy => 'assets/pip/pip-blij.png',
    PipExpression.proud => 'assets/pip/pip-trots.png',
    PipExpression.thinking => 'assets/pip/pip-denkend.png',
    PipExpression.wait => 'assets/pip/pip-wachten.png',
    PipExpression.surprise => 'assets/pip/pip-zwaaien.png',
  };
}
