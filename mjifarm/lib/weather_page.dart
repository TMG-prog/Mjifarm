import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; //  needed for Image.network
import 'dart:math'; //  needed for max/min in forecast calculation
import 'package:mjifarm/weather.dart'; 



// Changed back to StatelessWidget
class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});


  Icon _getWeatherIcon(String condition) {
    if (condition.toLowerCase().contains('clear') ||
        condition.toLowerCase().contains('sunny')) {
      return Icon(Icons.wb_sunny, color: Colors.orange.shade300);
    } else if (condition.toLowerCase().contains('cloud')) {
      return Icon(Icons.cloud, color: Colors.grey.shade500);
    } else if (condition.toLowerCase().contains('rain')) {
      return Icon(Icons.cloudy_snowing, color: Colors.blue.shade500);
    } else if (condition.toLowerCase().contains('storm') ||
        condition.toLowerCase().contains('thunder')) {
      return Icon(Icons.thunderstorm, color: Colors.indigo.shade500);
    }
    return Icon(Icons.cloud_queue, color: Colors.grey); // Default
  }

  
  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFFA),
      appBar: AppBar(
        title: const Text('Weather'),
        backgroundColor: Colors.green.shade800,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchCurrentWeatherData(), // Fetch current weather
        builder: (context, currentSnapshot) {
          if (currentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (currentSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading current weather: ${currentSnapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          }
          if (!currentSnapshot.hasData || currentSnapshot.data == null) {
            return const Center(
              child: Text('No current weather data available.'),
            );
          }

          final weatherData = currentSnapshot.data!;

          // Extract current weather details
          final String currentTemp =
              (weatherData['main']?['temp'] as num?)?.round()?.toString() ??
              'N/A';
          final String feelsLikeTemp =
              (weatherData['main']?['feels_like'] as num?)
                  ?.round()
                  ?.toString() ??
              'N/A';
          final String humidity =
              (weatherData['main']?['humidity'] as num?)?.round()?.toString() ??
              'N/A';
          final String windSpeed =
              ((weatherData['wind']?['speed'] as num?) != null
                  ? (weatherData['wind']['speed']! * 3.6).round().toString()
                  : 'N/A'); // m/s to km/h
          final String weatherDescription =
              weatherData['weather']?[0]?['description'] ?? 'N/A';
          final String city = weatherData['name'] ?? 'N/A';
          final String? iconCode = weatherData['weather']?[0]?['icon'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Weather Overview
                Center(
                  child: Column(
                    children: [
                      Text(
                        city,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        weatherDescription,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '$currentTemp°C',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (iconCode != null)
                        Image.network(
                          'http://openweathermap.org/img/wn/$iconCode@2x.png',
                          width: 80,
                          height: 80,
                        ),
                      Text(
                        'Feels like ${feelsLikeTemp}°C',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _buildStatCard(
                      'Humidity',
                      '$humidity%',
                      Icons.water_drop,
                      '',
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      'Wind Speed',
                      '$windSpeed km/h',
                      Icons.air,
                      '',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInsightsSection(
                  weatherData,
                ), // Pass current weather data to insights
                const SizedBox(height: 20),
                // Forecast section
                FutureBuilder<Map<String, dynamic>>(
                  future: fetchForecastData(), // Fetch forecast data
                  builder: (context, forecastSnapshot) {
                    if (forecastSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (forecastSnapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Error loading forecast: ${forecastSnapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    if (!forecastSnapshot.hasData ||
                        forecastSnapshot.data == null) {
                      return const Center(
                        child: Text('No forecast data available.'),
                      );
                    }
                    return _buildForecastSection(forecastSnapshot.data!);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.share), label: 'Share'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    String subText,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.green.shade800, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(title, style: TextStyle(color: Colors.grey[700])),
            if (subText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  subText,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

 
  List<String> _generateFarmingInsights(Map<String, dynamic> weatherData) {
    List<String> insights = [];
    

    final currentTemp = (weatherData['main']?['temp'] as num?)?.round();
    final humidity = (weatherData['main']?['humidity'] as num?)?.round();
    final windSpeedMps =
        (weatherData['wind']?['speed'] as num?)?.toDouble(); // m/s
    final windSpeedKmH =
        windSpeedMps != null ? (windSpeedMps * 3.6).round() : null;
    final weatherCondition =
        weatherData['weather']?[0]?['main']
            ?.toLowerCase(); // e.g., "clouds", "clear", "rain"
    final weatherDescription =
        weatherData['weather']?[0]?['description']?.toLowerCase();

    // Temperature-based insights
    if (currentTemp != null) {
      if (currentTemp > 30) {
        insights.add(
          'High temperatures (${currentTemp}°C) expected. Ensure plants are well-watered and consider afternoon shading for sensitive crops.',
        );
      } else if (currentTemp < 10) {
        insights.add(
          'Low temperatures (${currentTemp}°C) detected. Protect young plants from frost and cold stress.',
        );
      } else if (currentTemp >= 20 && currentTemp <= 28) {
        insights.add(
          'Optimal temperatures (${currentTemp}°C) for most common crops, supporting healthy growth.',
        );
      }
    }

    // Humidity-based insights
    if (humidity != null) {
      if (humidity > 80) {
        insights.add(
          'High humidity (${humidity}%) increases risk of fungal diseases. Ensure good air circulation around plants.',
        );
      } else if (humidity < 40) {
        insights.add(
          'Low humidity (${humidity}%) can lead to increased water demand. Monitor soil moisture closely.',
        );
      } else if (humidity >= 50 && humidity <= 70) {
        insights.add(
          'Ideal humidity (${humidity}%) for many crops, promoting efficient transpiration.',
        );
      }
    }

    // Wind-based insights
    if (windSpeedKmH != null) {
      if (windSpeedKmH > 25) {
        insights.add(
          'Strong winds (${windSpeedKmH} km/h) today. Secure taller plants and consider windbreaks for protection.',
        );
      } else if (windSpeedKmH <= 10) {
        insights.add(
          'Light winds (${windSpeedKmH} km/h) are perfect for natural pollination and avoiding plant stress.',
        );
      }
    }

    // Precipitation-based insights (from current weather condition)
    if (weatherCondition != null) {
      if (weatherCondition.contains('rain') ||
          weatherDescription.contains('rain')) {
        insights.add(
          'Rainfall expected. Check drainage systems and consider pausing irrigation.',
        );
      } else if (weatherCondition.contains('clear') ||
          weatherCondition.contains('sunny')) {
        insights.add(
          'Clear skies and sun today. Maximize sunlight exposure for plants that love full sun.',
        );
      }
    }

    // Fallback if no specific insights match
    if (insights.isEmpty) {
      insights.add(
        'Current weather conditions are generally stable for farming activities.',
      );
    }

    return insights;
  }

  Widget _buildInsightBox(String text, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
      ),
    );
  }

  Widget _buildInsightsSection(Map<String, dynamic> weatherData) {
    final insights = _generateFarmingInsights(
      weatherData,
    ); // Pass weatherData to generator

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Farming Insights',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...insights.map((insightText) {
            Color bgColor;
            if (insightText.toLowerCase().contains('optimal') ||
                insightText.toLowerCase().contains('perfect') ||
                insightText.toLowerCase().contains('ideal')) {
              bgColor = Colors.green.shade50;
            } else if (insightText.toLowerCase().contains('high temp') ||
                insightText.toLowerCase().contains('low temp') ||
                insightText.toLowerCase().contains('strong winds') ||
                insightText.toLowerCase().contains('risk') ||
                insightText.toLowerCase().contains('consider')) {
              bgColor = Colors.orange.shade50;
            } else {
              bgColor = Colors.blue.shade50;
            }
            return _buildInsightBox(insightText, bgColor);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildForecastSection(Map<String, dynamic> forecastData) {
    if (forecastData['list'] == null) {
      return const SizedBox.shrink();
    }

    final Map<String, List<Map<String, dynamic>>> dailyForecasts = {};
    for (var item in forecastData['list']) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final day = _getWeekday(dateTime.weekday);
      if (!dailyForecasts.containsKey(day)) {
        dailyForecasts[day] = [];
      }
      dailyForecasts[day]?.add(item);
    }

    final List<String> orderedDays = [];
    for (int i = 0; i < 5; i++) {
      final day = _getWeekday(DateTime.now().add(Duration(days: i)).weekday);
      orderedDays.add(day);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '5-Day Forecast',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...orderedDays.map((day) {
            final forecastsForDay = dailyForecasts[day];
            if (forecastsForDay == null || forecastsForDay.isEmpty) {
              return const SizedBox.shrink();
            }
            double maxTemp = -double.infinity;
            double minTemp = double.infinity;
            String mainCondition = '';
            int totalRainProbability = 0;
            int count = 0;

            for (var f in forecastsForDay) {
              final tempMax = (f['main']?['temp_max'] as num?)?.toDouble();
              final tempMin = (f['main']?['temp_min'] as num?)?.toDouble();
              final pop = (f['pop'] as num?)?.toDouble();

              if (tempMax != null) maxTemp = max(maxTemp, tempMax);
              if (tempMin != null) minTemp = min(minTemp, tempMin);
              if (pop != null) totalRainProbability += (pop * 100).round();
              count++;
            }

            if (forecastsForDay.isNotEmpty) {
              mainCondition =
                  forecastsForDay[0]['weather']?[0]?['description'] ?? 'N/A';
            }

            return _buildForecastTile(
              day,
              mainCondition,
              '${maxTemp.round()}°',
              '${minTemp.round()}°',
              '${count > 0 ? (totalRainProbability ~/ count) : 0}%',
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildForecastTile(
    String day,
    String condition,
    String high,
    String low,
    String rain,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      leading: _getWeatherIcon(condition),
      dense: true, 
      title: Text(
        day,
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(condition, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        // This is the column that holds high/low/rain info
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize:
            MainAxisSize
                .min, // Ensure the column takes minimum horizontal space
        children: [
          Text(
            // COMBINED HIGH AND LOW TEMPERATURES ON ONE LINE
            '$high / $low',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ), 
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(
            height: 2,
          ), 
          Text(
            '$rain rain',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
            ), 
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
