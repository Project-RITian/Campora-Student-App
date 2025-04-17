import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritian_v1/user_provider.dart';

class CustomNavigationDrawer extends StatelessWidget {
  const CustomNavigationDrawer({super.key});

  static AppBar buildAppBar(BuildContext context, String title) {
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Drawer(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              // Navigate to the profile screen when the header is tapped
              Navigator.pushNamed(context, '/profile');
            },
            child: UserAccountsDrawerHeader(
              accountName: Text(user?.name ?? 'Guest'),
              accountEmail: Text(user?.email ?? 'guest@example.com'),
              currentAccountPicture: const CircleAvatar(
                backgroundImage: NetworkImage(
                  'https://via.placeholder.com/150',
                ),
              ),
              decoration: const BoxDecoration(color: Colors.blue),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.pushNamed(context, '/home');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Apply Leave/OD'),
                  onTap: () {
                    Navigator.pushNamed(context, '/leaveandod');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notes),
                  title: const Text('Assignment Submission'),
                  onTap: () {
                    Navigator.pushNamed(context, '/assignment_submission');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.book),
                  title: const Text('GPA Book'),
                  onTap: () {
                    Navigator.pushNamed(context, '/gpa_book');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text('Class Committee'),
                  onTap: () {
                    Navigator.pushNamed(context, '/class_committee');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.query_builder),
                  title: const Text('Raise a Query'),
                  onTap: () {
                    Navigator.pushNamed(context, '/raise_query');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.credit_card),
                  title: const Text('Apply Certificates'),
                  onTap: () {
                    Navigator.pushNamed(context, '/apply_certificates');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Event Registration'),
                  onTap: () {
                    Navigator.pushNamed(context, '/event_registration');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_snippet),
                  title: const Text('Exam Results'),
                  onTap: () {
                    Navigator.pushNamed(context, '/exam_results');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.currency_rupee),
                  title: const Text('Fee Details'),
                  onTap: () {
                    Navigator.pushNamed(context, '/fee_details');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bus_alert),
                  title: const Text('Bus Tracking'),
                  onTap: () {
                    Navigator.pushNamed(context, '/bus_tracking');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.monetization_on),
                  title: const Text('Buy RITZ'),
                  onTap: () {
                    Navigator.pushNamed(context, '/buy_ritz');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('user_email');
                    Provider.of<UserProvider>(context, listen: false)
                        .clearUser();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
                const Divider(),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Developed by: Null Pointers',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
