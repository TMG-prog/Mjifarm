import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get the current user's UID

// Import the expert login screen
import 'expert_login_screen.dart'; // Make sure this path is correct

// Import the farmer application status widget
import '../farmer_features/expert_selection_status.dart'; // Make sure this path is correct

class ExpertApplicationForm extends StatefulWidget {
  const ExpertApplicationForm({super.key});

  @override
  State<ExpertApplicationForm> createState() => _ExpertApplicationFormState();
}

class _ExpertApplicationFormState extends State<ExpertApplicationForm> {
  // 0: Initial choice screen (login vs apply)
  // 1: Show the application form
  // 2: Show the application status (integrated within the application view)
  int _currentView = 0;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _expertiseController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitApplication() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to apply.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final DatabaseReference applicationsRef =
          FirebaseDatabase.instance.ref('expert_applications');

      try {
        await applicationsRef.child(user.uid).set({
          'applicantUid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'expertise': _expertiseController.text.trim(),
          'experience': _experienceController.text.trim(),
          'contactEmail': _contactEmailController.text.trim(),
          'contactPhone': _contactPhoneController.text.trim(),
          'status': 'pending',
          'timestamp': ServerValue.timestamp,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!')),
        );
        // After submission, switch to status view
        setState(() {
          _currentView = 1; // Stay on the application view to show status
        });
      } catch (e) {
        print('Error submitting expert application: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit application: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _expertiseController.dispose();
    _experienceController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _currentView == 0
            ? const Text('Become an Expert')
            : const Text('Expert Application'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCurrentView(),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 0: // Initial choice screen
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Image.asset(height: 200,"assets/Mjifarms.png"),
              const SizedBox(height: 30),
              Text(
                'Are you an existing expert or would you like to apply?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade600,
                    ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExpertLoginScreen()),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('I already have an Expert Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentView = 1; // Switch to application form/status view
                  });
                },
                icon: const Icon(Icons.app_registration),
                label: const Text('Apply to be an Expert'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                  side: BorderSide(color: Colors.green.shade700, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        );
      case 1: // Application form and status view
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FarmerApplicationStatusWidget(), // Display application status
              const SizedBox(height: 24),
              Text(
                'Submit Your Expert Application',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _expertiseController,
                      decoration: const InputDecoration(
                        labelText: 'Area of Expertise (e.g., Crop Management, Pest Control)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your area of expertise.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _experienceController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Describe your experience and qualifications',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please describe your experience.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Contact handle(email)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a contact email.';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Contact Phone (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitApplication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Submit Application',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      default:
        return const Center(child: Text('Unknown view state.'));
    }
  }
}