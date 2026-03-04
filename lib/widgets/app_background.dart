import 'package:flutter/material.dart';

/// Simple gradient background that responds to light/dark mode.
///
/// Light mode uses a soft blue/white gradient, dark mode a deep blue/indigo.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = brightness == Brightness.dark
        ? const [Color(0xFF1A1038), Color(0xFF0A0E21)]
        : const [Color(0xFFF0F4FF), Color(0xFF667EEA)];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}
