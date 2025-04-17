import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritian_v1/user_provider.dart';
import 'package:ritian_v1/widgets/custom_navigation_drawer.dart';
import 'package:ritian_v1/screens/payment_screen.dart' show UserBalance;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    Provider.of<UserProvider>(context, listen: false).clearUser();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    const String profilePictureUrl = 'https://via.placeholder.com/150';
    const String registrationNumber = 'RA123456789';
    final double ritzBalance = UserBalance.balance;

    return Scaffold(
      appBar: CustomNavigationDrawer.buildAppBar(context, 'Profile'),
      drawer: const CustomNavigationDrawer(),
      body: user == null
          ? const Center(child: Text('Please log in to view profile'))
          : SingleChildScrollView(
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
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(profilePictureUrl),
                            backgroundColor: Colors.grey.shade200,
                            child: profilePictureUrl.isEmpty
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.name,
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
                            value: registrationNumber,
                          ),
                          _buildProfileItem(
                            context,
                            icon: Icons.class_,
                            label: 'Class',
                            value: user.className,
                          ),
                          _buildProfileItem(
                            context,
                            icon: Icons.school,
                            label: 'Department',
                            value: user.department,
                          ),
                          _buildProfileItem(
                            context,
                            icon: Icons.calendar_today,
                            label: 'Year',
                            value: user.year,
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
