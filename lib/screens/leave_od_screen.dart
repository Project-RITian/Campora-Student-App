import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ritian_v1/widgets/custom_navigation_drawer.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class LeaveOdScreen extends StatefulWidget {
  const LeaveOdScreen({super.key});

  @override
  _LeaveOdScreenState createState() => _LeaveOdScreenState();
}

class _LeaveOdScreenState extends State<LeaveOdScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  FilePickerResult? _attachment;
  final TextEditingController _reasonController = TextEditingController();

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0C4D83),
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _selectAttachment() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null) {
        setState(() {
          _attachment = result;
        });
      }
    } catch (e) {
      print('Error selecting attachment: $e'); // Log error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select attachment: $e')),
      );
    }
  }

  Future<String?> _uploadAttachment(String filePath, String uid) async {
    try {
      File file = File(filePath);
      String fileName = filePath.split('/').last;
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('leave_attachments/$uid/$fileName');
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading attachment: $e'); // Log error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload attachment: $e')),
      );
      return null;
    }
  }

  Future<void> _submitApplication() async {
    if (_fromDate == null ||
        _toDate == null ||
        _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_toDate!.isBefore(_fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('To date cannot be before From date')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No authenticated user found'); // Log authentication issue
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    String? attachmentUrl;
    if (_attachment != null && _attachment!.files.single.path != null) {
      attachmentUrl =
          await _uploadAttachment(_attachment!.files.single.path!, user.uid);
    }

    final leaveData = {
      'fromDate': Timestamp.fromDate(_fromDate!),
      'toDate': Timestamp.fromDate(_toDate!),
      'reason': _reasonController.text,
      'attachmentUrl': attachmentUrl,
      'status': 'requested',
      'createdAt': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('leave_requests')
          .doc(user.uid)
          .collection('requests')
          .add(leaveData);

      setState(() {
        _fromDate = null;
        _toDate = null;
        _attachment = null;
        _reasonController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted successfully')),
      );
    } catch (e) {
      print('Error submitting application: $e'); // Log error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit application: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No authenticated user found'); // Log authentication issue
      return Scaffold(
        appBar: CustomNavigationDrawer.buildAppBar(context, 'Apply Leave/OD'),
        drawer: const CustomNavigationDrawer(),
        body: const Center(
          child: Text(
            'Please log in to apply for leave',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomNavigationDrawer.buildAppBar(context, 'Apply Leave/OD'),
      drawer: const CustomNavigationDrawer(),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apply for Leave/OD',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C4D83),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Dates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0C4D83),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectDate(context, true),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          color: Color(0xFF0C4D83)),
                                      const SizedBox(width: 8),
                                      Text(
                                        _fromDate == null
                                            ? 'From Date'
                                            : '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _fromDate == null
                                              ? Colors.grey
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectDate(context, false),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          color: Color(0xFF0C4D83)),
                                      const SizedBox(width: 8),
                                      Text(
                                        _toDate == null
                                            ? 'To Date'
                                            : '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _toDate == null
                                              ? Colors.grey
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Attachment (Optional)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0C4D83),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _selectAttachment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C4D83),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 24.0),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_file, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Upload File',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      ),
                      if (_attachment != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Selected: ${_attachment!.files.single.name}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.teal),
                          ),
                        ),
                      const SizedBox(height: 24),
                      const Text(
                        'Reason',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0C4D83),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reasonController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0)),
                          hintText: 'Enter the reason for Leave/OD...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: _submitApplication,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14.0, horizontal: 30.0),
                            elevation: 6,
                          ),
                          child: const Text('Submit Application',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Application History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C4D83),
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('leave_requests')
                    .doc(user.uid)
                    .collection('requests')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print(
                        'Firestore query error: ${snapshot.error}'); // Log error
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    print(
                        'No applications found for user: ${user.uid}'); // Log no data
                    return const Center(
                      child: Text(
                        'No applications submitted yet',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    );
                  }
                  print(
                      'Applications found: ${snapshot.data!.docs.length}'); // Log document count
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final fromDate = (data['fromDate'] as Timestamp).toDate();
                      final toDate = (data['toDate'] as Timestamp).toDate();
                      final reason = data['reason'] as String;
                      final attachmentUrl = data['attachmentUrl'] as String?;
                      final status = data['status'] as String;

                      return Card(
                        elevation: 6,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Application ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0C4D83),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'From: ${fromDate.day}/${fromDate.month}/${fromDate.year}',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black87),
                              ),
                              Text(
                                'To: ${toDate.day}/${toDate.month}/${toDate.year}',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black87),
                              ),
                              Text(
                                'Reason: $reason',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black87),
                              ),
                              if (attachmentUrl != null)
                                Text(
                                  'Attachment: ${attachmentUrl.split('/').last}',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.teal),
                                ),
                              const SizedBox(height: 16),
                              StatusProgressLine(status: status),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusProgressLine extends StatelessWidget {
  final String status;

  const StatusProgressLine({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Determine approval states and status text
    final bool isClassInchargeApproved = status != 'requested';
    final bool isHodApproved = status == 'approved';
    String statusText;
    List<Color> gradientColors;

    switch (status.toLowerCase()) {
      case 'requested':
        statusText = 'Leave/OD Requested';
        gradientColors = [Colors.grey, Colors.grey];
        break;
      case 'hod':
        statusText = 'Waiting for HoD approval';
        gradientColors = [Colors.green, Colors.grey];
        break;
      case 'approved':
        statusText = 'Approved';
        gradientColors = [Colors.green, Colors.green];
        break;
      case 'rejected':
        statusText = 'Rejected';
        gradientColors = [Colors.red, Colors.grey];
        break;
      default:
        statusText = 'Unknown Status';
        gradientColors = [Colors.grey, Colors.grey];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0C4D83)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(
                  isClassInchargeApproved
                      ? Icons.check_circle
                      : Icons.hourglass_empty,
                  color: isClassInchargeApproved ? Colors.green : Colors.grey,
                  size: 24,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Class Incharge',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Column(
              children: [
                Icon(
                  isHodApproved ? Icons.check_circle : Icons.hourglass_empty,
                  color: isHodApproved ? Colors.green : Colors.grey,
                  size: 24,
                ),
                const SizedBox(height: 4),
                const Text(
                  'HoD',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: status == 'rejected' ? Colors.red : Colors.black87,
          ),
        ),
      ],
    );
  }
}
