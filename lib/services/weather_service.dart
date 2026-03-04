import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

// Service météo pour récupérer les données depuis l'API OpenWeatherMap
class WeatherService {
  static const String apiKey = '86320a56b72a502cece76f844097f434';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
// La méthode fetchWeather renvoie un WeatherModel pour une ville donnée
  Future<WeatherModel> fetchWeather(String city) async {
    final url = '$baseUrl?q=$city&appid=$apiKey&units=metric&lang=fr';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Impossible de charger la météo pour $city');
    }
  }
}
