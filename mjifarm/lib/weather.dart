import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: WeatherPage(), debugShowCheckedModeBanner: false));
}

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FFFA),
      appBar: AppBar(
        title: const Text('Weather'),
        backgroundColor: Colors.green.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatCard(
                  'Temperature',
                  '24°C',
                  Icons.thermostat,
                  'Feels like 26°C',
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  'Humidity',
                  '65%',
                  Icons.water_drop,
                  'Good for plants',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInsightsSection(),
            const SizedBox(height: 20),
            _buildForecastSection(),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatCard('Wind Speed', '12 km/h', Icons.air, ''),
                const SizedBox(width: 10),
                _buildStatCard('Soil Moisture', '78%', Icons.grass, ''),
              ],
            ),
          ],
        ),
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

  Widget _buildInsightsSection() {
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
          _buildInsightBox(
            'Perfect conditions for watering leafy greens - humidity at optimal 65%',
            Colors.green.shade50,
          ),
          _buildInsightBox(
            'Light winds (12 km/h) ideal for pollination of tomato plants',
            Colors.blue.shade50,
          ),
          _buildInsightBox(
            'UV index at 6 - consider shade cloth for sensitive seedlings',
            Colors.amber.shade50,
          ),
        ],
      ),
    );
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

  Widget _buildForecastSection() {
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
          _buildForecastTile('Today', 'Partly Cloudy', '26°', '18°', '10%'),
          _buildForecastTile('Tomorrow', 'Sunny', '28°', '20°', '5%'),
          _buildForecastTile('Wed', 'Rainy', '23°', '16°', '80%'),
          _buildForecastTile('Thu', 'Cloudy', '25°', '17°', '30%'),
          _buildForecastTile('Fri', 'Sunny', '27°', '19°', '0%'),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Icon(Icons.wb_sunny, color: Colors.orange.shade300),
      title: Text(day, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(condition),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            high,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(low, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            '$rain rain',
            style: const TextStyle(fontSize: 12, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}

class WeatherData {
  final String temperature;
  final String condition;

  WeatherData({required this.temperature, required this.condition});
}

WeatherData getTodayWeatherSummary() {
  // Replace these hardcoded values with actual data retrieval logic if needed
  return WeatherData(temperature: '24°C', condition: 'Partly Cloudy');
}
