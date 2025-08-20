import 'dart:io';
import 'package:yaml/yaml.dart';

void main() async {
  try {
    // 读取pubspec.yaml版本
    final pubspecFile = File('../pubspec.yaml');

    if (!await pubspecFile.exists()) {
      print('❌ Error: pubspec.yaml not found');
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
    await updateInstallerNsi(version);

    print('\n🎉 Version synchronization completed!');
    print('\n📝 Updated files:');
    print('   - installer.nsi');
    print('   - build_installer.bat');
    print('\n💡 Windows and Android versions will be automatically');
    print('   synchronized when you run \'flutter build\'');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

Future<void> updateInstallerNsi(String version) async {
  final nsiFile = File('installer.nsi');

  if (!await nsiFile.exists()) {
    print('❌ Warning: installer.nsi not found');
    return;
  }

  // // 创建备份
  // final backupFile = File('installer.nsi.bak');
  // await nsiFile.copy(backupFile.path);

  var content = await nsiFile.readAsString();

  // 替换版本号
  content = content.replaceAll(
    RegExp(r'!define APP_VERSION "[^"]*"'),
    '!define APP_VERSION "$version"',
  );

  content = content.replaceAll(
    RegExp(r'OutFile "QuickStart-[^"]*-windows-setup\.exe"'),
    'OutFile "QuickStart-$version-windows-setup.exe"',
  );

  await nsiFile.writeAsString(content);
  print('✅ Updated installer.nsi to version $version');
}
