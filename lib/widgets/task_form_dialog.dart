import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_alarm.dart';

/// Modal dialog for creating or editing an offline task alarm.
class TaskFormDialog extends StatefulWidget {
  final TaskAlarm? initialTask;

  const TaskFormDialog({super.key, this.initialTask});

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');

    if (task != null) {
      _selectedDate = DateTime(
        task.scheduledTime.year,
        task.scheduledTime.month,
        task.scheduledTime.day,
      );
      _selectedTime = TimeOfDay(
        hour: task.scheduledTime.hour,
        minute: task.scheduledTime.minute,
      );
    } else {
      final now = DateTime.now().add(const Duration(minutes: 5));
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime get _targetDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _errorMessage = null;
      });
    }
  }

  void _submit() {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final target = _targetDateTime;
    if (target.isBefore(DateTime.now())) {
      setState(() {
        _errorMessage = 'Target alarm time must be in the future.';
      });
      return;
    }

    final task = TaskAlarm(
      id: widget.initialTask?.id ??
          DateTime.now().millisecondsSinceEpoch.remainder(1000000),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      scheduledTime: target,
      isCompleted: widget.initialTask?.isCompleted ?? false,
    );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialTask != null;
    final dateStr = DateFormat('EEE, MMM d, y').format(_selectedDate);
    final timeStr = _selectedTime.format(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit_calendar : Icons.alarm_add,
                      color: Colors.deepPurple,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEditing ? 'Edit Task Alarm' : 'New Task Alarm',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title *',
                    hintText: 'e.g., Take medication',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Task title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 255,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional, max 255 chars)',
                    hintText: 'Enter notes or reminder details',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value != null && value.length > 255) {
                      return 'Description cannot exceed 255 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Alarm Trigger Time',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month, size: 18),
                        label: Text(
                          dateStr,
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(
                          timeStr,
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check),
                      label: Text(isEditing ? 'Update Alarm' : 'Schedule Alarm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
