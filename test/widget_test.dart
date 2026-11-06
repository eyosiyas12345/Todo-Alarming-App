import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_alarm/models/task_alarm.dart';
import 'package:task_alarm/screens/alarm_home_screen.dart';
import 'package:task_alarm/widgets/task_form_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TaskAlarm Model Tests', () {
    test('TaskAlarm JSON serialization and deserialization', () {
      final scheduled = DateTime(2026, 12, 1, 10, 30);
      final task = TaskAlarm(
        id: 101,
        title: 'Meeting reminder',
        description: 'Standup with team',
        scheduledTime: scheduled,
        isCompleted: false,
      );

      final json = task.toJson();
      expect(json['id'], 101);
      expect(json['title'], 'Meeting reminder');
      expect(json['description'], 'Standup with team');

      final deserialized = TaskAlarm.fromJson(json);
      expect(deserialized.id, task.id);
      expect(deserialized.title, task.title);
      expect(deserialized.description, task.description);
      expect(deserialized.scheduledTime, task.scheduledTime);
      expect(deserialized.isCompleted, false);
    });

    test('TaskAlarm copyWith toggles isCompleted', () {
      final task = TaskAlarm(
        id: 102,
        title: 'Workout',
        scheduledTime: DateTime(2026, 11, 8, 7, 0),
        isCompleted: false,
      );

      final updated = task.copyWith(isCompleted: true);
      expect(updated.isCompleted, true);
      expect(updated.title, task.title);
    });

    test('TaskAlarm formatted strings', () {
      final date = DateTime(2026, 5, 20, 14, 15);
      final task = TaskAlarm(
        id: 1,
        title: 'Doctor appointment',
        scheduledTime: date,
      );

      expect(task.formattedDate.isNotEmpty, true);
      expect(task.formattedTime.isNotEmpty, true);
    });
  });

  group('TaskAlarmHomeScreen Widget Tests', () {
    testWidgets('Renders AppBar and Empty State', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskAlarmHomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Offline Task Alarms'), findsOneWidget);
      expect(find.text('No Active Alarms'), findsOneWidget);
      expect(find.text('Add Alarm'), findsOneWidget);
    });
  });

  group('TaskFormDialog Widget Tests', () {
    testWidgets('Renders New Task Form', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TaskFormDialog()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Task Alarm'), findsOneWidget);
      expect(find.text('Schedule Alarm'), findsOneWidget);
    });

    testWidgets('Renders Edit Task Form with initial values', (WidgetTester tester) async {
      final existingTask = TaskAlarm(
        id: 201,
        title: 'Read a book',
        description: 'Read 20 pages',
        scheduledTime: DateTime.now().add(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TaskFormDialog(initialTask: existingTask)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Task Alarm'), findsOneWidget);
      expect(find.text('Update Alarm'), findsOneWidget);
      expect(find.text('Read a book'), findsOneWidget);
      expect(find.text('Read 20 pages'), findsOneWidget);
    });
  });
}
