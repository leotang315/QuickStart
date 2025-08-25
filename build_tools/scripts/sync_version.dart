import 'dart:io';
import 'package:yaml/yaml.dart';

void main() async {
  // 路径配置变量
  const pubspecPath = '../../pubspec.yaml';
  const installerNsiPath = './installer.nsi';
  const backupPath = './installer.nsi.bak';

  try {
    // 读取pubspec.yaml版本
    final pubspecFile = File(pubspecPath);

    if (!await pubspecFile.exists()) {
      print('❌ Error: pubspec.yaml not found at $pubspecPath');
      exit(1);
    }

    final pubspecContent = await pubspecFile.readAsString();
    final pubspec = loadYaml(pubspecContent);
    final version = pubspec['version'] as String?;

    if (version == null || version.isEmpty) {
      print('❌ Error: Version not found in pubspec.yaml');
      exit(1);
    }

    print('📦 Found version: $version');

    // 更新installer.nsi
    await updateInstallerNsi(version, installerNsiPath, backupPath);

    print('\n🎉 Version synchronization completed!');
    print('\n📝 Updated files:');
    print('   - installer.nsi');
    print('   - build_installer.bat');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

Future<void> updateInstallerNsi(
  String version,
  String nsiPath,
  String backupPath,
) async {
  final nsiFile = File(nsiPath);

  if (!await nsiFile.exists()) {
    print('❌ Warning: installer.nsi not found at $nsiPath');
    return;
  }

  // 创建备份（可选）
  // final backupFile = File(backupPath);
  // await nsiFile.copy(backupFile.path);
  // print('📋 Created backup: $backupPath');

  var content = await nsiFile.readAsString();

  // 替换版本号
  content = content.replaceAll(
    RegExp(r'!define APP_VERSION "[^"]*"'),
    '!define APP_VERSION "$version"',
  );

  // 更新正则表达式以匹配包含路径的 OutFile 行
  content = content.replaceAll(
    RegExp(r'OutFile "[^"]*QuickStart-[^"]*-windows-setup\.exe"'),
    'OutFile "\${PROJECT_ROOT}\\\\dist\\\\QuickStart-$version-windows-setup.exe"',
  );

  await nsiFile.writeAsString(content);
  print('✅ Updated installer.nsi to version $version');
}
