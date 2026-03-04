import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../widgets/weather_card.dart';
import '../widgets/app_background.dart';
import '../main.dart';
import 'detail_screen.dart';

// ─── Palette or ───────────────────────────────────────────────────────────────
const _gold      = Color(0xFFD4AF6E);
const _goldLight = Color(0xFFF0D080);
const _goldDark  = Color(0xFFBF953F);

// ─── Palette réactive clair / sombre ─────────────────────────────────────────
class _P {
  final bool dark;
  const _P(this.dark);
  Color get bg      => dark ? const Color(0xFF0A0A0F) : const Color(0xFFFAF6EE);
  Color get surface => dark ? const Color(0xFF12121A) : const Color(0xFFFFFFFF);
  Color get onBg    => dark ? const Color(0xFFF5EDD8) : const Color(0xFF1A1206);
  Color get onBgSub => onBg.withOpacity(0.40);
  Color get haloTop => _gold.withOpacity(dark ? 0.09 : 0.16);
  Color get haloBot => const Color(0xFF5C3D8F).withOpacity(dark ? 0.10 : 0.05);
}

// ─── Couleurs néon par ville ──────────────────────────────────────────────────
Color _cityColor(String city) {
  switch (city) {
    case 'Paris':    return const Color(0xFF00D4FF); // cyan électrique
    case 'New York': return const Color(0xFFFF4D6D); // rouge néon
    case 'Tokyo':    return const Color(0xFFE040FB); // violet magenta
    case 'London':   return const Color(0xFF39FF14); // vert néon
    case 'Dakar':    return const Color(0xFFFFAA00); // orange fluo
    default:         return _gold;
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});
  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  final List<String> cities = ['Paris', 'New York', 'Tokyo', 'London', 'Dakar'];
  final List<String> messages = [
    'Collecte des donnees atmospheriques...',
    'Analyse des conditions meteo...',
    'Finalisation en cours...',
  ];

  final WeatherService _weatherService = WeatherService();
  List<WeatherModel> weatherList = [];
  double progress = 0.0;
  int messageIndex = 0;
  int cityIndex = 0;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  Timer? _timer;

  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _fade;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _pulseCtrl = AnimationController(duration: const Duration(milliseconds: 1800), vsync: this)..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _shimmerCtrl = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat();
    startLoading();
  }

  void startLoading() {
    _timer?.cancel();
    _fadeCtrl.reset();
    setState(() {
      weatherList = []; progress = 0.0; messageIndex = 0; cityIndex = 0;
      isLoading = true; hasError = false; errorMessage = '';
    });
    bool isFetching = false;
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (isFetching) return;
      isFetching = true;
      if (cityIndex < cities.length) {
        try {
          final weather = await _weatherService.fetchWeather(cities[cityIndex]);
          if (!mounted) return;
          setState(() {
            weatherList.add(weather); cityIndex++; progress = cityIndex / cities.length;
            messageIndex = (messageIndex + 1) % messages.length;
          });
        } catch (e) {
          timer.cancel();
          if (!mounted) return;
          setState(() { hasError = true; isLoading = false; errorMessage = 'Impossible de recuperer les donnees.\nVerifiez votre connexion ou votre cle API.'; });
        }
      }
      isFetching = false;
      if (cityIndex >= cities.length) {
        timer.cancel();
        if (!mounted) return;
        setState(() => isLoading = false);
        _fadeCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); _fadeCtrl.dispose(); _pulseCtrl.dispose(); _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark || (mode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        final p = _P(isDark);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          color: p.bg,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _LuxBgPainter(haloTop: p.haloTop, haloBot: p.haloBot))),
                Positioned(left: 28, top: 0, bottom: 0, child: VerticalDivider(width: 1, color: _gold.withOpacity(isDark ? 0.07 : 0.14))),
                SafeArea(
                  child: Column(
                    children: [
                      _topBar(context, p, isDark),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: hasError ? _buildError(p) : (isLoading ? _buildLoading(p) : _buildResults(p)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(BuildContext context, _P p, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 38, height: 38,
              decoration: BoxDecoration(
                border: Border.all(color: _gold.withOpacity(0.30)),
                borderRadius: BorderRadius.circular(12),
                color: _gold.withOpacity(isDark ? 0.07 : 0.10),
              ),
              child: Center(child: Icon(Icons.arrow_back_rounded, color: _gold.withOpacity(0.80), size: 18)),
            ),
          ),
          const SizedBox(width: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              key: ValueKey(isLoading ? 0 : (hasError ? 1 : 2)),
              isLoading ? 'CHARGEMENT' : (hasError ? 'ERREUR' : 'METEO MONDIALE'),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.onBg.withOpacity(0.45), letterSpacing: 3.5),
            ),
          ),
          const Spacer(),
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _gold.withOpacity(0.4), width: 1),
              gradient: RadialGradient(colors: [_gold.withOpacity(isDark ? 0.20 : 0.30), Colors.transparent]),
            ),
            child: const Center(child: Text('*', style: TextStyle(color: _gold, fontSize: 14, fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(_P p) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _shimmerCtrl,
          builder: (context, _) => SizedBox(
            width: 200, height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(width: 200, height: 200,
                  child: CircularProgressIndicator(value: 1.0, strokeWidth: 1.5, color: _gold.withOpacity(0.12), strokeCap: StrokeCap.round)),
                SizedBox(width: 200, height: 200,
                  child: CustomPaint(painter: _GoldArcPainter(
                    progress: progress,
                    shimmer: _shimmerCtrl.value,
                    arcColor: cityIndex > 0 ? _cityColor(cities[cityIndex - 1]) : _gold,
                  ))),
                ScaleTransition(
                  scale: _pulse,
                  child: Container(
                    width: 130, height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        (cityIndex > 0 ? _cityColor(cities[cityIndex - 1]) : _gold).withOpacity(0.10),
                        Colors.transparent,
                      ]),
                      border: Border.all(color: (cityIndex > 0 ? _cityColor(cities[cityIndex - 1]) : _gold).withOpacity(0.14), width: 1),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(progress * 100).toInt()}',
                      style: TextStyle(fontSize: 52, fontWeight: FontWeight.w100, color: p.onBg, letterSpacing: -3, height: 1)),
                    Text('%', style: TextStyle(fontSize: 14,
                        color: (cityIndex > 0 ? _cityColor(cities[cityIndex - 1]) : _gold).withOpacity(0.80),
                        fontWeight: FontWeight.w500, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text('$cityIndex / ${cities.length} VILLES',
                      style: TextStyle(fontSize: 9, color: p.onBgSub, letterSpacing: 2, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        Row(children: [
          Expanded(child: Divider(color: _gold.withOpacity(0.12), thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('*', style: TextStyle(color: _gold.withOpacity(0.35), fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Divider(color: _gold.withOpacity(0.12), thickness: 0.5)),
        ]),
        const SizedBox(height: 28),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          child: Text(
            messages[messageIndex],
            key: ValueKey(messageIndex),
            style: TextStyle(fontSize: 14, color: p.onBgSub, fontWeight: FontWeight.w300, height: 1.6, letterSpacing: 0.3),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        if (weatherList.isNotEmpty) ...[
          Text('CHARGEES', style: TextStyle(fontSize: 9, color: _gold.withOpacity(0.45), letterSpacing: 3, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
            children: weatherList.asMap().entries.map((entry) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + entry.key * 60),
              curve: Curves.easeOut,
              builder: (context, v, child) => Opacity(opacity: v, child: Transform.scale(scale: 0.85 + 0.15 * v, child: child)),
              child: Builder(builder: (context) {
                final cc = _cityColor(entry.value.city);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cc, width: 1.2),
                    boxShadow: [
                      BoxShadow(color: cc.withOpacity(0.55), blurRadius: 18, spreadRadius: 0),
                      BoxShadow(color: cc.withOpacity(0.20), blurRadius: 40, spreadRadius: 4),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cc,
                        boxShadow: [BoxShadow(color: cc, blurRadius: 6, spreadRadius: 1)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(entry.value.city, style: TextStyle(color: cc, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8,
                        shadows: [Shadow(color: cc.withOpacity(0.80), blurRadius: 8)])),
                  ]),
                );
              }),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildError(_P p) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold.withOpacity(0.25), width: 1),
            gradient: RadialGradient(colors: [_gold.withOpacity(0.10), Colors.transparent]),
          ),
          child: Center(child: Icon(Icons.cloud_off_rounded, size: 38, color: _gold.withOpacity(0.70))),
        ),
        const SizedBox(height: 28),
        Text('Connexion\ninterrompue',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w200, color: p.onBg, letterSpacing: -1, height: 1.1)),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: p.onBgSub, height: 1.7, letterSpacing: 0.2)),
        ),
        const SizedBox(height: 40),
        _GoldOutlineBtn(label: 'Reessayer', icon: Icons.refresh_rounded, onTap: startLoading),
      ],
    );
  }

  Widget _buildResults(_P p) {
    return FadeTransition(
      opacity: _fade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(children: [
            Container(width: 28, height: 1, color: _gold.withOpacity(0.55)),
            const SizedBox(width: 10),
            Text('RESULTATS', style: TextStyle(fontSize: 9, color: _gold.withOpacity(0.60), letterSpacing: 3.5, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 10),
          RichText(text: TextSpan(children: [
            TextSpan(text: '${weatherList.length} ', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: _gold, letterSpacing: -1, height: 1)),
            TextSpan(text: 'villes', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w200, color: p.onBg, letterSpacing: -1, height: 1)),
          ])),
          const SizedBox(height: 4),
          Text('Mis a jour a l\'instant', style: TextStyle(fontSize: 11, color: _gold.withOpacity(0.45), letterSpacing: 1.5)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: weatherList.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 280 + index * 80),
                curve: Curves.easeOut,
                builder: (context, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ColoredCardWrapper(
                    city: weatherList[index].city,
                    isDark: p.dark,
                    child: WeatherCard(
                      weather: weatherList[index],
                      onTap: () => Navigator.push(context, PageRouteBuilder(
                        pageBuilder: (_, anim, __) => DetailScreen(weather: weatherList[index]),
                        transitionsBuilder: (_, anim, __, child) => SlideTransition(
                          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                        transitionDuration: const Duration(milliseconds: 380),
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _GoldOutlineBtn(label: 'Recommencer', icon: Icons.refresh_rounded, onTap: startLoading),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ColoredCardWrapper extends StatelessWidget {
  final String city;
  final bool isDark;
  final Widget child;
  const _ColoredCardWrapper({required this.city, required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    final cc = _cityColor(city);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: cc.withOpacity(isDark ? 0.20 : 0.14), blurRadius: 18, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            child,
            // Bandeau coloré gauche
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 3.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [cc, cc.withOpacity(0.25)],
                  ),
                ),
              ),
            ),
            // Badge ville coloré haut droite
            Positioned(
              top: 10, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cc.withOpacity(isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cc.withOpacity(0.40), width: 0.8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 4, height: 4,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: cc)),
                  const SizedBox(width: 5),
                  Text(city.toUpperCase(),
                      style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800,
                          color: cc, letterSpacing: 1.2)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LuxBgPainter extends CustomPainter {
  final Color haloTop;
  final Color haloBot;
  const _LuxBgPainter({required this.haloTop, required this.haloBot});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = RadialGradient(colors: [haloTop, Colors.transparent])
            .createShader(Rect.fromCenter(center: Offset(size.width / 2, 0), width: size.width * 1.8, height: size.height * 0.85)));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = RadialGradient(colors: [haloBot, Colors.transparent])
            .createShader(Rect.fromCenter(center: Offset(0, size.height), width: size.width * 1.2, height: size.height * 0.65)));
  }
  @override
  bool shouldRepaint(_LuxBgPainter old) => old.haloTop != haloTop || old.haloBot != haloBot;
}

class _GoldArcPainter extends CustomPainter {
  final double progress;
  final double shimmer;
  final Color arcColor;
  const _GoldArcPainter({required this.progress, required this.shimmer, required this.arcColor});
  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startAngle, sweepAngle, false, Paint()
      ..style = PaintingStyle.stroke ..strokeWidth = 12 ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..shader = SweepGradient(
        colors: [arcColor.withOpacity(0), arcColor.withOpacity(0.35), arcColor.withOpacity(0.55)],
        stops: const [0.0, 0.6, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect));
    canvas.drawArc(rect, startAngle, sweepAngle, false, Paint()
      ..style = PaintingStyle.stroke ..strokeWidth = 2.5 ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [arcColor.withOpacity(0.3), arcColor, Color.lerp(arcColor, Colors.white, 0.4)!],
        stops: const [0.0, 0.6, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect));
    final endAngle = startAngle + sweepAngle;
    final dotPos = Offset(center.dx + radius * math.cos(endAngle), center.dy + radius * math.sin(endAngle));
    canvas.drawCircle(dotPos, 5, Paint()..color = arcColor.withOpacity(0.9)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(dotPos, 2.5, Paint()..color = Colors.white.withOpacity(0.95));
  }
  @override
  bool shouldRepaint(_GoldArcPainter old) => old.progress != progress || old.shimmer != shimmer || old.arcColor != arcColor;
}

class _GoldOutlineBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GoldOutlineBtn({required this.label, required this.icon, required this.onTap});
  @override
  State<_GoldOutlineBtn> createState() => _GoldOutlineBtnState();
}

class _GoldOutlineBtnState extends State<_GoldOutlineBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: _pressed ? 0.80 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(colors: [_gold.withOpacity(_pressed ? 0.14 : 0.10), _gold.withOpacity(_pressed ? 0.08 : 0.05)]),
              border: Border.all(color: _gold.withOpacity(0.35), width: 1),
              boxShadow: _pressed ? [] : [BoxShadow(color: _gold.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: _gold.withOpacity(0.80), size: 16),
                const SizedBox(width: 10),
                Text(widget.label, style: TextStyle(color: _gold.withOpacity(0.90), fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}