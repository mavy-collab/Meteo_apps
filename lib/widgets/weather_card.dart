import 'package:flutter/material.dart';
import '../models/weather_model.dart';

// helper to pick contrasting foreground color depending on theme
Color _onBg(BuildContext context, [double opacity = 1]) =>
    Theme.of(context).colorScheme.onBackground.withOpacity(opacity);


class WeatherCard extends StatelessWidget {
  final WeatherModel weather;
  final VoidCallback onTap;

  const WeatherCard({
    super.key,
    required this.weather,
    required this.onTap,
  });

  // Couleur d'accent selon la température (Apple-like)
  Color _accentColor(double t) {
    if (t < 0) return const Color(0xFF90CAF9);
    if (t < 12) return const Color(0xFF64B5F6);
    if (t < 22) return const Color(0xFF4FC3F7);
    if (t < 30) return const Color(0xFFFFB74D);
    return const Color(0xFFEF9A9A);
  }

  String _tempFeeling(double t) {
    if (t < 0) return 'Glacial';
    if (t < 12) return 'Froid';
    if (t < 22) return 'Agréable';
    if (t < 30) return 'Chaud';
    return 'Très chaud';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(weather.temperature);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        decoration: BoxDecoration(
          color: _onBg(context, 0.22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _onBg(context, 0.30),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icône météo
            Image.network(
              'https://openweathermap.org/img/wn/${weather.icon}@2x.png',
              width: 56,
              height: 56,
              errorBuilder: (_, _, _) {
                return Icon(Icons.wb_cloudy_rounded,
                    size: 44, color: _onBg(context, 0.7));
              },
            ),

            const SizedBox(width: 10),

            // Infos texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather.city,
                    style: TextStyle(
                      color: _onBg(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    weather.description,
                    style: TextStyle(
                      color: _onBg(context, 0.65),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MiniStat(
                        icon: Icons.water_drop_rounded,
                        label: '${weather.humidity}%',
                        color: Colors.lightBlueAccent,
                      ),
                      const SizedBox(width: 12),
                      _MiniStat(
                        icon: Icons.air_rounded,
                        label: '${weather.windSpeed} m/s',
                        color: Colors.tealAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Température (grand, à droite — style Apple)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${weather.temperature.toStringAsFixed(0)}°',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w200,
                    color: accent,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _tempFeeling(weather.temperature),
                  style: TextStyle(
                    fontSize: 11,
                    color: accent.withValues(alpha: 0.80),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _onBg(context, 0.35),
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color.withValues(alpha: 0.80)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _onBg(context, 0.55),
          ),
        ),
      ],
    );
  }
}
