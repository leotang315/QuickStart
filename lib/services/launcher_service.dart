import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../models/program.dart';

class LauncherService {
  static final LauncherService _instance = LauncherService._internal();

  factory LauncherService() => _instance;

  LauncherService._internal();

  Future<bool> launchProgram(Program program) async {
    try {
      final file = File(program.path);
      if (await file.exists()) {
        // 创建文件URI
        final Uri fileUri = Uri.file(program.path);

        // 如果有参数，需要处理启动方式
        if (program.arguments != null && program.arguments!.isNotEmpty) {
          // 在Windows上，我们可以使用cmd来启动带参数的程序
          // 创建一个cmd命令来执行程序
          final cmdUri = Uri.parse(
            'cmd:/c start "" "${program.path}" ${program.arguments}',
          );

          // 尝试启动命令
          if (await launchUrl(cmdUri)) {
            return true;
          } else {
            // 如果cmd方式失败，尝试直接启动文件
            return await launchUrl(fileUri);
          }
        } else {
          // 没有参数，直接启动文件
          return await launchUrl(fileUri);
        }
      }
      final Uri fileUri = Uri.file(program.path);
      return await launchUrl(fileUri);
    } catch (e) {
      print('Error launching program: $e');
      return false;
    }
  }
}
