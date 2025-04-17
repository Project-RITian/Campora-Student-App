import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ritian_v1/widgets/custom_navigation_drawer.dart';
import 'dart:io';

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
  final List<LeaveOdApplication> _applications = [];

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    setState(() {
      _attachment = result;
    });
  }

  void _submitApplication() {
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

    setState(() {
      _applications.add(LeaveOdApplication(
        fromDate: _fromDate!,
        toDate: _toDate!,
        reason: _reasonController.text,
        attachmentPath: _attachment?.files.single.path,
        status: 'Waiting for Class Incharge Approval',
      ));
      _fromDate = null;
      _toDate = null;
      _attachment = null;
      _reasonController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Application submitted successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomNavigationDrawer.buildAppBar(context, 'Apply Leave/OD'),
      drawer: const CustomNavigationDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apply for Leave/OD',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Dates',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'From Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _fromDate == null
                                    ? 'Select date'
                                    : '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'To Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _toDate == null
                                    ? 'Select date'
                                    : '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Attachment (Optional)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _selectAttachment,
                      child: const Text('Upload File'),
                    ),
                    if (_attachment != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Selected: ${_attachment!.files.single.name}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reason',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter the reason for Leave/OD...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitApplication,
                        child: const Text('Submit Application'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Application History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _applications.isEmpty
                ? const Center(child: Text('No applications submitted yet'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _applications.length,
                    itemBuilder: (context, index) {
                      final application = _applications[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Application ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'From: ${application.fromDate.day}/${application.fromDate.month}/${application.fromDate.year}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'To: ${application.toDate.day}/${application.toDate.month}/${application.toDate.year}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Reason: ${application.reason}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (application.attachmentPath != null)
                                Text(
                                  'Attachment: ${application.attachmentPath!.split('/').last}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              const SizedBox(height: 16),
                              StatusProgressLine(status: application.status),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class LeaveOdApplication {
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final String? attachmentPath;
  String status;

  LeaveOdApplication({
    required this.fromDate,
    required this.toDate,
    required this.reason,
    this.attachmentPath,
    required this.status,
  });
}

class StatusProgressLine extends StatelessWidget {
  final String status;

  const StatusProgressLine({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isClassInchargeApproved =
        status != 'Waiting for Class Incharge Approval';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
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
                ),
                const Text(
                  'Class Incharge',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            Expanded(
              child: Container(
                height: 2,
                color: isClassInchargeApproved ? Colors.green : Colors.grey,
              ),
            ),
            Column(
              children: [
                Icon(
                  status == 'Approved by HoD'
                      ? Icons.check_circle
                      : Icons.hourglass_empty,
                  color:
                      status == 'Approved by HoD' ? Colors.green : Colors.grey,
                ),
                const Text(
                  'HoD',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
