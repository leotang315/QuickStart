import 'dart:io';
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  // 默认pubspec.yaml路径
  String pubspecPath = '../../pubspec.yaml';

  // 如果提供了参数，使用第一个参数作为文件路径
  if (args.isNotEmpty) {
    pubspecPath = args[0];
  }

  final pubspecFile = File(pubspecPath);

  if (!await pubspecFile.exists()) {
    print('Error: $pubspecPath not found');
    exit(1);
  }

  final content = await pubspecFile.readAsString();
  final yaml = loadYaml(content);

  final name = yaml['name'] ?? 'unknown';
  final version = yaml['version'] ?? '1.0.0';

  // 输出为批处理可以解析的格式
  print('PROJECT_NAME=$name');
  print('PROJECT_VERSION=$version');
  // 输出文件名，用于GitHub Actions
  print('INSTALLER_FILENAME=${name}-${version}-windows-setup');
}
