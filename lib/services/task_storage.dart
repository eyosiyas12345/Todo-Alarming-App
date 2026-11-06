import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_alarm.dart';

/// Handles offline task persistence using local storage.
class TaskStorage {
  static const String _storageKey = 'offline_task_alarms';

  Future<List<TaskAlarm>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];
    return jsonList
        .map((item) => TaskAlarm.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTasks(List<TaskAlarm> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }
}
