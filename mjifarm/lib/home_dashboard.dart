import 'package:flutter/material.dart';
import 'newplant.dart'; // Import this
import 'plants.dart'; // Optional if routing directly
import 'weather.dart';
class HomeDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                
                   //if this card is pressed, navigate to the weather page
                  
                  GestureDetector(                                     
                                
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => WeatherPage()),
                      );
                    },
                    child: _buildCard('Weather'),
                  ),


                 
                ],
              ),
              SizedBox(height: 25),

              Text(
                'Hello Tracy,',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text('Tip of the day', style: TextStyle(color: Colors.black54)),
              SizedBox(height: 20),

              // In the Farm
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MyPlantsPage()),
                  );
                },
                child: Row(
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
              ),
              SizedBox(height: 15),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFarmCircle(context, icon: Icons.add, label: 'Add'),
                  ],
                ),
              ),
              SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trending practices',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Icon(Icons.chevron_right),
                ],
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildTrendingCard(
                      'assets/sample1.jpg',
                      'Compost Tips',
                      'Best composting for urban farms',
                    ),
                    _buildTrendingCard(
                      'assets/sample2.jpg',
                      'Irrigation Hacks',
                      'Low-budget watering system',
                    ),
                  ],
                ),
              ),
            ],
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

  Widget _buildFarmCircle(
    BuildContext context, {
    IconData? icon,
    String? image,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {
        if (label == 'Add') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NewPlantPage()),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(right: 15),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              child:
                  icon != null
                      ? Icon(icon, size: 30, color: Colors.black)
                      : image != null && image.isNotEmpty
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
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    height: 100,
                    width: 130,
                    child: Icon(Icons.broken_image),
                  ),
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
