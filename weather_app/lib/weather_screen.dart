// ignore_for_file: avoid_print, library_private_types_in_public_api

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:weather_app/color_const.dart';
import 'weather_provider.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  TextEditingController cityController = TextEditingController();
  List<String> cityNames = [];
  String selectedCity = '';

  @override
  void initState() {
    super.initState();
    loadCityNames();
  }

  Future<void> loadCityNames() async {
    try {
      String citiesJson = await rootBundle.loadString('assets/cities.json');
      List<dynamic> citiesList = jsonDecode(citiesJson);
      List<String> names =
          citiesList.map((city) => city['name'] as String).toList();
      setState(() {
        cityNames = names;
      });
    } catch (e) {
      print('Error loading city names: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorConstants.blue1,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: () {
              if (selectedCity.isNotEmpty) {
                _refreshWeather(context, weatherProvider, selectedCity);
              }
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: ColorConstants.linearGradientColor,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter)),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                selectedCity.isEmpty ? 'Select a City' : selectedCity,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return cityNames.where((String option) {
                          return option
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        setState(() {
                          selectedCity = selection;
                        });
                        cityController.text = selection;
                        weatherProvider.addCity(selection).then((_) {
                          cityController.clear();
                        }).catchError((e) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Error'),
                                content: Text(e.toString()),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        });
                      },
                      fieldViewBuilder: (BuildContext context,
                          TextEditingController textEditingController,
                          FocusNode focusNode,
                          VoidCallback onFieldSubmitted) {
                        cityController = textEditingController;
                        return TextField(
                          controller: cityController,
                          focusNode: focusNode,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                              labelText: 'Enter city',
                              labelStyle: TextStyle(color: Colors.white)),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      final city = cityController.text;
                      setState(() {
                        selectedCity = city;
                      });
                      weatherProvider.addCity(city).then((_) {
                        cityController.clear();
                      }).catchError((e) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Error'),
                              content: Text(e.toString()),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      });
                    },
                  ),
                ],
              ),
              Expanded(
                child: weatherProvider.weatherData.containsKey(selectedCity)
                    ? WeatherDetails(weatherProvider.weatherData[selectedCity])
                    : const Center(child: Text('No weather data available')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _refreshWeather(
      BuildContext context, WeatherProvider weatherProvider, String city) {
    weatherProvider.fetchWeather(city).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weather data updated'),
        ),
      );
    }).catchError((e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }
}

class WeatherDetails extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const WeatherDetails(this.weatherData, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.thermostat, size: 44, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              '${weatherData['temp']} °C',
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud, size: 44, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              '${weatherData['condition']}',
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.water, size: 44, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              '${weatherData['humidity']}%',
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.air, size: 44, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              '${weatherData['windSpeed']} m/s',
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}
