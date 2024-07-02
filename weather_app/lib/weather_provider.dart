import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherProvider with ChangeNotifier {
  final List<String> _cities = [];
  final Map<String, dynamic> _weatherData = {};

  List<String> get cities => _cities;
  Map<String, dynamic> get weatherData => _weatherData;

  Future<void> addCity(String city) async {
    if (!_cities.contains(city)) {
      _cities.add(city);
      try {
        await fetchWeather(city);
      } catch (e) {
        _cities.remove(city);
        throw e;
      }
      notifyListeners();
    }
  }

  void removeCity(String city) {
    _cities.remove(city);
    _weatherData.remove(city);
    notifyListeners();
  }

  Future<void> fetchWeather(String city) async {
    final apiKey = '37ccc71e7b1faadce91b36dc9ee88d54';
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _weatherData[city] = {
        'temp': data['main']['temp'],
        'condition': data['weather'][0]['description'],
        'icon': data['weather'][0]['icon'],
        'humidity': data['main']['humidity'],
        'windSpeed': data['wind']['speed'],
      };
      notifyListeners();
    } else {
      final errorData = json.decode(response.body);
      final errorMessage =
          errorData['message'] ?? 'Failed to load weather data';
      throw Exception('Error fetching weather for $city: $errorMessage');
    }
  }
}
