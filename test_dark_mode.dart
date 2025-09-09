import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lib/screens/health/medicine_directory_screen.dart';
import 'lib/screens/doctor/doctor_search_screen.dart';
import 'lib/constants/app_theme.dart';

/// Test app to verify dark mode responsiveness
class DarkModeTestApp extends StatefulWidget {
  const DarkModeTestApp({super.key});

  @override
  State<DarkModeTestApp> createState() => _DarkModeTestAppState();
}

class _DarkModeTestAppState extends State<DarkModeTestApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Dark Mode Test',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Dark Mode Test'),
            actions: [
              Switch(
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                },
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isDarkMode ? 'Dark Mode' : 'Light Mode',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MedicineDirectoryScreen(),
                      ),
                    );
                  },
                  child: const Text('Medicine Directory'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DoctorSearchScreen(),
                      ),
                    );
                  },
                  child: const Text('Doctor Search'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const DarkModeTestApp());
}
