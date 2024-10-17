import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyWeatherApp());

class MyWeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final List<String> cities = ['Москва', 'Санкт-Петербург', 'Новосибиирск', 'Екатеринбург', 'Казань'];
  String selectedCity = 'Москва';
  Map<String, dynamic>? weatherData;

  @override
  void initState() {
    super.initState();
    fetchWeather(selectedCity);
  }

  Future<void> fetchWeather(String city) async {
    final Map<String, List<double>> cityCoordinates = {
      'Москва': [55.7558, 37.6173],
      'Санкт-Петербург': [59.9343, 30.3351],
      'Новосибиирск': [55.0084, 82.9357],
      'Екатеринбург': [56.8389, 60.6057],
      'Казань': [55.8304, 49.0661],
    };

    final coords = cityCoordinates[city];
    final String apiUrl = 'https://api.open-meteo.com/v1/forecast?latitude=${coords![0]}&longitude=${coords[1]}&hourly=temperature_2m,precipitation,weathercode&timezone=Europe%2FMoscow';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      setState(() {
        weatherData = json.decode(response.body);
      });
    } else {
      throw Exception('Не удалось загрузить данные о погоде');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Прогноз погоды'),
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            value: selectedCity,
            onChanged: (String? newCity) {
              setState(() {
                selectedCity = newCity!;
                fetchWeather(selectedCity);
              });
            },
            items: cities.map<DropdownMenuItem<String>>((String city) {
              return DropdownMenuItem<String>(
                value: city,
                child: Text(city),
              );
            }).toList(),
          ),
          if (weatherData != null)
            Expanded(
              child: WeatherForecast(weatherData: weatherData!),
            )
          else
            Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class WeatherForecast extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  WeatherForecast({required this.weatherData});


  String getFormattedDate(DateTime date) {
    const List<String> daysOfWeek = [
      'Октября Воскресенье', 'Октября Понедельник', 'Октября Вторник', 'Октября Среда', 'Октября Четверг', 'Октября Пятница', 'Октября Суббота'
    ];
    String dayOfWeek = daysOfWeek[date.weekday % 7];
    return '${date.day} $dayOfWeek'; 
  }

  String getWeatherIcon(int code) {
    switch (code) {
      case 0:
        return '☀️'; // Ясно
      case 1:
      case 2:
        return '🌤️'; // Малооблачно
      case 3:
        return '☁️'; // Облачно
      case 45:
      case 48:
        return '🌫️'; // Туман
      case 51:
      case 53:
      case 55:
        return '🌧️'; // Дождь
      case 61:
      case 63:
      case 65:
        return '🌧️'; // Ливень
      case 71:
      case 73:
      case 75:
        return '🌨️'; // Снег
      case 80:
      case 81:
      case 82:
        return '🌧️'; // Ливень
      default:
        return '🌧️'; // Неизвестно
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> temperatures = weatherData['hourly']['temperature_2m'];
    final List<dynamic> weatherCodes = weatherData['hourly']['weathercode'];
    final List<dynamic> times = weatherData['hourly']['time'];

    
    Map<String, List<Widget>> dailyForecasts = {};

    for (int i = 0; i < temperatures.length; i++) {
      final dateTime = DateTime.parse(times[i]);
      final formattedDate = getFormattedDate(dateTime); 
      final temperature = temperatures[i].round(); 
      final weatherIcon = getWeatherIcon(weatherCodes[i]);

      final forecastTile = ListTile(
        title: Text(
          '${dateTime.hour}:00 - $weatherIcon $temperature°C',
          style: TextStyle(fontSize: 18),
        ),
      );

      if (dailyForecasts.containsKey(formattedDate)) {
        dailyForecasts[formattedDate]!.add(forecastTile);
      } else {
        dailyForecasts[formattedDate] = [forecastTile];
      }
    }

    
    return ListView(
      children: dailyForecasts.entries.map((entry) {
        return ExpansionTile(
          title: Text(
            entry.key, 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          children: entry.value, 
        );
      }).toList(),
    );
  }
}
