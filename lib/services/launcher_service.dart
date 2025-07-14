import 'dart:io';
import 'package:process_run/process_run.dart';
import '../models/program.dart';

class LauncherService {
  static final LauncherService _instance = LauncherService._internal();

  factory LauncherService() => _instance;

  LauncherService._internal();

  Future<bool> launchProgram(Program program) async {
    try {
      final file = File(program.path);
      if (await file.exists()) {
        final command = program.arguments != null
            ? '${program.path} ${program.arguments}'
            : program.path;
        await run(command);
        return true;
      }
      return false;
    } catch (e) {
      print('Error launching program: $e');
      return false;
    }
  }

  Future<String?> pickProgramPath() async {
    // 使用file_picker包实现文件选择
    // 实际实现需要添加相应代码
    return null;
  }
}
