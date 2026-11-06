import 'package:intl/intl.dart';

/// TaskAlarm model representing an offline alarm task.
class TaskAlarm {
  final int id;
  final String title;
  final String description;
  final DateTime scheduledTime;
  final bool isCompleted;

  const TaskAlarm({
    required this.id,
    required this.title,
    this.description = '',
    required this.scheduledTime,
    this.isCompleted = false,
  });

  bool get isDue => DateTime.now().isAfter(scheduledTime);

  String get formattedDate => DateFormat('EEE, MMM d, y').format(scheduledTime);

  String get formattedTime => DateFormat('hh:mm a').format(scheduledTime);

  TaskAlarm copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? scheduledTime,
    bool? isCompleted,
  }) {
    return TaskAlarm(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'scheduledTime': scheduledTime.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory TaskAlarm.fromJson(Map<String, dynamic> json) {
    return TaskAlarm(
      id: json['id'] as int,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      isCompleted: (json['isCompleted'] as bool?) ?? false,
    );
  }
}
