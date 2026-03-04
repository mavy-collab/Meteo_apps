import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';
import 'loading_screen.dart';
import '../widgets/app_background.dart';

// ─── Or : identique dans les deux thèmes ──────────────────────────────────────
const _gold      = Color(0xFFD4AF6E);
const _goldLight = Color(0xFFF0D080);

// ─── Palette réactive au thème ────────────────────────────────────────────────
// Mode sombre : fond quasi-noir, texte ivoire
// Mode clair  : fond ivoire chaud, texte brun foncé
class _P {
  final bool dark;
  const _P(this.dark);

  // Arrière-plan principal
  Color get bg        => dark ? const Color(0xFF0A0A0F) : const Color(0xFFFAF6EE);
  // Surface carte
  Color get surface   => dark ? const Color(0xFF12121A) : const Color(0xFFFFFFFF);
  // Fond icône ville
  Color get iconBg    => dark ? const Color(0xFF0A0A0F) : const Color(0xFFF0E8D8);
  // Texte principal
  Color get onBg      => dark ? const Color(0xFFF5EDD8) : const Color(0xFF1A1206);
  // Texte secondaire (sous-titres)
  Color get onBgSub   => onBg.withOpacity(0.38);
  // Séparateur dans la carte
  Color get divider   => _gold.withOpacity(dark ? 0.10 : 0.20);
  // Ligne déco verticale gauche
  Color get lineDecor => _gold.withOpacity(dark ? 0.07 : 0.14);
  // Halo doré en haut
  Color get haloTop   => _gold.withOpacity(dark ? 0.09 : 0.16);
  // Halo violet en bas-gauche
  Color get haloBot   => const Color(0xFF5C3D8F).withOpacity(dark ? 0.10 : 0.05);
}

// ─── HomeScreen ───────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double>   _fadeIn;
  late Animation<Offset>   _heroSlide;
  late Animation<Offset>   _cardSlide;
  late Animation<Offset>   _btnSlide;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        duration: const Duration(milliseconds: 1400), vsync: this)
      ..forward();
    _shimmerCtrl = AnimationController(
        duration: const Duration(seconds: 3), vsync: this)
      ..repeat();
    _fadeIn = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic)));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.25, 0.70, curve: Curves.easeOutCubic)));
    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.50, 1.0, curve: Curves.easeOutCubic)));
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _launch() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const LoadingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder reconstruit tout l'arbre quand le thème change
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark ||
            (mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        final p = _P(isDark);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          color: p.bg,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // ── Fond radial (halos or + violet) ─────────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LuxuryBgPainter(
                        haloTop: p.haloTop, haloBot: p.haloBot),
                  ),
                ),

                // ── Ligne déco verticale gauche ──────────────────────────
                Positioned(
                  left: 28, top: 0, bottom: 0,
                  child: VerticalDivider(width: 1, color: p.lineDecor),
                ),

                SafeArea(
                  child: SingleChildScrollView(
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: Column(
                        children: [
                        // ── Top bar ────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(44, 16, 24, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Logo ✦ MÉTÉO
                              Row(children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: _gold.withOpacity(0.5), width: 1),
                                    gradient: RadialGradient(colors: [
                                      _gold.withOpacity(isDark ? 0.25 : 0.35),
                                      Colors.transparent,
                                    ]),
                                  ),
                                  child: const Center(
                                    child: Text('✦',
                                        style: TextStyle(
                                            color: _gold, fontSize: 11)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('MÉTÉO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: p.onBg.withOpacity(0.45),
                                      letterSpacing: 4,
                                    )),
                              ]),

                              // Bouton toggle thème
                              GestureDetector(
                                onTap: () => themeNotifier.value =
                                    isDark ? ThemeMode.light : ThemeMode.dark,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: _gold.withOpacity(0.28)),
                                    borderRadius: BorderRadius.circular(20),
                                    color: _gold
                                        .withOpacity(isDark ? 0.06 : 0.10),
                                  ),
                                  child: Row(children: [
                                    Icon(
                                      isDark
                                          ? Icons.wb_sunny_outlined
                                          : Icons.nights_stay_outlined,
                                      color: _gold.withOpacity(0.80),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isDark ? 'Jour' : 'Nuit',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _gold.withOpacity(0.70),
                                        letterSpacing: 1,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ── Hero ──────────────────────────────────────
                        SlideTransition(
                          position: _heroSlide,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 44),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(
                                      width: 28,
                                      height: 1,
                                      color: _gold.withOpacity(0.55)),
                                  const SizedBox(width: 10),
                                  Text('COLLECTION MONDIALE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: _gold.withOpacity(0.60),
                                        letterSpacing: 3.5,
                                        fontWeight: FontWeight.w500,
                                      )),
                                ]),
                                const SizedBox(height: 20),
                                RichText(
                                  text: TextSpan(children: [
                                    TextSpan(
                                      text: "L'Art\nde la\n",
                                      style: TextStyle(
                                        fontSize: 58,
                                        fontWeight: FontWeight.w200,
                                        color: p.onBg,
                                        letterSpacing: -2,
                                        height: 1.05,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'Météo',
                                      style: TextStyle(
                                        fontSize: 58,
                                        fontWeight: FontWeight.w700,
                                        color: _gold,
                                        letterSpacing: -2,
                                        height: 1.05,
                                      ),
                                    ),
                                  ]),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Conditions atmosphériques en temps réel,\ncuratées avec précision.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: p.onBgSub,
                                    height: 1.7,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ── Carte villes ──────────────────────────────
                        SlideTransition(
                          position: _cardSlide,
                          child: _LuxuryCitiesCard(
                              shimmerCtrl: _shimmerCtrl, palette: p),
                        ),

                        const SizedBox(height: 40),

                        // ── Bouton CTA ────────────────────────────────
                        SlideTransition(
                          position: _btnSlide,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 44),
                            child: _GoldButton(onTap: _launch),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SlideTransition(
                          position: _btnSlide,
                          child: Text(
                            '✦  Données actualisées en continu  ✦',
                            style: TextStyle(
                              fontSize: 9,
                              color: _gold.withOpacity(0.28),
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
            )],
            ),
          ),
        );
      },
    );
  }
}

// ─── Fond luxe paramétré ──────────────────────────────────────────────────────
class _LuxuryBgPainter extends CustomPainter {
  final Color haloTop;
  final Color haloBot;
  const _LuxuryBgPainter({required this.haloTop, required this.haloBot});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = RadialGradient(colors: [haloTop, Colors.transparent])
              .createShader(Rect.fromCenter(
                  center: Offset(size.width / 2, 0),
                  width: size.width * 1.8,
                  height: size.height * 0.85)));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = RadialGradient(colors: [haloBot, Colors.transparent])
              .createShader(Rect.fromCenter(
                  center: Offset(0, size.height),
                  width: size.width * 1.2,
                  height: size.height * 0.65)));
  }

  @override
  bool shouldRepaint(_LuxuryBgPainter old) =>
      old.haloTop != haloTop || old.haloBot != haloBot;
}

// ─── Carte villes ─────────────────────────────────────────────────────────────
class _LuxuryCitiesCard extends StatelessWidget {
  final AnimationController shimmerCtrl;
  final _P palette;
  const _LuxuryCitiesCard(
      {required this.shimmerCtrl, required this.palette});

  static const _cities = [
    _CityData(flag: '🗼', city: 'Paris',   sub: 'France'),
    _CityData(flag: '🗽', city: 'N.York',  sub: 'USA'),
    _CityData(flag: '⛩️', city: 'Tokyo',  sub: 'Japon'),
    _CityData(flag: '🎡', city: 'Londres', sub: 'UK'),
    _CityData(flag: '🌍', city: 'Dakar',   sub: 'Sénégal'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedBuilder(
        animation: shimmerCtrl,
        builder: (context, child) => CustomPaint(
          // foregroundPainter peint PAR-DESSUS le child → contenu visible
          foregroundPainter:
              _GoldShimmerBorderPainter(progress: shimmerCtrl.value),
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _gold.withOpacity(palette.dark ? 0.04 : 0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DESTINATIONS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _gold.withOpacity(0.55),
                        letterSpacing: 3,
                      )),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: _gold.withOpacity(0.25)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('5 VILLES',
                        style: TextStyle(
                          fontSize: 8,
                          color: _gold.withOpacity(0.50),
                          letterSpacing: 2,
                        )),
                  ),
                ],
              ),
              Divider(color: palette.divider, height: 22, thickness: 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _cities
                    .map((c) =>
                        _LuxuryCityPill(data: c, palette: palette))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer doré tournant sur la bordure ─────────────────────────────────────
class _GoldShimmerBorderPainter extends CustomPainter {
  final double progress;
  const _GoldShimmerBorderPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(20)));
    final metrics = path.computeMetrics().first;
    final total = metrics.length;
    final arcLen = total * 0.28;
    final start = (progress * total) % total;
    final end = start + arcLen;

    Path arcPath;
    if (end <= total) {
      arcPath = metrics.extractPath(start, end);
    } else {
      arcPath = metrics.extractPath(start, total);
      arcPath.addPath(metrics.extractPath(0, end - total), Offset.zero);
    }

    final sr = Rect.fromLTWH(0, 0, size.width, size.height);
    for (final layer in [
      (blur: 16.0, width: 6.0, opacity: 0.30),
      (blur: 6.0,  width: 2.5, opacity: 0.65),
      (blur: 1.5,  width: 1.2, opacity: 1.00),
    ]) {
      canvas.drawPath(
        arcPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = layer.width
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, layer.blur)
          ..shader = SweepGradient(
            colors: [
              _goldLight.withOpacity(0),
              _goldLight.withOpacity(layer.opacity),
              _gold.withOpacity(layer.opacity),
              _gold.withOpacity(0),
            ],
            stops: const [0.0, 0.25, 0.75, 1.0],
            transform: GradientRotation(progress * math.pi * 2),
          ).createShader(sr),
      );
    }

    // Point brillant en tête de l'arc
    final hs = (start + arcLen * 0.93) % total;
    final hp = metrics.extractPath(hs, (hs + 2).clamp(0, total));
    final hm = hp.computeMetrics();
    if (hm.isNotEmpty) {
      final t = hm.first.getTangentForOffset(0);
      if (t != null) {
        canvas.drawCircle(
          t.position, 3.5,
          Paint()
            ..color = _goldLight.withOpacity(0.90)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        canvas.drawCircle(
          t.position, 1.5,
          Paint()..color = Colors.white.withOpacity(0.95),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GoldShimmerBorderPainter old) =>
      old.progress != progress;
}

// ─── Data & Pill ville ────────────────────────────────────────────────────────
class _CityData {
  final String flag;
  final String city;
  final String sub;
  const _CityData(
      {required this.flag, required this.city, required this.sub});
}

class _LuxuryCityPill extends StatelessWidget {
  final _CityData data;
  final _P palette;
  const _LuxuryCityPill({required this.data, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: palette.iconBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _gold.withOpacity(0.20), width: 1),
            boxShadow: [
              BoxShadow(
                  color: _gold.withOpacity(0.08),
                  blurRadius: 10,
                  spreadRadius: 1)
            ],
          ),
          child: Center(
              child: Text(data.flag,
                  style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(height: 8),
        Text(data.city,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: palette.onBg.withOpacity(0.70),
              letterSpacing: 0.5,
            )),
        const SizedBox(height: 2),
        Text(data.sub,
            style: TextStyle(
              fontSize: 8,
              color: _gold.withOpacity(0.45),
              letterSpacing: 0.3,
            )),
      ],
    );
  }
}

// ─── Bouton doré principal ────────────────────────────────────────────────────
class _GoldButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GoldButton({required this.onTap});
  @override
  State<_GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<_GoldButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: _pressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 19),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFBF953F),
                  Color(0xFFD4AF6E),
                  Color(0xFFF0D080),
                  Color(0xFFD4AF6E),
                  Color(0xFFBF953F),
                ],
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: _gold.withOpacity(_pressed ? 0.18 : 0.32),
                  blurRadius: _pressed ? 10 : 22,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Explorer la Météo',
                    style: TextStyle(
                      color: Color(0xFF1A1206),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    )),
                const SizedBox(width: 12),
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0x33000000),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_forward_rounded,
                        color: Color(0xFF1A1206), size: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}