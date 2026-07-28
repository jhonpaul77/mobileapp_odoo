import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Service untuk logging error dan events ke file
/// File log disimpan di: /storage/emulated/0/Android/data/{app}/files/logs/
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  File? _logFile;
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Initialize logger service
  Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');

      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${logsDir.path}/app_log_$date.txt');

      if (!await _logFile!.exists()) {
        await _logFile!.create();
      }

      await _writeLog('✅ [LOGGER] Logger service initialized');
      print('✅ [LOGGER] Log file: ${_logFile!.path}');
    } catch (e) {
      print('❌ [LOGGER] Failed to initialize: $e');
    }
  }

  /// Write log entry
  Future<void> _writeLog(String message) async {
    if (_logFile == null) return;

    try {
      final timestamp = _dateFormat.format(DateTime.now());
      final logEntry = '[$timestamp] $message\n';
      await _logFile!.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      print('❌ [LOGGER] Failed to write log: $e');
    }
  }

  /// Log info message
  Future<void> info(String message) async {
    print('ℹ️ [INFO] $message');
    await _writeLog('INFO: $message');
  }

  /// Log error message
  Future<void> error(String message,
      [dynamic error, StackTrace? stackTrace]) async {
    print('❌ [ERROR] $message');
    if (error != null) print('   Error: $error');
    if (stackTrace != null) print('   Stack: $stackTrace');

    await _writeLog('ERROR: $message');
    if (error != null) await _writeLog('   Error: $error');
    if (stackTrace != null) await _writeLog('   Stack: $stackTrace');
  }

  /// Log warning message
  Future<void> warning(String message) async {
    print('⚠️ [WARNING] $message');
    await _writeLog('WARNING: $message');
  }

  /// Log debug message
  Future<void> debug(String message) async {
    print('🐛 [DEBUG] $message');
    await _writeLog('DEBUG: $message');
  }

  /// Log API request
  Future<void> apiRequest(String method, String url,
      {Map<String, dynamic>? headers, dynamic body}) async {
    final message = 'API Request: $method $url';
    print('📡 [API] $message');
    await _writeLog(message);
    if (headers != null) await _writeLog('   Headers: $headers');
    if (body != null) await _writeLog('   Body: $body');
  }

  /// Log API response
  Future<void> apiResponse(int statusCode, String url, {dynamic body}) async {
    final message = 'API Response: $statusCode $url';
    print('📥 [API] $message');
    await _writeLog(message);
    if (body != null) await _writeLog('   Body: $body');
  }

  /// Get log file path
  String? get logFilePath => _logFile?.path;

  /// Read all logs
  Future<String> readLogs() async {
    if (_logFile == null || !await _logFile!.exists()) {
      return 'No logs available';
    }
    return await _logFile!.readAsString();
  }

  /// Clear logs
  Future<void> clearLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.delete();
      await _logFile!.create();
      await _writeLog('✅ [LOGGER] Logs cleared');
    }
  }

  /// Get all log files
  Future<List<File>> getAllLogFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');

      if (!await logsDir.exists()) {
        return [];
      }

      return logsDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.txt'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path)); // Latest first
    } catch (e) {
      print('❌ [LOGGER] Failed to get log files: $e');
      return [];
    }
  }
}
