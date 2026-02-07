import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../data/task_service.dart';
import '../../data/task_model.dart';
import 'package:taskflow_pro/state/app_state.dart';
import 'package:taskflow_pro/services/notification_service.dart';
import 'package:taskflow_pro/features/settings/presentation/screens/settings_screen.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _notifiedTaskIds = {};
//task.dueDate.subtract(const Duration(days: 1))
  @override
  Widget build(BuildContext context) {
    final taskService = TaskService();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "TaskFlow Pro",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,

        // ⭐ CHANGED: compact actions only
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddTaskDialog(context),
      ),

      body: Consumer<AppState>(
        builder: (context, appState, _) {
          return Column(
            children: [
              _buildFilterChips(context, appState),

              Expanded(
                child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, authSnap) {
                    if (authSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final user = authSnap.data;
                    if (user == null) {
                      return const Center(
                          child: Text("Please login"));
                    }

                    return StreamBuilder<List<TaskModel>>(
                      stream: taskService.getTasksForUser(user.uid),
                      builder: (context, taskSnap) {
                        if (taskSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final tasks = taskSnap.data ?? [];
                        _checkAndNotifyDueTasks(tasks);

                        final filtered = appState.filter == "All"
                            ? tasks
                            : tasks
                            .where((t) =>
                        t.category == appState.filter)
                            .toList();

                        filtered.sort((a, b) {
                          if (!a.isCompleted && b.isCompleted) return -1;
                          if (a.isCompleted && !b.isCompleted) return 1;

                          switch (appState.sortBy) {
                            case "dateAsc":
                              return a.dueDate.compareTo(b.dueDate);
                            case "dateDesc":
                              return b.dueDate.compareTo(a.dueDate);
                            case "category":
                              return a.category.compareTo(b.category);
                            default:
                              return 0;
                          }
                        });

                        if (filtered.isEmpty) {
                          return const Center(
                            child: Text(
                              "No tasks yet.\nTap + to add one.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) =>
                              _taskCard(context, taskService, filtered[i]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ⭐ CHANGED: compact sorting bottom sheet
  void _showSortSheet(BuildContext context) {
    final appState = context.read<AppState>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text(
            "Sort Tasks",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          ListTile(
            leading: const Icon(Icons.arrow_upward),
            title: const Text("Date ↑ (Nearest)"),
            onTap: () {
              appState.setSort("dateAsc");
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.arrow_downward),
            title: const Text("Date ↓ (Latest)"),
            onTap: () {
              appState.setSort("dateDesc");
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text("Category A–Z"),
            onTap: () {
              appState.setSort("category");
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ---------------- REST OF YOUR FILE ----------------
  // ------------------------------------------------------------------
  Widget _taskCard(
      BuildContext context, TaskService service, TaskModel task) {
    final now = DateTime.now();
    final isDueSoon =
        !task.isCompleted && task.dueDate.difference(now).inHours <= 24;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDueSoon ? Colors.red.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => _showTaskDetails(context, task),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: (v) {
                  service.toggleTaskCompletion(task.id, v!);
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(label: Text(task.category)),
                        Chip(
                          label: Text(
                              "Due: ${_formatDateTime(task.dueDate, context)}"),
                        ),
                        if (isDueSoon)
                          const Chip(
                            label: Text("⚠ Due Soon"),
                            backgroundColor: Colors.redAccent,
                            labelStyle:
                            TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditTaskDialog(context, task),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                color: Colors.red,
                onPressed: () async {
                  final baseId = task.id.hashCode & 0x7fffffff;
                  await NotificationService.cancel(baseId);
                  await NotificationService.cancel(baseId + 1);
                  await NotificationService.cancel(baseId + 2);
                  await service.deleteTask(task.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  void _showTaskDetails(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category: ${task.category}"),
            const SizedBox(height: 6),
            Text("Due: ${_formatDateTime(task.dueDate, context)}"),
            const SizedBox(height: 6),
            Text("Description:\n${task.description}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  void _showEditTaskDialog(BuildContext context, TaskModel task) {
    final titleCtrl = TextEditingController(text: task.title);
    final descCtrl = TextEditingController(text: task.description);

    String category = task.category;
    DateTime selectedDateTime = task.dueDate;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (_, setState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Edit Task",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: titleCtrl,
                      decoration:
                      const InputDecoration(labelText: "Title")),
                  const SizedBox(height: 12),
                  TextField(
                      controller: descCtrl,
                      decoration:
                      const InputDecoration(labelText: "Description")),
                  const SizedBox(height: 12),
                  DropdownButtonFormField(
                    value: category,
                    items: ["Work", "Personal", "Urgent"]
                        .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => category = v!),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) {
                        setState(() {
                          selectedDateTime = DateTime(
                            d.year,
                            d.month,
                            d.day,
                            selectedDateTime.hour,
                            selectedDateTime.minute,
                          );
                        });
                      }
                    },
                    child: Text(
                        "Date: ${_formatDateTime(selectedDateTime, context)}"),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime:
                        TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (t != null) {
                        setState(() {
                          selectedDateTime = DateTime(
                            selectedDateTime.year,
                            selectedDateTime.month,
                            selectedDateTime.day,
                            t.hour,
                            t.minute,
                          );
                        });
                      }
                    },
                    child: Text(
                        "Time: ${TimeOfDay.fromDateTime(selectedDateTime).format(context)}"),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async {
                      await TaskService().editTask(task.id, {
                        "title": titleCtrl.text.trim(),
                        "description": descCtrl.text.trim(),
                        "category": category,
                        "dueDate": selectedDateTime,
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Save"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// -------------------------------------------------------------------
  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    final categories = ["Work", "Personal", "Urgent"];
    String selectedCategory = "Work";
    DateTime? selectedDateTime;

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder: (_, setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Add Task",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: "Title"),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: descController,
                        decoration:
                        const InputDecoration(labelText: "Description"),
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField(
                        value: selectedCategory,
                        items: categories
                            .map(
                              (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ),
                        )
                            .toList(),
                        onChanged: (v) => setState(() => selectedCategory = v!),
                        decoration:
                        const InputDecoration(labelText: "Category"),
                      ),

                      const SizedBox(height: 12),

                      // 📅 DATE PICKER
                      FilledButton.tonal(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            initialDate: DateTime.now(),
                          );

                          if (pickedDate != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                9, // default hour
                                0, // default minute
                              );
                            });
                          }
                        },
                        child: Text(
                          selectedDateTime == null
                              ? "Pick due date"
                              : "Date: ${selectedDateTime!
                              .toString()
                              .substring(0, 10)}",
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ⏰ TIME PICKER
                      FilledButton.tonal(
                        onPressed: selectedDateTime == null
                            ? null
                            : () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime:
                            TimeOfDay.fromDateTime(selectedDateTime!),
                          );

                          if (pickedTime != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                selectedDateTime!.year,
                                selectedDateTime!.month,
                                selectedDateTime!.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        },
                        child: Text(
                          selectedDateTime == null
                              ? "Pick time"
                              : "Time: ${TimeOfDay.fromDateTime(selectedDateTime!)
                              .format(context)}",
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),

                          const SizedBox(width: 10),

                          FilledButton(
                            onPressed: () {
                              if (titleController.text.trim().isEmpty ||
                                  descController.text.trim().isEmpty ||
                                  selectedDateTime == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please fill all fields"),
                                  ),
                                );
                                return;
                              }

                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("User not logged in"),
                                  ),
                                );
                                return;
                              }

                              final task = TaskModel(
                                id: FirebaseFirestore.instance
                                    .collection("tasks")
                                    .doc()
                                    .id,
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                category: selectedCategory,
                                dueDate: selectedDateTime!,
                                isCompleted: false,
                                userId: user.uid,
                              );

                              TaskService().addTask(task);
                              final baseId = task.id.hashCode & 0x7fffffff;
                              final now = DateTime.now();

                              // Due time (always valid)
                              NotificationService.schedule(
                                id: baseId,
                                title: "Task Reminder",
                                body: task.title,
                                dateTime: task.dueDate,
                              );

                              // 1 hour before (ONLY if future)
                              if (task.dueDate.isAfter(now.add(const Duration(hours: 1)))) {
                                NotificationService.schedule(
                                  id: baseId + 1,
                                  title: "Upcoming Task",
                                  body: "${task.title} in 1 hour",
                                  dateTime: task.dueDate.subtract(const Duration(hours: 1)),
                                );
                              }

                              // 1 day before (ONLY if future)
                              if (task.dueDate.isAfter(now.add(const Duration(days: 1)))) {
                                NotificationService.schedule(
                                  id: baseId + 2,
                                  title: "Upcoming Task",
                                  body: "${task.title} tomorrow",
                                  dateTime: task.dueDate.subtract(const Duration(days: 1)),
                                );
                              }


                              Navigator.pop(context);
                            },
                            child: const Text("Add"),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------
  String _formatDateTime(DateTime dt, BuildContext context) {
    final d =
        "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
    final t = TimeOfDay.fromDateTime(dt).format(context);
    return "$d • $t";
  }

  Widget _buildFilterChips(BuildContext context, AppState appState) {
    final filters = ["All", "Work", "Personal", "Urgent"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: filters.map((f) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: appState.filter == f,
              onSelected: (_) => appState.setFilter(f),
            ),
          );
        }).toList(),
      ),
    );
  }
  void _checkAndNotifyDueTasks(List<TaskModel> tasks) {
    final now = DateTime.now();
    for (final task in tasks) {
      // Already completed → skip
      if (task.isCompleted) continue;
      // Already notified → skip
      if (_notifiedTaskIds.contains(task.id)) continue;
      final diff = task.dueDate.difference(now);
      // 🔔 Notify ONLY if due in next 5 minutes
      if (diff.inMinutes <= 5 && diff.inMinutes >= 0) {
        NotificationService.showInstant(
          id: task.id.hashCode & 0x7fffffff,
          title: "Task Due Soon",
          body: task.title,
        );
        _notifiedTaskIds.add(task.id);
      }
    }
  }
}
