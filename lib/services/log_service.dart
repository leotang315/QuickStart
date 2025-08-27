import 'package:logger/logger.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 日志服务类
/// 提供统一的日志管理功能，支持控制台输出和文件输出
class LogService {
  static LogService? _instance;
  static Logger? _logger;
  
  LogService._internal();
  
  /// 获取单例实例
  static LogService get instance {
    _instance ??= LogService._internal();
    return _instance!;
  }
  
  /// 初始化日志服务
  static Future<void> init({bool enableFileOutput = true}) async {
    List<LogOutput> outputs = [ConsoleOutput()];
    
    // 如果启用文件输出，添加文件输出
    if (enableFileOutput) {
      try {
        final logFile = await _getLogFile();
        outputs.add(FileOutput(file: logFile));
      } catch (e) {
        print('Failed to initialize file logging: $e');
      }
    }
    
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      output: MultiOutput(outputs),
      level: Level.debug,
    );
  }
  
  /// 获取日志文件
  static Future<File> _getLogFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    final logDir = Directory(path.join(appDir.path, 'QuickStart', 'logs'));
    
    if (!logDir.existsSync()) {
      logDir.createSync(recursive: true);
    }
    
    final now = DateTime.now();
    final fileName = 'quickstart_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.log';
    
    return File(path.join(logDir.path, fileName));
  }
  
  /// 调试日志
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.d(message, error: error, stackTrace: stackTrace);
  }
  
  /// 信息日志
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.i(message, error: error, stackTrace: stackTrace);
  }
  
  /// 警告日志
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.w(message, error: error, stackTrace: stackTrace);
  }
  
  /// 错误日志
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.e(message, error: error, stackTrace: stackTrace);
  }
  
  /// 致命错误日志
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.f(message, error: error, stackTrace: stackTrace);
  }
  
  /// 关闭日志服务
  static void close() {
    _logger?.close();
  }
}

/// 自定义文件输出类
class FileOutput extends LogOutput {
  final File file;
  
  FileOutput({required this.file});
  
  @override
  void output(OutputEvent event) {
    try {
      final buffer = StringBuffer();
      for (final line in event.lines) {
        buffer.writeln(line);
      }
      file.writeAsStringSync(buffer.toString(), mode: FileMode.append);
    } catch (e) {
      print('Failed to write log to file: $e');
    }
  }
}