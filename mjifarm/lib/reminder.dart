import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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
  bool isDone;
  DateTime dueDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.isDone,
    required this.dueDate,
  });
}

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final List<Task> _tasks = [];

  void _addOrEditTask({Task? task}) {
    final _formKey = GlobalKey<FormState>();
    String title = task?.title ?? '';
    String description = task?.description ?? '';
    DateTime dueDate = task?.dueDate ?? _selectedDay ?? DateTime.now();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(task == null ? "Add Task" : "Edit Task"),
            content: Form(
              key: _formKey,
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
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    setState(() {
                      if (task == null) {
                        _tasks.add(
                          Task(
                            id:
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            title: title,
                            description: description,
                            isDone: false,
                            dueDate: dueDate,
                          ),
                        );
                      } else {
                        task.title = title;
                        task.description = description;
                        task.dueDate = dueDate;
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

  void _deleteTask(String id) {
    setState(() {
      _tasks.removeWhere((t) => t.id == id);
    });
  }

  void _toggleDone(Task task, bool? value) {
    setState(() {
      task.isDone = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final selectedDay = _selectedDay ?? today;

    final overdue =
        _tasks.where((t) => t.dueDate.isBefore(today) && !t.isDone).toList();
    final pending =
        _tasks.where((t) => t.dueDate.isAfter(today) && !t.isDone).toList();
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

            // Overdue Section
            const Text(
              'Overdue Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (overdue.isEmpty) const Text("No overdue tasks."),
            ...overdue.map(_taskTile),

            const SizedBox(height: 20),

            // Pending Section
            const Text(
              'Pending Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (pending.isEmpty) const Text("No pending tasks."),
            ...pending.map(_taskTile),

            const SizedBox(height: 20),

            // Today's or selected day's tasks
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

  Widget _taskTile(Task task) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: task.isDone,
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
              onPressed: () => _deleteTask(task.id),
            ),
          ],
        ),
      ),
    );
  }
}
