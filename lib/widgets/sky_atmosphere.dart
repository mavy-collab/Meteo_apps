import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── Période de la journée ────────────────────────────────────────────────────

enum DayPeriod { dawn, morning, midday, afternoon, sunset, dusk, night }

// ─── Widget principal ─────────────────────────────────────────────────────────

/// Fond atmosphérique animé : gradient + soleil/lune + nuages + étoiles.
/// Tout est dessiné via UN SEUL CustomPainter + UN SEUL AnimationController.
class SkyAtmosphere extends StatefulWidget {
  final Widget child;
  final int? cityLocalHour;
  final bool? cityIsDaytime;
  final String? weatherIconCode;

  const SkyAtmosphere({
    super.key,
    required this.child,
    this.cityLocalHour,
    this.cityIsDaytime,
    this.weatherIconCode,
  });

  @override
  State<SkyAtmosphere> createState() => _SkyAtmosphereState();
}

class _SkyAtmosphereState extends State<SkyAtmosphere>
    with SingleTickerProviderStateMixin {

  // UN SEUL contrôleur pour TOUTES les animations (nuages + étoiles + halo)
  late final AnimationController _ticker;
  late DayPeriod _period;
  late int _hour;
  late final List<List<double>> _stars;

  @override
  void initState() {
    super.initState();
    _hour = widget.cityLocalHour ?? DateTime.now().hour;
    _period = _buildPeriod();

    // Positions fixes des étoiles (graine 42 = reproductible)
    final rng = math.Random(42);
    _stars = List.generate(20, (_) => [
      rng.nextDouble(),
      rng.nextDouble() * 0.60,
      rng.nextDouble() * 1.6 + 0.7,
      rng.nextDouble(),
    ]);

    // Période de 90 secondes, limité à ~20fps via lowerBound trick
    _ticker = AnimationController(
      duration: const Duration(seconds: 90),
      vsync: this,
    )..repeat();
    // Note : shouldRepaint filtre les updates non significatifs
  }

  DayPeriod _buildPeriod() {
    final p = _periodFromHour(_hour);
    if (widget.cityIsDaytime == true && _isNight(p)) return DayPeriod.midday;
    if (widget.cityIsDaytime == false && !_isNight(p)) return DayPeriod.night;
    return p;
  }

  static DayPeriod _periodFromHour(int h) {
    if (h >= 5 && h < 7)  return DayPeriod.dawn;
    if (h >= 7 && h < 11) return DayPeriod.morning;
    if (h >= 11 && h < 15) return DayPeriod.midday;
    if (h >= 15 && h < 18) return DayPeriod.afternoon;
    if (h >= 18 && h < 20) return DayPeriod.sunset;
    if (h >= 20 && h < 22) return DayPeriod.dusk;
    return DayPeriod.night;
  }

  static bool _isNight(DayPeriod p) =>
      p == DayPeriod.night || p == DayPeriod.dusk;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  List<Color> get _gradient {
    switch (_period) {
      case DayPeriod.dawn:
        return [const Color(0xFF1A1038), const Color(0xFFB05070), const Color(0xFFE88050)];
      case DayPeriod.morning:
        return [const Color(0xFF4DA8DA), const Color(0xFF72C8F0), const Color(0xFFFFD080)];
      case DayPeriod.midday:
        return [const Color(0xFF1976D2), const Color(0xFF2196F3), const Color(0xFF64B5F6)];
      case DayPeriod.afternoon:
        return [const Color(0xFF1565C0), const Color(0xFF42A5F5), const Color(0xFFFFB74D)];
      case DayPeriod.sunset:
        return [const Color(0xFF7B1FA2), const Color(0xFFE53935), const Color(0xFFFF9800)];
      case DayPeriod.dusk:
        return [const Color(0xFF1A0A2E), const Color(0xFF3D1C6E), const Color(0xFF5E3090)];
      case DayPeriod.night:
        return [const Color(0xFF050C1A), const Color(0xFF0A1628), const Color(0xFF0D2040)];
    }
  }

  int get _cloudCount {
    final code = widget.weatherIconCode ?? '';
    if (code == '01') return 0;
    if (code == '02') return 1;
    if (code == '03') return 2;
    if (code.isEmpty) return 2;
    return 3;
  }

  Color get _cloudColor {
    switch (_period) {
      case DayPeriod.sunset: return const Color(0xFFFFCCBB);
      case DayPeriod.morning:
      case DayPeriod.dawn:   return const Color(0xFFFFF0E0);
      default:               return Colors.white;
    }
  }

  double get _cloudOpacity {
    switch (_period) {
      case DayPeriod.morning: return 0.55;
      case DayPeriod.midday:  return 0.40;
      case DayPeriod.sunset:  return 0.48;
      default:                return 0.36;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNight = _isNight(_period);
    final showSun  = !isNight && _period != DayPeriod.dawn;
    final showMoon = isNight;
    final showStars = isNight ||
        _period == DayPeriod.dusk ||
        _period == DayPeriod.dawn;
    final showClouds = !isNight;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _gradient,
        ),
      ),
      child: Stack(
        children: [
          // ── Atmosphère animée ─────────────────────────────────────────────
          // RepaintBoundary → les repaints du fond n'affectent pas l'UI.
          // IgnorePointer   → les éléments décoratifs ne bloquent jamais les touches.
          RepaintBoundary(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ticker,
                builder: (_, _) => CustomPaint(
                  painter: _SkyPainter(
                    period:      _period,
                    hour:        _hour,
                    progress:    _ticker.value,
                    stars:       showStars  ? _stars : const [],
                    showSun:     showSun,
                    showMoon:    showMoon,
                    cloudCount:  showClouds ? _cloudCount : 0,
                    cloudColor:  _cloudColor,
                    cloudOpacity: _cloudOpacity,
                  ),
                  // SizedBox.expand() donne au CustomPaint la taille de l'écran
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),

          // ── Contenu UI (reçoit tous les touches) ─────────────────────────
          widget.child,
        ],
      ),
    );
  }
}

// ─── CustomPainter unique ─────────────────────────────────────────────────────
// Dessine étoiles + lune + soleil + nuages en une seule passe canvas.
// Zéro widget alloué par frame → performance maximale.

class _SkyPainter extends CustomPainter {
  final DayPeriod period;
  final int hour;
  final double progress;          // 0.0 → 1.0 sur 90 secondes
  final List<List<double>> stars;
  final bool showSun;
  final bool showMoon;
  final int cloudCount;
  final Color cloudColor;
  final double cloudOpacity;

  const _SkyPainter({
    required this.period,
    required this.hour,
    required this.progress,
    required this.stars,
    required this.showSun,
    required this.showMoon,
    required this.cloudCount,
    required this.cloudColor,
    required this.cloudOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showStars) _drawStars(canvas, size);
    if (showMoon)  _drawMoon(canvas, size);
    if (showSun)   _drawSun(canvas, size);
    if (cloudCount > 0) _drawClouds(canvas, size);
  }

  bool get showStars => stars.isNotEmpty;

  // ── Étoiles ────────────────────────────────────────────────────────────────

  void _drawStars(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final baseAlpha = period == DayPeriod.dawn ? 0.30 : 1.0;
    for (final s in stars) {
      final phase = (s[3] + progress * 0.25) % 1.0; // Scintillement très lent
      final alpha = (baseAlpha * (0.25 + 0.75 * math.sin(phase * math.pi).abs()))
          .clamp(0.0, 1.0);
      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(s[0] * size.width, s[1] * size.height),
        s[2] / 2,
        paint,
      );
    }
  }

  // ── Lune ───────────────────────────────────────────────────────────────────

  void _drawMoon(Canvas canvas, Size size) {
    final cx = size.width - 65.0;
    const cy = 72.0;

    // Halo simulé par cercles empilés (sans MaskFilter.blur)
    canvas.drawCircle(Offset(cx, cy), 50,
        Paint()..color = Colors.white.withValues(alpha: 0.04));
    canvas.drawCircle(Offset(cx, cy), 38,
        Paint()..color = Colors.white.withValues(alpha: 0.06));

    // Disque lunaire
    canvas.drawCircle(Offset(cx, cy), 26,
        Paint()..color = const Color(0xFFE8EAF6));

    // Ombre pour créer le croissant
    canvas.drawCircle(Offset(cx - 12, cy - 8), 22,
        Paint()..color = const Color(0xFF0A1628).withValues(alpha: 0.88));
  }

  // ── Soleil ─────────────────────────────────────────────────────────────────

  void _drawSun(Canvas canvas, Size size) {
    final t = ((hour - 5) / 15.0).clamp(0.0, 1.0);
    final cx = (0.08 + t * 0.84) * size.width;
    final cy = (0.52 - math.sin(t * math.pi) * 0.40) * size.height;

    final double sunR;
    final Color sunColor;
    switch (period) {
      case DayPeriod.dawn:
        sunR = 44; sunColor = const Color(0xFFFF7043);
      case DayPeriod.morning:
        sunR = 36; sunColor = const Color(0xFFFFCA28);
      case DayPeriod.midday:
        sunR = 30; sunColor = const Color(0xFFFFEE58);
      case DayPeriod.afternoon:
        sunR = 36; sunColor = const Color(0xFFFFB300);
      case DayPeriod.sunset:
        sunR = 44; sunColor = const Color(0xFFFF6D00);
      default:
        sunR = 36; sunColor = const Color(0xFFFFD740);
    }

    // Halo pulsant simulé par cercles empilés (sans MaskFilter.blur)
    final pulse = 0.10 + math.sin(progress * 2 * math.pi) * 0.05;
    canvas.drawCircle(Offset(cx, cy), sunR + 40,
        Paint()..color = sunColor.withValues(alpha: (pulse * 0.5).clamp(0.0, 1.0)));
    canvas.drawCircle(Offset(cx, cy), sunR + 22,
        Paint()..color = sunColor.withValues(alpha: (pulse * 0.9).clamp(0.0, 1.0)));

    // Disque solaire
    canvas.drawCircle(Offset(cx, cy), sunR,
        Paint()..color = sunColor);
  }

  // ── Nuages ─────────────────────────────────────────────────────────────────

  void _drawClouds(Canvas canvas, Size size) {
    // Les 3 nuages se déplacent à des vitesses différentes (offsets de phase)
    if (cloudCount >= 1) {
      final x = (1 - progress) * (size.width + 200) - 200;
      _drawCloud(canvas, x, size.height * 0.09, 180, cloudOpacity);
    }
    if (cloudCount >= 2) {
      final p2 = (progress + 0.38) % 1.0;
      final x = (1 - p2) * (size.width + 260) - 260;
      _drawCloud(canvas, x, size.height * 0.18, 240, cloudOpacity - 0.08);
    }
    if (cloudCount >= 3) {
      final p3 = (progress + 0.72) % 1.0;
      final x = (1 - p3) * (size.width + 160) - 160;
      _drawCloud(canvas, x, size.height * 0.06, 140, cloudOpacity - 0.13);
    }
  }

  void _drawCloud(Canvas canvas, double x, double y,
      double width, double opacity) {
    if (opacity <= 0) return;
    final paint = Paint()
      ..color = cloudColor.withValues(alpha: opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    final h = width * 0.55;

    // Base arrondie
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + h * 0.50, width, h * 0.50),
        Radius.circular(h * 0.25),
      ),
      paint,
    );
    // Boursouflures
    canvas.drawCircle(Offset(x + width * 0.24, y + h * 0.42), width * 0.18, paint);
    canvas.drawCircle(Offset(x + width * 0.50, y + h * 0.28), width * 0.20, paint);
    canvas.drawCircle(Offset(x + width * 0.76, y + h * 0.48), width * 0.16, paint);
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      // Limite les repaints à ~11fps : évite de surcharger l'émulateur
      (progress - old.progress).abs() > 0.001;
}
