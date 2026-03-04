class WeatherModel {
  final String city;
  final double temperature;
  final String description;
  final int humidity;
  final double windSpeed;
  final double lat;
  final double lon;
  final String icon;
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

  int get localHour {
    final utcNow = DateTime.now().toUtc();
    final cityTime = utcNow.add(Duration(seconds: timezoneOffset));
    return cityTime.hour;
  }

  bool get isDaytime => icon.endsWith('d');
}
