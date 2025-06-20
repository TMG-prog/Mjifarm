import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Needed for DatabaseReference

class UserManagementContent extends StatefulWidget {
  const UserManagementContent({super.key});

  @override
  State<UserManagementContent> createState() => _UserManagementContentState();
}

class _UserManagementContentState extends State<UserManagementContent> {
  late DatabaseReference _usersRef;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  late Stream<DatabaseEvent> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersRef = FirebaseDatabase.instance.ref('users');
    _usersStream = _usersRef.onValue;
    _listenToUsers();
  }

  void _listenToUsers() {
    _usersStream.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final List<Map<String, dynamic>> fetchedUsers = [];
        data.forEach((key, value) {
          if (value is Map) {
            fetchedUsers.add({'id': key, ...Map<String, dynamic>.from(value)});
          }
        });
        setState(() {
          _users = fetchedUsers;
          _isLoading = false;
        });
      } else {
        setState(() {
          _users = [];
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print("Error listening to users: $error");
      setState(() {
        _isLoading = false;
      });
      _showSnackBar("Error fetching users: $error", Colors.red);
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2), backgroundColor: color),
    );
  }

  void _handleStatusChange(String userId, String newStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Confirm Action'),
          content: Text('Are you sure you want to set user status to "$newStatus"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _usersRef.child(userId).update({'status': newStatus});
                  _showSnackBar('User $userId status updated to $newStatus', Colors.green);
                } catch (e) {
                  _showSnackBar('Failed to update status: $e', Colors.red);
                } finally {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _handleDelete(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete user $userId? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _usersRef.child(userId).remove();
                  _showSnackBar('User $userId deleted.', Colors.green);
                } catch (e) {
                  _showSnackBar('Failed to delete user: $e', Colors.red);
                } finally {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return Colors.green.shade100;
      case 'pending': return Colors.orange.shade100;
      case 'inactive': return Colors.red.shade100;
      default: return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'active': return Colors.green.shade800;
      case 'pending': return Colors.orange.shade800;
      case 'inactive': return Colors.red.shade800;
      default: return Colors.grey.shade800;
    }
  }

  Color _getRoleColor(List<dynamic>? roles) {
    if (roles == null) return Colors.grey.shade100;
    if (roles.contains('admin')) return Colors.purple.shade100;
    if (roles.contains('expert')) return Colors.yellow.shade100;
    if (roles.contains('farmer')) return Colors.blue.shade100;
    return Colors.grey.shade100;
  }

  Color _getRoleTextColor(List<dynamic>? roles) {
    if (roles == null) return Colors.grey.shade800;
    if (roles.contains('admin')) return Colors.purple.shade800;
    if (roles.contains('expert')) return Colors.yellow.shade800;
    if (roles.contains('farmer')) return Colors.blue.shade800;
    return Colors.grey.shade800;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Management',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  columnSpacing: 16.0,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 60,
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  columns: const [
                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Registered', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _users.map((user) => DataRow(cells: [
                    DataCell(Text(user['name'] ?? 'N/A')),
                    DataCell(Text(user['email'] ?? 'N/A')),
                    DataCell(
                      Chip(
                        label: Text(
                          user['userRole'] != null ? (user['userRole'] as List).join(', ') : 'N/A',
                          style: TextStyle(color: _getRoleTextColor(user['userRole'])),
                        ),
                        backgroundColor: _getRoleColor(user['userRole']),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    DataCell(
                      Chip(
                        label: Text(user['status'] ?? 'N/A', style: TextStyle(color: _getStatusTextColor(user['status'] ?? ''))),
                        backgroundColor: _getStatusColor(user['status'] ?? ''),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    DataCell(Text(user['registrationDate'] != null ? DateTime.fromMillisecondsSinceEpoch(user['registrationDate']).toLocal().toString().split(' ')[0] : 'N/A')),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(user['status'] == 'active' ? Icons.toggle_off : Icons.toggle_on, color: user['status'] == 'active' ? Colors.red : Colors.green),
                            tooltip: user['status'] == 'active' ? 'Deactivate' : 'Activate',
                            onPressed: () => _handleStatusChange(user['id'], user['status'] == 'active' ? 'inactive' : 'active'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete User',
                            onPressed: () => _handleDelete(user['id']),
                          ),
                        ],
                      ),
                    ),
                  ])).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
