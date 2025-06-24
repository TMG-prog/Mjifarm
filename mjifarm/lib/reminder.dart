import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reminders',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const ReminderPage(),
    );
  }
}

class Task {
  String id;
  String title;
  String description;
  DateTime dueDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
  });

  // Convert a Task object to Map for Firebase
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate.toIso8601String(),
  };

  // Create Task from Firebase snapshot
  factory Task.fromMap(Map data) => Task(
    id: data['id'],
    title: data['title'],
    description: data['description'],
    dueDate: DateTime.parse(data['dueDate']),
  );
}

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final user = FirebaseAuth.instance.currentUser;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  List<Task> _tasks = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Load tasks for current user from Firebase
  void _loadTasks() async {
    final uid = user?.uid;
    if (uid == null) return;

    final snapshot = await _dbRef.child('tasks/$uid').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _tasks =
            data.entries
                .map((e) => Task.fromMap(Map<String, dynamic>.from(e.value)))
                .toList();
      });
    }
  }

  // Add or update a task in Firebase
  void _addOrEditTask({Task? task}) {
    final formKey = GlobalKey<FormState>();
    String title = task?.title ?? '';
    String description = task?.description ?? '';
    DateTime dueDate = task?.dueDate ?? _selectedDay ?? DateTime.now();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(task == null ? "Add Task" : "Edit Task"),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: title,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator:
                        (val) =>
                            val == null || val.isEmpty ? "Enter title" : null,
                    onSaved: (val) => title = val!,
                  ),
                  TextFormField(
                    initialValue: description,
                    decoration: const InputDecoration(labelText: 'Description'),
                    onSaved: (val) => description = val ?? '',
                  ),
                  TextButton(
                    child: Text("Due: ${dueDate.toLocal()}".split(' ')[0]),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => dueDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                child: Text(task == null ? "Add" : "Update"),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    final newTask = Task(
                      id: task?.id ?? Random().nextInt(1000000).toString(),
                      title: title,
                      description: description,
                      dueDate: dueDate,
                    );
                    final uid = user?.uid;
                    if (uid != null) {
                      _dbRef
                          .child('tasks/$uid/${newTask.id}')
                          .set(newTask.toMap());
                    }
                    setState(() {
                      if (task == null) {
                        _tasks.add(newTask);
                      } else {
                        final index = _tasks.indexWhere((t) => t.id == task.id);
                        _tasks[index] = newTask;
                      }
                    });
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
    );
  }

  // Delete task from Firebase
  void _deleteTask(Task task) {
    final uid = user?.uid;
    if (uid != null) {
      _dbRef.child('tasks/$uid/${task.id}').remove();
    }
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
  }

  // Handle checkbox toggle (delete if checked)
  void _toggleDone(Task task, bool? value) {
    if (value == true) {
      _deleteTask(task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final selectedDay = _selectedDay ?? today;

    // Sort tasks into categories
    final overdue =
        _tasks
            .where(
              (t) =>
                  isSameDay(t.dueDate, today) == false &&
                  t.dueDate.isBefore(today),
            )
            .toList();
    final pending = _tasks.where((t) => t.dueDate.isAfter(today)).toList();
    final dayTasks =
        _tasks.where((t) => isSameDay(t.dueDate, selectedDay)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Reminders")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditTask(),
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
            ),
            const SizedBox(height: 20),

            // Overdue Tasks Section
            const Text(
              'Overdue Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (overdue.isEmpty) const Text("No overdue tasks."),
            ...overdue.map((task) => _taskTile(task, isOverdue: true)),

            const SizedBox(height: 20),

            // Pending Tasks Section
            const Text(
              'Pending Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (pending.isEmpty) const Text("No pending tasks."),
            ...pending.map(_taskTile),

            const SizedBox(height: 20),

            // Today's Tasks
            Text(
              isSameDay(selectedDay, today)
                  ? "Today's Tasks"
                  : "Tasks for ${selectedDay.toLocal()}".split(' ')[0],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (dayTasks.isEmpty) const Text("No tasks for this day."),
            ...dayTasks.map(_taskTile),
          ],
        ),
      ),
    );
  }

  // Task UI Tile
  Widget _taskTile(Task task, {bool isOverdue = false}) {
    return Card(
      color: isOverdue ? Colors.red.shade100 : null,
      child: ListTile(
        leading: Checkbox(
          value: false,
          onChanged: (val) => _toggleDone(task, val),
        ),
        title: Text(task.title),
        subtitle: Text(task.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _addOrEditTask(task: task),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteTask(task),
            ),
          ],
        ),
      ),
    );
  }
}
