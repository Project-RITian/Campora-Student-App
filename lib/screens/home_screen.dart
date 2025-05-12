import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_navigation_drawer.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel_slider;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/campus_status_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoadingAnnouncements = true;
  String? _studentClass;

  @override
  void initState() {
    super.initState();
    _fetchStudentClassAndAnnouncements();
  }

  Future<void> _fetchStudentClassAndAnnouncements() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingAnnouncements = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _isLoadingAnnouncements = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not found')),
        );
        return;
      }

      _studentClass = userDoc.data()!['class'] as String?;
      if (_studentClass == null) {
        setState(() {
          _isLoadingAnnouncements = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class not found for user')),
        );
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('timestamp', descending: true)
          .get();

      final filteredAnnouncements = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['viewers'] == 'Students') {
          final announcementClass = data['class'] as String?;
          if (announcementClass == _studentClass ||
              announcementClass == 'All Classes') {
            filteredAnnouncements.add({
              'announcement': data['announcement'] as String,
              'announcer': data['announcer'] as String,
              'class': announcementClass,
              'timestamp': (data['timestamp'] as Timestamp).toDate(),
            });
          }
        } else if (data['viewers'] == 'Everyone') {
          filteredAnnouncements.add({
            'announcement': data['announcement'] as String,
            'announcer': data['announcer'] as String,
            'class': 'Everyone',
            'timestamp': (data['timestamp'] as Timestamp).toDate(),
          });
        }
      }

      setState(() {
        _announcements = filteredAnnouncements;
        _isLoadingAnnouncements = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAnnouncements = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch data: $e')),
      );
    }
  }

  void _showAnnouncementDialog(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Announcement Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  announcement['announcement'],
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'By: ${announcement['announcer']}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'For: ${announcement['class']}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Posted: ${announcement['timestamp'].toString().substring(0, 16)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0C4D83);
    final campusStatus =
        Provider.of<CampusStatusProvider>(context).campusStatus;

    final List<Map<String, dynamic>> quickLinks = [
      {
        'text': 'Time Table',
        'color': Colors.orange,
        'route': '/timetable',
        'icon': FontAwesomeIcons.calendar
      },
      {
        'text': 'Assignments',
        'color': Colors.deepPurpleAccent,
        'route': '/assignment_submission',
        'icon': FontAwesomeIcons.book
      },
      {
        'text': 'GPA Book',
        'color': Colors.blue,
        'route': '/gpa_book',
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
        'route': '/exam_results',
        'icon': FontAwesomeIcons.chartLine
      },
      {
        'text': 'My Purchases',
        'color': Colors.red,
        'route': '/purchase_history',
        'icon': FontAwesomeIcons.history
      },
      {
        'text': 'Bus Tracking',
        'color': Colors.teal,
        'route': '/bus_tracking',
        'icon': FontAwesomeIcons.bus
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
        'route': '/apply_certificates',
        'icon': FontAwesomeIcons.certificate
      },
      {
        'text': 'Raise a Query',
        'color': Colors.amber,
        'route': '/raise_query',
        'icon': FontAwesomeIcons.questionCircle
      },
    ];

    final List<String> carouselItems = [
      'https://ritchennai.org/img/rit-about.jpg',
      'https://ritchennai.org/image/rit_imgs/CoursesOffered/1.jpg',
      'https://content.jdmagicbox.com/v2/comp/chennai/u5/044pxx44.xx44.100223165126.x1u5/catalogue/rajalakshmi-institute-of-technology-thirumazhisai-chennai-engineering-colleges-6ddqz7.jpg',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Home'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: campusStatus == 'In Campus'
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    campusStatus == 'In Campus'
                        ? Icons.location_on
                        : Icons.location_off,
                    color:
                        campusStatus == 'In Campus' ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    campusStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: campusStatus == 'In Campus'
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      drawer: const CustomNavigationDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Announcements',
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
          _isLoadingAnnouncements
              ? const Center(child: CircularProgressIndicator())
              : _announcements.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'No announcements available',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: carousel_slider.CarouselSlider(
                        options: carousel_slider.CarouselOptions(
                          height: 150.0,
                          enlargeCenterPage: true,
                          autoPlay: true,
                          aspectRatio: 16 / 9,
                          autoPlayInterval: const Duration(seconds: 5),
                          viewportFraction: 0.85,
                          autoPlayAnimationDuration:
                              const Duration(milliseconds: 800),
                        ),
                        items: _announcements.map((announcement) {
                          return Builder(
                            builder: (BuildContext context) {
                              return GestureDetector(
                                onTap: () {
                                  _showAnnouncementDialog(announcement);
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        spreadRadius: 1,
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            announcement['announcement'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'By: ${announcement['announcer']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'For: ${announcement['class']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Posted: ${announcement['timestamp'].toString().substring(0, 16)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
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
                                color:
                                    quickLinks[index]['color'].withOpacity(0.3),
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
    );
  }
}
