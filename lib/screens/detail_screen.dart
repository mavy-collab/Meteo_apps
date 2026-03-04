import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/weather_model.dart';
import '../widgets/sky_atmosphere.dart';

// ─── Constantes de couleur ────────────────────────────────────────────────────
// SkyAtmosphere impose toujours un fond visuel (ciel de jour/nuit/nuageux).
// Les textes doivent donc toujours être BLANCS pour rester lisibles,
// quel que soit le mode clair/sombre du thème Flutter.
const _white      = Colors.white;
const _gold       = Color(0xFFD4AF6E);
const _goldLight  = Color(0xFFF0D080);

Color _txt([double opacity = 1.0])  => _white.withOpacity(opacity);
Color _gold_([double opacity = 1.0]) => _gold.withOpacity(opacity);

class DetailScreen extends StatefulWidget {
  final WeatherModel weather;
  const DetailScreen({super.key, required this.weather});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _openMaps() async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${widget.weather.lat},${widget.weather.lon}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.weather;
    final iconCode = w.icon.replaceAll(RegExp(r'[dn]'), '');

    return Scaffold(
      body: SkyAtmosphere(
        cityLocalHour:   w.localHour,
        cityIsDaytime:   w.isDaytime,
        weatherIconCode: iconCode,
        child: SafeArea(
          child: Column(
            children: [
              // ── Header fixe ────────────────────────────────────────────────
              _FixedHeader(cityName: w.city),

              // ── Contenu scrollable ──────────────────────────────────────────
              Expanded(
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),

                            // ── Eyebrow doré ─────────────────────────────────
                            Row(children: [
                              Container(width: 22, height: 1, color: _gold_(0.70)),
                              const SizedBox(width: 8),
                              Text(
                                'MÉTÉO LOCALE',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: _gold_(0.85),
                                  letterSpacing: 3.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 14),

                            // ── Nom de la ville ───────────────────────────────
                            Text(
                              w.city,
                              style: TextStyle(
                                color: _txt(),
                                fontSize: 38,
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              w.description,
                              style: TextStyle(
                                color: _txt(0.65),
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ── Température immense ───────────────────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  w.temperature.toStringAsFixed(0),
                                  style: TextStyle(
                                    color: _txt(),
                                    fontSize: 100,
                                    fontWeight: FontWeight.w100,
                                    letterSpacing: -5,
                                    height: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 18),
                                  child: Text(
                                    '°C',
                                    style: TextStyle(
                                      color: _txt(),
                                      fontSize: 34,
                                      fontWeight: FontWeight.w200,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // ── Icône météo + feeling ─────────────────────────
                            Row(
                              children: [
                                Image.network(
                                  'https://openweathermap.org/img/wn/${w.icon}@2x.png',
                                  width: 48,
                                  height: 48,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.wb_sunny_rounded,
                                    color: _gold,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _tempFeeling(w.temperature),
                                  style: TextStyle(
                                    color: _txt(0.60),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),

                            // ── Badge heure locale ────────────────────────────
                            const SizedBox(height: 10),
                            _LocalTimeBadge(localHour: w.localHour),

                            // ── Séparateur doré ───────────────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Row(children: [
                                Expanded(child: Divider(color: _gold_(0.25), thickness: 0.5)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('✦',
                                      style: TextStyle(color: _gold_(0.40), fontSize: 9)),
                                ),
                                Expanded(child: Divider(color: _gold_(0.25), thickness: 0.5)),
                              ]),
                            ),

                            // ── Grille infos 2×2 ──────────────────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: _InfoTile(
                                    icon: Icons.water_drop_rounded,
                                    label: 'Humidité',
                                    value: '${w.humidity}%',
                                    iconColor: const Color(0xFF64B5F6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _InfoTile(
                                    icon: Icons.air_rounded,
                                    label: 'Vent',
                                    value: '${w.windSpeed} m/s',
                                    iconColor: const Color(0xFF80CBC4),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _InfoTile(
                                    icon: Icons.my_location_rounded,
                                    label: 'Latitude',
                                    value: w.lat.toStringAsFixed(3),
                                    iconColor: _goldLight,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _InfoTile(
                                    icon: Icons.explore_rounded,
                                    label: 'Longitude',
                                    value: w.lon.toStringAsFixed(3),
                                    iconColor: _goldLight,
                                  ),
                                ),
                              ],
                            ),

                            // ── Bouton Google Maps ────────────────────────────
                            const SizedBox(height: 24),
                            _MapsButton(onTap: _openMaps),
                            const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _tempFeeling(double t) {
    if (t < 0)  return 'Conditions glaciales';
    if (t < 12) return 'Temps froid';
    if (t < 22) return 'Temps agréable';
    if (t < 30) return 'Temps chaud';
    return 'Très forte chaleur';
  }
}

// ─── Header fixe ─────────────────────────────────────────────────────────────
class _FixedHeader extends StatelessWidget {
  final String cityName;
  const _FixedHeader({required this.cityName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                // Toujours semi-transparent blanc : lisible sur n'importe quel ciel
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.30)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Badge heure locale ───────────────────────────────────────────────────────
class _LocalTimeBadge extends StatelessWidget {
  final int localHour;
  const _LocalTimeBadge({required this.localHour});

  @override
  Widget build(BuildContext context) {
    final h = localHour;
    final period = h >= 5 && h < 12
        ? 'Matin'
        : h < 18
            ? 'Après-midi'
            : h < 22
                ? 'Soir'
                : 'Nuit';
    final display = '${h.toString().padLeft(2, '0')}h locales · $period';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withOpacity(0.45)),
      ),
      child: Text(
        display,
        style: TextStyle(
          color: _gold.withOpacity(0.90),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Tuile info ───────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        // Fond toujours sombre semi-transparent → lisible sur le ciel
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  // Label en or pour cohérence luxe
                  color: _gold.withOpacity(0.65),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w200,
              // Valeur toujours blanche : contraste maximal sur fond sombre
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bouton Google Maps ───────────────────────────────────────────────────────
class _MapsButton extends StatefulWidget {
  final VoidCallback onTap;
  const _MapsButton({required this.onTap});

  @override
  State<_MapsButton> createState() => _MapsButtonState();
}

class _MapsButtonState extends State<_MapsButton> {
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
          opacity: _pressed ? 0.80 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              // Dégradé or luxe — cohérent avec HomeScreen
              gradient: LinearGradient(
                colors: [
                  _gold.withOpacity(_pressed ? 0.14 : 0.18),
                  _gold.withOpacity(_pressed ? 0.08 : 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _gold.withOpacity(0.50), width: 1),
              boxShadow: _pressed
                  ? []
                  : [
                      BoxShadow(
                        color: _gold.withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_rounded, color: _gold.withOpacity(0.85), size: 18),
                const SizedBox(width: 10),
                Text(
                  'Voir sur Google Maps',
                  style: TextStyle(
                    // Texte blanc sur fond semi-transparent : toujours lisible
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
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