import 'package:flutter/material.dart';
import 'screens/alarm_home_screen.dart';
import 'services/alarm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlarmService.instance.initialize();
  runApp(const TaskAlarmApp());
}

/// Root widget configuring the Material 3 app theme.
class TaskAlarmApp extends StatelessWidget {
  const TaskAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Alarm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const TaskAlarmHomeScreen(),
    );
  }
}
