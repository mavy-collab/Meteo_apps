class WeatherModel {
  final String city;
  final double temperature;
  final String description;
  final int humidity;
  final double windSpeed;
  final double lat;
  final double lon;
  final String icon;
  /// Décalage en secondes depuis UTC (fourni par l'API OpenWeather).
  /// Ex : New York = -18000 (UTC-5), Tokyo = 32400 (UTC+9)
  final int timezoneOffset;

  WeatherModel({
    required this.city,
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.lat,
    required this.lon,
    required this.icon,
    required this.timezoneOffset,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      city: json['name'],
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'],
      humidity: json['main']['humidity'],
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      lat: (json['coord']['lat'] as num).toDouble(),
      lon: (json['coord']['lon'] as num).toDouble(),
      icon: json['weather'][0]['icon'],
      timezoneOffset: (json['timezone'] as num).toInt(),
    );
  }

  /// Retourne l'heure locale réelle de la ville (0–23).
  int get localHour {
    final utcNow = DateTime.now().toUtc();
    final cityTime = utcNow.add(Duration(seconds: timezoneOffset));
    return cityTime.hour;
  }

  /// Retourne true si c'est le jour dans la ville (selon l'icône OpenWeather).
  bool get isDaytime => icon.endsWith('d');
}
