import 'package:flutter/material.dart';
import '../widgets/custom_navigation_drawer.dart';
import 'package:carousel_slider/carousel_slider.dart'
    as carousel_slider; // Alias to avoid conflict

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // List of navigation options with colors and destinations
    final List<Map<String, dynamic>> quickLinks = [
      {'text': 'Time Table', 'color': Colors.orange, 'route': '/under-construction'},
      {'text': 'Assignments', 'color': Colors.deepPurpleAccent, 'route': '/under-construction'},
      {'text': 'GPA Book', 'color': Colors.blue, 'route': '/under-construction'},
      {'text': 'Attendance', 'color': Colors.green, 'route': '/under-construction'},
      {'text': 'CAT Results', 'color': Colors.red, 'route': '/details'},
    ];

    final List<Map<String, dynamic>> resourcesManagement = [
      {'text': 'Canteen', 'color': Colors.teal, 'route': '/canteen'},
      {'text': 'Arcade', 'color': Colors.deepPurple, 'route': '/arcade'},
      {'text': 'Contact', 'color': Colors.lightGreen, 'route': '/settings'},
      {'text': 'Check Balance', 'color': Colors.amber, 'route': '/under-construction'},
    ];

    final List<Map<String, dynamic>> applicationsLink = [
      {'text': 'Apply Leave / OD', 'color': Colors.teal, 'route': '/leaveandod'},
      {'text': 'Event Registration', 'color': Colors.deepPurple, 'route': '/event_registration'},
      {'text': 'Apply Certificates', 'color': Colors.lightGreen, 'route': '/under-construction'},
      {'text': 'Raise a Query', 'color': Colors.amber, 'route': '/under-construction'},
    ];

    // List of carousel items (e.g., image URLs or widgets)
    final List<String> carouselItems = [
      'https://via.placeholder.com/600x200.png?text=Slide+1',
      'https://via.placeholder.com/600x200.png?text=Slide+2',
      'https://via.placeholder.com/600x200.png?text=Slide+3',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      drawer: const CustomNavigationDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          // Carousel at the top
          carousel_slider.CarouselSlider(
            // Use the aliased CarouselSlider
            options: carousel_slider.CarouselOptions(
              height: 200.0,
              enlargeCenterPage: true,
              autoPlay: true,
              aspectRatio: 16 / 9,
              autoPlayInterval: const Duration(seconds: 3),
            ),
            items: carouselItems.map((item) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Image.network(
                      item,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Text('Image failed to load')),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 5),
          const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Quick Links',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
          ),// Space between carousel and cards
          // Row 1: Scrollable Cards
          SizedBox(
            height: 120, // Fixed height for each row
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: quickLinks.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                          context, quickLinks[index]['route']);
                    },
                    child: Card(
                      color: quickLinks[index]['color'],
                      child: Container(
                        width: 150,
                        alignment: Alignment.center,
                        child: Text(
                          quickLinks[index]['text'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 5),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Resources',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          // Row 2: Additional Scrollable Cards
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: resourcesManagement.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                          context, resourcesManagement[index]['route']);
                    },
                    child: Card(
                      color:
                          resourcesManagement[(index + 1) % resourcesManagement.length]
                              ['color'],
                      child: Container(
                        width: 150,
                        alignment: Alignment.center,
                        child: Text(
                          resourcesManagement[index]['text'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 5),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Applications',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
   // Spacer between rows
          // Row 2: Additional Scrollable Cards
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: applicationsLink.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                          context, applicationsLink[index]['route']);
                    },
                    child: Card(
                      color: applicationsLink[
                          (index + 1) % applicationsLink.length]['color'],
                      child: Container(
                        width: 150,
                        alignment: Alignment.center,
                        child: Text(
                          applicationsLink[index]['text'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// DetailsScreen remains unchanged
class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      drawer: const CustomNavigationDrawer(),
      body: const Center(child: Text('Details Screen Content')),
    );
  }
}
