import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritian_v1/screens/arcade_screen.dart';
import 'package:ritian_v1/screens/canteen_screen.dart';
import 'package:ritian_v1/screens/payment_success_screen.dart';
import 'package:ritian_v1/screens/under_construction_screen.dart';
import 'package:ritian_v1/screens/ritz_purchase_screen.dart';
import 'package:ritian_v1/screens/event_registration_screen.dart';
import 'package:ritian_v1/screens/leave_od_screen.dart';
import 'package:ritian_v1/screens/login_screen.dart';
import 'package:ritian_v1/user_provider.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/payment_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? userEmail = prefs.getString('user_email');
  final bool isLoggedIn = userEmail != null;

  // Inline JSON data for credentials and student details (same as LoginScreen)
  const List<Map<String, dynamic>> userData = [
    {
      "email": "john.doe@example.com",
      "password": "password123",
      "name": "John Doe",
      "department": "Computer Science and Engineering",
      "class": "CSE-A",
      "year": "3rd Year",
    },
    {
      "email": "jane.smith@example.com",
      "password": "password456",
      "name": "Jane Smith",
      "department": "Electronics and Communication",
      "class": "ECE-B",
      "year": "2nd Year",
    },
    {
      "email": "sidharth.240308@aids.ritchennai.edu.in",
      "password": "1234",
      "name": "Sidharth P L",
      "department": "Artificial Intelligence & Data Science",
      "class": "AI&DS",
      "year": "1st Year",
    },
    {
      "email": "shanjithkrishna.240291@aids.ritchennai.edu.in",
      "password": "1234",
      "name": "Shanjithkrishna V",
      "department": "Artificial Intelligence & Data Science",
      "class": "AI&DS",
      "year": "1st Year",
    },
    {
      "email": "shruthi.240304@aids.ritchennai.edu.in",
      "password": "1234",
      "name": "Shruthi S S",
      "department": "Artificial Intelligence & Data Science",
      "class": "AI&DS",
      "year": "1st Year",
    },
    {
      "email": "shylendhar.240306@aids.ritchennai.edu.in",
      "password": "1234",
      "name": "Shylendhar M",
      "department": "Artificial Intelligence & Data Science",
      "class": "AI&DS",
      "year": "1st Year",
    },
  ];

  runApp(
    ChangeNotifierProvider(
      create: (context) {
        final userProvider = UserProvider();
        if (isLoggedIn) {
          final userDataItem = userData.firstWhere(
            (user) => user['email'] == userEmail,
            orElse: () => {},
          );
          if (userDataItem.isNotEmpty) {
            userProvider.setUserFromJson(userDataItem);
          }
        }
        return userProvider;
      },
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RITian App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/arcade': (context) => const ArcadeScreen(),
        '/canteen': (context) => const CanteenScreen(),
        '/payment': (context) => const PaymentScreen(
              file: null,
              copies: 1,
              isColor: false,
              printSide: 'Single Sided',
              customInstructions: '',
              stationeryCart: {},
              stationeryItems: [],
              foodCart: {},
              foodItems: [],
            ),
        '/payment-success': (context) => const PaymentSuccessScreen(),
        '/under-construction': (context) => const UnderConstructionScreen(),
        '/buy_ritz': (context) => const RitzPurchaseScreen(),
        '/event_registration': (context) => const EventRegistrationScreen(),
        '/leaveandod': (context) => const LeaveOdScreen(),
        '/assignment_submission': (context) => const UnderConstructionScreen(),
        '/gpa_book': (context) => const UnderConstructionScreen(),
        '/class_committee': (context) => const UnderConstructionScreen(),
        '/raise_query': (context) => const UnderConstructionScreen(),
        '/apply_certificates': (context) => const UnderConstructionScreen(),
        '/exam_results': (context) => const UnderConstructionScreen(),
        '/fee_details': (context) => const UnderConstructionScreen(),
        '/bus_tracking': (context) => const UnderConstructionScreen(),
      },
    );
  }
}
