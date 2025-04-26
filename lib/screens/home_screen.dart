import 'package:flutter/material.dart';
import '../widgets/custom_navigation_drawer.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel_slider;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define primary color
    const Color primaryColor = Color(0xFF0C4D83);

    // List of navigation options with colors, icons, and routes
    final List<Map<String, dynamic>> quickLinks = [
      {
        'text': 'Time Table',
        'color': Colors.orange,
        'route': '/under-construction',
        'icon': FontAwesomeIcons.calendar
      },
      {
        'text': 'Assignments',
        'color': Colors.deepPurpleAccent,
        'route': '/under-construction',
        'icon': FontAwesomeIcons.book
      },
      {
        'text': 'GPA Book',
        'color': Colors.blue,
        'route': '/under-construction',
        'icon': FontAwesomeIcons.graduationCap
      },
      {
        'text': 'Attendance',
        'color': Colors.green,
        'route': '/under-construction',
        'icon': FontAwesomeIcons.checkSquare
      },
      {
        'text': 'CAT Results',
        'color': Colors.red,
        'route': '/details',
        'icon': FontAwesomeIcons.chartLine
      },
      {
        'text': 'My Purchases',
        'color': Colors.red,
        'route': '/purchase_history',
        'icon': FontAwesomeIcons.history
      },
    ];

    final List<Map<String, dynamic>> resourcesManagement = [
      {
        'text': 'Canteen',
        'color': Colors.teal,
        'route': '/canteen',
        'icon': FontAwesomeIcons.utensils
      },
      {
        'text': 'Arcade',
        'color': Colors.deepPurple,
        'route': '/arcade',
        'icon': FontAwesomeIcons.gamepad
      },
      {
        'text': 'Contact',
        'color': Colors.lightGreen,
        'route': '/settings',
        'icon': FontAwesomeIcons.addressBook
      },
      {
        'text': 'Check Balance',
        'color': Colors.amber,
        'route': '/buy_ritz',
        'icon': FontAwesomeIcons.wallet
      },
    ];

    final List<Map<String, dynamic>> applicationsLink = [
      {
        'text': 'Apply Leave / OD',
        'color': Colors.teal,
        'route': '/leaveandod',
        'icon': FontAwesomeIcons.suitcase
      },
      {
        'text': 'Event Registration',
        'color': Colors.deepPurple,
        'route': '/event_registration',
        'icon': FontAwesomeIcons.ticket
      },
      {
        'text': 'Apply Certificates',
        'color': Colors.lightGreen,
        'route': '/under-construction',
        'icon': FontAwesomeIcons.certificate
      },
      {
        'text': 'Raise a Query',
        'color': Colors.amber,
        'route': '/under-construction',
        'icon': FontAwesomeIcons.questionCircle
      },
    ];

    // List of carousel items
    final List<String> carouselItems = [
      'https://ritchennai.org/img/rit-about.jpg',
      'https://ritchennai.org/image/rit_imgs/CoursesOffered/1.jpg',
      'https://content.jdmagicbox.com/v2/comp/chennai/u5/044pxx44.xx44.100223165126.x1u5/catalogue/rajalakshmi-institute-of-technology-thirumazhisai-chennai-engineering-colleges-6ddqz7.jpg',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        elevation: 0,
        // flexibleSpace: Container(
        //   decoration: BoxDecoration(
        //     gradient: LinearGradient(
        //       colors: [primaryColor, const Color(0xFF3B82F6)],
        //       begin: Alignment.topLeft,
        //       end: Alignment.bottomRight,
        //     ),
        //   ),
        // ),
      ),
      drawer: const CustomNavigationDrawer(),
      body: Container(
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     colors: [
        //       Colors.blue[50]!,
        //       Colors.purple[50]!,
        //       Colors.pink[50]!,
        //     ],
        //     begin: Alignment.topCenter,
        //     end: Alignment.bottomCenter,
        //   ),
        // ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Carousel at the top
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                // gradient: LinearGradient(
                //   colors: [Colors.blue[100]!, Colors.purple[100]!],
                //   begin: Alignment.topLeft,
                //   end: Alignment.bottomRight,
                // ),
                // border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: carousel_slider.CarouselSlider(
                options: carousel_slider.CarouselOptions(
                  height: 200.0,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  aspectRatio: 16 / 9,
                  autoPlayInterval: const Duration(seconds: 3),
                  viewportFraction: 0.85,
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                ),
                items: carouselItems.map((item) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15.0),
                          child: Image.network(
                            item,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: primaryColor,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey[200],
                              child: const Center(
                                  child: Text('Image failed to load')),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            // Quick Links Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Links',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Container(
                    height: 3,
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, Colors.blue[300]!],
                      ),
                    ),
                    margin: const EdgeInsets.only(top: 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Row 1: Colorful Scrollable Cards
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: quickLinks.length,
                itemBuilder: (context, index) {
                  return AnimatedOpacity(
                    opacity: 1.0,
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                              context, quickLinks[index]['route']);
                        },
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 1.0, end: 1.0),
                          duration: const Duration(milliseconds: 200),
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  quickLinks[index]['color'].withOpacity(0.9),
                                  quickLinks[index]['color'].withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: quickLinks[index]['color']
                                      .withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  quickLinks[index]['icon'],
                                  color: Colors.white,
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  quickLinks[index]['text'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Resources Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resources',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Container(
                    height: 3,
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, Colors.blue[300]!],
                      ),
                    ),
                    margin: const EdgeInsets.only(top: 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Row 2: Colorful Scrollable Cards
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: resourcesManagement.length,
                itemBuilder: (context, index) {
                  return AnimatedOpacity(
                    opacity: 1.0,
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                              context, resourcesManagement[index]['route']);
                        },
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 1.0, end: 1.0),
                          duration: const Duration(milliseconds: 200),
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  resourcesManagement[index]['color']
                                      .withOpacity(0.9),
                                  resourcesManagement[index]['color']
                                      .withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: resourcesManagement[index]['color']
                                      .withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  resourcesManagement[index]['icon'],
                                  color: Colors.white,
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  resourcesManagement[index]['text'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Applications Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Applications',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Container(
                    height: 3,
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, Colors.blue[300]!],
                      ),
                    ),
                    margin: const EdgeInsets.only(top: 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Row 3: Colorful Scrollable Cards
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: applicationsLink.length,
                itemBuilder: (context, index) {
                  return AnimatedOpacity(
                    opacity: 1.0,
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                              context, applicationsLink[index]['route']);
                        },
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 1.0, end: 1.0),
                          duration: const Duration(milliseconds: 200),
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  applicationsLink[index]['color']
                                      .withOpacity(0.9),
                                  applicationsLink[index]['color']
                                      .withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: applicationsLink[index]['color']
                                      .withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  applicationsLink[index]['icon'],
                                  color: Colors.white,
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  applicationsLink[index]['text'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
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
