import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritian_v1/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // Inline JSON data for credentials and student details
  static const List<Map<String, dynamic>> _userData = [
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
      "password": "Zypher@2006",
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

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final userData = _userData.firstWhere(
      (user) => user['email'] == email && user['password'] == password,
      orElse: () => {},
    );

    if (userData.isNotEmpty) {
      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);

      // Set user in UserProvider
      Provider.of<UserProvider>(context, listen: false)
          .setUserFromJson(userData);

      // Navigate to home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password')),
      );
    }
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password'),
        content: const Text('Please contact the admin to reset your password.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Image.network(
                'https://via.placeholder.com/150',
                height: 100,
                width: 100,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.school,
                  size: 100,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'RITian App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
