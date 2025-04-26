import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritian_v1/user_provider.dart';
import 'package:ritian_v1/widgets/custom_navigation_drawer.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    Provider.of<UserProvider>(context, listen: false).clearUser();
    await fb_auth.FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = fb_auth.FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: CustomNavigationDrawer.buildAppBar(context, 'Profile'),
        drawer: const CustomNavigationDrawer(),
        body: const Center(child: Text('Please log in to view profile')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: CustomNavigationDrawer.buildAppBar(context, 'Profile'),
            drawer: const CustomNavigationDrawer(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (userSnapshot.hasError) {
          return Scaffold(
            appBar: CustomNavigationDrawer.buildAppBar(context, 'Profile'),
            drawer: const CustomNavigationDrawer(),
            body: const Center(child: Text('Error loading profile data')),
          );
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return Scaffold(
            appBar: CustomNavigationDrawer.buildAppBar(context, 'Profile'),
            drawer: const CustomNavigationDrawer(),
            body: const Center(child: Text('Profile data not found')),
          );
        }

        // Update UserProvider with Firestore user data
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUserFromJson({
          'email': userData['email'] ?? '',
          'name': userData['name'] ?? 'User',
          'department': userData['department'] ?? '',
          'class': userData['class'] ?? '',
          'year': userData['year'] ?? '',
          'regdNumber': userData['regdNumber'] ?? '',
        });

        final appUser = userProvider.user;

        // Fetch RITZ balance
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('user_balances')
              .doc(user.uid)
              .snapshots(),
          builder: (context, balanceSnapshot) {
            double ritzBalance = 0.0;
            if (balanceSnapshot.hasData && balanceSnapshot.data!.exists) {
              ritzBalance =
                  (balanceSnapshot.data!['balance'] as num?)?.toDouble() ?? 0.0;
            }

            return Scaffold(
              appBar: CustomNavigationDrawer.buildAppBar(context, 'Profile'),
              drawer: const CustomNavigationDrawer(),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              radius: 60,
                              backgroundImage: NetworkImage(
                                  'https://via.placeholder.com/150'),
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, size: 60),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              appUser?.name ?? 'User',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildProfileItem(
                              context,
                              icon: Icons.badge,
                              label: 'Registration Number',
                              value: appUser?.regdNumber ?? 'N/A',
                            ),
                            _buildProfileItem(
                              context,
                              icon: Icons.class_,
                              label: 'Class',
                              value: appUser?.className ?? 'N/A',
                            ),
                            _buildProfileItem(
                              context,
                              icon: Icons.school,
                              label: 'Department',
                              value: appUser?.department ?? 'N/A',
                            ),
                            _buildProfileItem(
                              context,
                              icon: Icons.calendar_today,
                              label: 'Year',
                              value: appUser?.year ?? 'N/A',
                            ),
                            _buildProfileItem(
                              context,
                              icon: Icons.monetization_on,
                              label: 'RITZ Balance',
                              value: '$ritzBalance RITZ',
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _logout(context),
                              icon: const Icon(Icons.logout),
                              label: const Text('Logout'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
