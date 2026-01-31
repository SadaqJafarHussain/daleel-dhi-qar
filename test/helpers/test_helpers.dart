import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Test utilities and helpers
class TestHelpers {
  static String? _tempPath;

  /// Initialize Hive for testing with a temporary directory
  static Future<void> initHiveForTesting() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Create a unique temp directory for each test run
    final tempDir = await Directory.systemTemp.createTemp('hive_test_');
    _tempPath = tempDir.path;
    Hive.init(_tempPath);
  }

  /// Clean up Hive after tests
  static Future<void> cleanupHive() async {
    await Hive.close();
    if (_tempPath != null) {
      final tempDir = Directory(_tempPath!);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      _tempPath = null;
    }
  }

  /// Get current day of week (0=Sunday format)
  static int getCurrentDayOfWeek() {
    return DateTime.now().weekday % 7;
  }

  /// Get work days string that includes today
  static String getWorkDaysIncludingToday() {
    final today = getCurrentDayOfWeek();
    return List.generate(7, (i) => i.toString()).join(',');
  }

  /// Get work days string that excludes today
  static String getWorkDaysExcludingToday() {
    final today = getCurrentDayOfWeek();
    return List.generate(7, (i) => i)
        .where((i) => i != today)
        .map((i) => i.toString())
        .join(',');
  }

  /// Get current time formatted as HH:mm
  static String getCurrentTimeFormatted() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// Get time N hours from now formatted as HH:mm
  static String getTimeHoursFromNow(int hours) {
    final time = DateTime.now().add(Duration(hours: hours));
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Get time N hours ago formatted as HH:mm
  static String getTimeHoursAgo(int hours) {
    final time = DateTime.now().subtract(Duration(hours: hours));
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Extension for easier time-based testing
extension DateTimeTestExtension on DateTime {
  /// Get the day of week in 0=Sunday format
  int get dayOfWeekSundayFormat => weekday % 7;

  /// Format as HH:mm
  String get timeFormatted =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
