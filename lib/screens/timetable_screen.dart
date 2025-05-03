import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ritian_v1/user_provider.dart';
import 'package:ritian_v1/widgets/custom_navigation_drawer.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  Map<String, Map<String, Map<String, String>>> timetable = {};
  List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  int _numberOfPeriods = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTimetable();
  }

  Future<void> _fetchTimetable() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null || user.className == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User class not found')),
      );
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('timetables')
          .where('class', isEqualTo: user.className)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final fetchedTimetable = Map<String, dynamic>.from(data['timetable']);

        // Convert the timetable to the expected format
        Map<String, Map<String, Map<String, String>>> convertedTimetable = {};
        fetchedTimetable.forEach((day, periods) {
          convertedTimetable[day] = {};
          Map<String, dynamic>.from(periods).forEach((period, details) {
            convertedTimetable[day]![period] =
                Map<String, String>.from(details);
          });
        });

        setState(() {
          timetable = convertedTimetable;
          // Determine the max number of periods across all days
          _numberOfPeriods = timetable.values
              .map((day) => day.keys.length)
              .reduce((a, b) => a > b ? a : b);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No timetable found for your class')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch timetable: $e')),
      );
    }
  }

  Widget _buildTimetableGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_numberOfPeriods == 0 || timetable.isEmpty) {
      return const Center(child: Text('No timetable available'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Day')),
          ...List.generate(
            _numberOfPeriods,
            (index) => DataColumn(label: Text('Period ${index + 1}')),
          ),
        ],
        rows: days.map((day) {
          return DataRow(cells: [
            DataCell(Text(day)),
            ...List.generate(_numberOfPeriods, (period) {
              final periodKey = (period + 1).toString();
              final subject = timetable[day]?[periodKey]?['subject'] ?? '-';
              final faculty = timetable[day]?[periodKey]?['faculty'] ?? '-';
              return DataCell(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject),
                    Text(faculty, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomNavigationDrawer.buildAppBar(context, 'Timetable'),
      drawer: const CustomNavigationDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildTimetableGrid(),
      ),
    );
  }
}
