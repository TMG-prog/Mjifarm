import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class Task {
  String title;
  String description;
  bool isDone;
  DateTime dueDate;

  Task({
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

  List<Task> tasks = [
    Task(
      title: "Buy Seeds",
      description: "Kales & Spinach",
      isDone: false,
      dueDate: DateTime.now().subtract(Duration(days: 1)),
    ),
    Task(
      title: "Water Crops",
      description: "Early morning",
      isDone: false,
      dueDate: DateTime.now(),
    ),
    Task(
      title: "Check Pests",
      description: "Inspect for aphids",
      isDone: true,
      dueDate: DateTime.now(),
    ),
    Task(
      title: "Harvest Tomatoes",
      description: "Fully ripened",
      isDone: false,
      dueDate: DateTime.now().add(Duration(days: 1)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final overdueTasks =
        tasks
            .where((task) => task.dueDate.isBefore(today) && !task.isDone)
            .toList();
    final todaysTasks =
        tasks.where((task) => isSameDay(task.dueDate, today)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reminders"),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Overdue
            const Text(
              'Overdue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...overdueTasks.map((task) => overdueTile(task)),

            const SizedBox(height: 20),

            // Today's Tasks
            const Text(
              "Today's Tasks",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...todaysTasks.map((task) => taskTile(task)),
          ],
        ),
      ),
    );
  }

  Widget taskTile(Task task) {
    return ListTile(
      leading: Checkbox(
        value: task.isDone,
        onChanged: (val) {
          setState(() {
            task.isDone = val!;
          });
        },
      ),
      title: Text(task.title),
      subtitle: Text(task.description),
      trailing: Icon(
        Icons.check_circle,
        color: task.isDone ? Colors.green : Colors.grey,
      ),
    );
  }

  Widget overdueTile(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text('${task.title} - ${task.description}')),
        ],
      ),
    );
  }
}
