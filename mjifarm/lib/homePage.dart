import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.black45,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Pending tasks and weather alerts
                Row(
                  children: [
                    _buildCard('Pending task'),
                    _buildCard('Alert weather/\nbreakouts'),
                  ],
                ),
                SizedBox(height: 25),

                // Hello & Tip
                Text(
                  'Hello Tracy,',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text('Tip of the day', style: TextStyle(color: Colors.black54)),
                SizedBox(height: 20),

                // In the Farm title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'In the Farm',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
                SizedBox(height: 15),

                // In the Farm list
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFarmCircle(icon: Icons.add, label: ''),
                      _buildFarmCircle(
                        image: 'assets/watermelon.png',
                        label: 'Plant',
                      ),
                      _buildFarmCircle(
                        image: 'assets/watermelon.png',
                        label: 'Plant',
                      ),
                      _buildFarmCircle(
                        image: 'assets/watermelon.png',
                        label: 'Plant',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 25),

                // Trending Practices
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trending practices',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
                SizedBox(height: 10),

                // Trending horizontal articles
                SizedBox(
                  height: 180,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildTrendingCard(
                        'assets/radish.jpg',
                        'Brand',
                        'article',
                      ),
                      _buildTrendingCard(
                        'assets/mushrooms.jpg',
                        'Brand',
                        'article',
                      ),
                      _buildTrendingCard(
                        'assets/peppers.jpg',
                        'Brand',
                        'article',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xffb0e8b2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(child: Text(title, textAlign: TextAlign.center)),
    );
  }

  Widget _buildFarmCircle({
    IconData? icon,
    String? image,
    required String label,
  }) {
    return Container(
      margin: EdgeInsets.only(right: 15),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[200],
            child:
                icon != null
                    ? Icon(icon, size: 30, color: Colors.black)
                    : image != null
                    ? ClipOval(
                      child: Image.asset(
                        image,
                        fit: BoxFit.cover,
                        height: 60,
                        width: 60,
                      ),
                    )
                    : null,
          ),
          SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(String image, String brand, String label) {
    return Container(
      width: 130,
      margin: EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              image,
              height: 100,
              width: 130,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 5),
          Text(brand, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
