import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileHelper {
  static Future<void> writeEmailToLog(String email) async {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/email_log.txt');
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = '[$timestamp] User opted-in for email notifications with email: $email\n';
      await file.writeAsString(logEntry, mode: FileMode.append);
  }

  static Future<String> readEmailLog() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/email_log.txt');

      if (await file.exists()) {
        return await file.readAsString();
      } else {
        return "Log file not found. No emails have been logged yet.";
      }
    } catch (e) {
      return "An error occurred while reading the log file: $e";
    }
  }
}
