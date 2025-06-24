import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mjifarm/forms/expert_application_form.dart'; 

class FarmerApplicationStatusWidget extends StatefulWidget {
  const FarmerApplicationStatusWidget({super.key});

  @override
  State<FarmerApplicationStatusWidget> createState() => _FarmerApplicationStatusWidgetState();
}

class _FarmerApplicationStatusWidgetState extends State<FarmerApplicationStatusWidget> {
  User? _currentUser;
  DatabaseReference? _applicationRef;
  String _applicationStatus = 'not_applied'; // Default status if no application exists

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _applicationRef = FirebaseDatabase.instance
          .ref('expert_applications')
          .child(_currentUser!.uid);
      _listenToApplicationStatus();
    }
  }

  void _listenToApplicationStatus() {
    _applicationRef?.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _applicationStatus = data['status'] ?? 'pending';
        });
      } else {
        setState(() {
          _applicationStatus = 'not_applied'; // No application found
        });
      }
    }, onError: (error) {
      print("Error listening to application status: $error");
      setState(() {
        _applicationStatus = 'error';
      });
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade700;
      case 'approved':
        return Colors.green.shade700;
      case 'rejected':
        return Colors.red.shade700;
      case 'not_applied':
        return Colors.blueGrey.shade700;
      case 'error':
      default:
        return Colors.grey;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Your expert application is Pending Review.';
      case 'approved':
        return 'Congratulations! Your application has been Approved. You are now an Expert.';
      case 'rejected':
        return 'Your expert application was Rejected. You can re-apply if you wish.';
      case 'not_applied':
        return 'Become an Expert! Submit your application today.';
      case 'error':
        return 'Error loading application status.';
      default:
        return 'Unknown application status.';
    }
  }

  @override
  Widget build(BuildContext context) {
    String message = _getStatusMessage(_applicationStatus);
    Color color = _getStatusColor(_applicationStatus);
    IconData icon;

    if (_applicationStatus == 'approved') {
      icon = Icons.check_circle_outline;
    } else if (_applicationStatus == 'rejected') {
      icon = Icons.cancel_outlined;
    } else if (_applicationStatus == 'pending') {
      icon = Icons.hourglass_empty;
    } else {
      icon = Icons.how_to_reg_outlined; // For not_applied or error
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: color.withOpacity(0.1), // Lighter background based on status
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: color, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Expert Application Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 15, color: color.withOpacity(0.9)),
            ),
            if (_applicationStatus == 'not_applied' || _applicationStatus == 'rejected')
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ExpertApplicationForm()),
                    );
                  },
                  icon: Icon(
                    _applicationStatus == 'not_applied' ? Icons.app_registration : Icons.redo,
                    color: color,
                  ),
                  label: Text(
                    _applicationStatus == 'not_applied' ? 'Apply Now' : 'Re-apply',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            if (_applicationStatus == 'pending')
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Please wait for admin review.',
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: color.withOpacity(0.8)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}