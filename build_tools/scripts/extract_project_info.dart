import 'dart:io';
import 'package:yaml/yaml.dart';

void main() async {
  final pubspecFile = File('../../pubspec.yaml');
  
  if (!await pubspecFile.exists()) {
    print('Error: pubspec.yaml not found');
    exit(1);
  }
  
  final content = await pubspecFile.readAsString();
  final yaml = loadYaml(content);
  
  final name = yaml['name'] ?? 'unknown';
  final version = yaml['version'] ?? '1.0.0';
  
  // 输出为批处理可以解析的格式
  print('PROJECT_NAME=$name');
  print('PROJECT_VERSION=$version');
}