import 'package:flutter/material.dart';
import '../models/task_alarm.dart';
import '../services/alarm_service.dart';
import '../services/task_storage.dart';
import '../widgets/task_form_dialog.dart';

/// Main screen managing task queue and background alarms via StatefulWidget.
class TaskAlarmHomeScreen extends StatefulWidget {
  const TaskAlarmHomeScreen({super.key});

  @override
  State<TaskAlarmHomeScreen> createState() => _TaskAlarmHomeScreenState();
}

class _TaskAlarmHomeScreenState extends State<TaskAlarmHomeScreen> {
  final List<TaskAlarm> _tasks = [];
  final TaskStorage _storage = TaskStorage();
  final AlarmService _alarmService = AlarmService.instance;

  bool _isLoading = true;
  bool _isPlayingSound = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    _alarmService.onAlarmTriggered = () {
      if (mounted) {
        setState(() {
          _isPlayingSound = true;
        });
      }
    };

    final savedTasks = await _storage.loadTasks();
    savedTasks.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    if (mounted) {
      setState(() {
        _tasks.addAll(savedTasks);
        _isLoading = false;
        _isPlayingSound = _alarmService.isPlaying;
      });
    }
  }

  Future<void> _addTask() async {
    final TaskAlarm? newTask = await showDialog<TaskAlarm>(
      context: context,
      builder: (context) => const TaskFormDialog(),
    );

    if (newTask == null) return;

    await _alarmService.scheduleAlarm(
      id: newTask.id,
      title: newTask.title,
      description: newTask.description,
      scheduledTime: newTask.scheduledTime,
    );

    setState(() {
      _tasks.add(newTask);
      _tasks.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    });

    await _storage.saveTasks(_tasks);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Alarm scheduled for ${newTask.formattedDate} at ${newTask.formattedTime}'),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editTask(TaskAlarm task) async {
    final TaskAlarm? updatedTask = await showDialog<TaskAlarm>(
      context: context,
      builder: (context) => TaskFormDialog(initialTask: task),
    );

    if (updatedTask == null) return;

    await _alarmService.cancelAlarm(task.id);
    if (!updatedTask.isDue && !updatedTask.isCompleted) {
      await _alarmService.scheduleAlarm(
        id: updatedTask.id,
        title: updatedTask.title,
        description: updatedTask.description,
        scheduledTime: updatedTask.scheduledTime,
      );
    }

    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        _tasks.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      }
    });

    await _storage.saveTasks(_tasks);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alarm "${updatedTask.title}" updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleTaskCompletion(TaskAlarm task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);

    if (updatedTask.isCompleted) {
      await _alarmService.cancelAlarm(task.id);
    } else if (!updatedTask.isDue) {
      await _alarmService.scheduleAlarm(
        id: updatedTask.id,
        title: updatedTask.title,
        description: updatedTask.description,
        scheduledTime: updatedTask.scheduledTime,
      );
    }

    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
    });

    await _storage.saveTasks(_tasks);
  }

  Future<void> _deleteTask(TaskAlarm task) async {
    await _alarmService.cancelAlarm(task.id);

    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });

    await _storage.saveTasks(_tasks);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alarm "${task.title}" cancelled'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleAudioTest() async {
    if (_isPlayingSound) {
      await _alarmService.stopAlarmSound();
      setState(() => _isPlayingSound = false);
    } else {
      await _alarmService.playAlarmSound();
      setState(() => _isPlayingSound = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Task Alarms'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: _isPlayingSound ? 'Stop Alarm Audio' : 'Test Alarm Sound',
            icon: Icon(
              _isPlayingSound ? Icons.volume_off : Icons.volume_up,
              color: _isPlayingSound ? Colors.amberAccent : null,
            ),
            onPressed: _toggleAudioTest,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isPlayingSound)
            Container(
              color: Colors.amber.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.alarm_on, color: Colors.white),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Alarm Ringtone Playing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _toggleAudioTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Silence'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? _buildEmptyState()
                    : _buildTaskList(theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add_alarm),
        label: const Text('Add Alarm'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm_off, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          Text(
            'No Active Alarms',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the button below to schedule an offline alarm.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        final isDue = task.isDue;
        final isDone = task.isCompleted;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDone
                  ? Colors.blue.shade100
                  : (isDue ? Colors.grey.shade300 : Colors.deepPurple.shade100),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: isDone ? 'Mark Incomplete' : 'Mark Completed',
                  icon: Icon(
                    isDone
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isDone ? Colors.green : Colors.deepPurple,
                    size: 26,
                  ),
                  onPressed: () => _toggleTaskCompletion(task),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration:
                              (isDone || isDue) ? TextDecoration.lineThrough : null,
                          color: (isDone || isDue)
                              ? Colors.grey.shade600
                              : null,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: isDone
                                ? Colors.grey
                                : (isDue ? Colors.grey : Colors.deepPurple),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.formattedDate} • ${task.formattedTime}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDone
                                  ? Colors.grey
                                  : (isDue ? Colors.grey : Colors.deepPurple),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? Colors.blue.shade50
                                  : (isDue
                                      ? Colors.grey.shade200
                                      : Colors.green.shade50),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isDone
                                  ? 'Completed'
                                  : (isDue ? 'Triggered' : 'Scheduled'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDone
                                    ? Colors.blue.shade700
                                    : (isDue
                                        ? Colors.grey
                                        : Colors.green.shade700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit Alarm',
                  onPressed: () => _editTask(task),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  tooltip: 'Delete Alarm',
                  onPressed: () => _deleteTask(task),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
