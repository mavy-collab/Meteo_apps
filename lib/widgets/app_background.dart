import 'package:flutter/material.dart';

/// Widget qui met un fond en dégradé.
/// Il change automatiquement selon le mode clair ou sombre.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  static const List<Color> _lightGradient = [
    Color(0xFFF0F4FF),
    Color(0xFF667EEA),
  ];

  static const List<Color> _darkGradient = [
    Color(0xFF1A1038),
    Color(0xFF0A0E21),
  ];

  List<Color> _getGradientColors(Brightness brightness) =>
      brightness == Brightness.dark ? _darkGradient : _lightGradient;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _getGradientColors(brightness),
        ),
      ),
      child: child,
    );
  }
}