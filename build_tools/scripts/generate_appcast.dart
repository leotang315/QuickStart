import 'dart:io';

class SignUpdateResult {
  final String signature;
  final int length;

  SignUpdateResult({required this.signature, required this.length});
}

void main(List<String> args) async {
  if (args.length < 5) {
    print(
      'Usage: dart generate_appcast.dart <installer_path> <sign_update_output> <project_name> <project_version> <output_dir>',
    );
    exit(1);
  }

  final installerPath = args[0];
  final signUpdateOutput = args[1];
  final projectName = args[2];
  final version = args[3];
  final outputDir = args[4];

  print('Processing sign update output: $signUpdateOutput');
  print('Project: $projectName v$version');
  print('Output directory: $outputDir');

  try {
    // 修改正则表达式以匹配没有引号的格式
    RegExp regex = RegExp(r'sparkle:(dsa|ed)Signature=([^\s]+)\s+length=(\d+)');
    RegExpMatch? match = regex.firstMatch(signUpdateOutput);

    if (match == null) {
      // 如果第一个正则表达式失败，尝试带引号的格式
      RegExp quotedRegex = RegExp(
        r'sparkle:(dsa|ed)Signature="([^"]+)"\s+length="(\d+)"',
      );
      match = quotedRegex.firstMatch(signUpdateOutput);

      if (match == null) {
        print('Failed to parse sign update output.');
        print(
          'Expected format 1: sparkle:dsaSignature=<signature> length=<number>',
        );
        print(
          'Expected format 2: sparkle:dsaSignature="<signature>" length="<number>"',
        );
        print('Actual output: $signUpdateOutput');
        throw Exception('Failed to parse sign update output');
      }
    }

    final signResult = SignUpdateResult(
      signature: match.group(2)!,
      length: int.tryParse(match.group(3)!) ?? 0,
    );

    print('Extracted signature: ${signResult.signature}');
    print('Extracted length: ${signResult.length}');

    // 获取安装包文件大小（使用实际文件大小，而不是签名输出中的长度）
    final installerFile = File(installerPath);
    if (!await installerFile.exists()) {
      print('Error: Installer file not found: $installerPath');
      exit(1);
    }

    final actualFileSize = await installerFile.length();
    print('Actual installer file size: $actualFileSize bytes');

    // 获取当前时间（RFC 2822 格式）
    final now = DateTime.now().toUtc();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final pubDate =
        '${weekdays[now.weekday - 1]}, ${now.day.toString().padLeft(2, '0')} '
        '${months[now.month - 1]} ${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} GMT';

    // 生成下载文件名
    final fileName = installerFile.uri.pathSegments.last;

    // 生成 appcast.xml 内容
    final appcastXml = '''
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>$projectName Updates</title>
    <description>Updates for $projectName</description>
    <language>en</language>
    <item>
      <title>$projectName $version</title>
      <description><![CDATA[
        <h3>Version $version</h3>
        <ul>
          <li>Bug fixes and improvements</li>
          <li>Performance optimizations</li>
          <li>Enhanced user experience</li>
        </ul>
      ]]></description>
      <pubDate>$pubDate</pubDate>
      <enclosure
        url="http://localhost:80/downloads/$fileName"
        sparkle:version="$version"
        sparkle:dsaSignature="${signResult.signature}"
        length="$actualFileSize"
        type="application/octet-stream" />
    </item>
  </channel>
</rss>
''';

    // 确保输出目录存在
    final outputDirectory = Directory(outputDir);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
      print('Created output directory: ${outputDirectory.path}');
    }

    // 写入 appcast.xml 文件
    final appcastFile = File('$outputDir/appcast.xml');
    await appcastFile.writeAsString(appcastXml);

    print('✓ appcast.xml generated successfully!');
    print('  File: ${appcastFile.absolute.path}');
    print('  Project: $projectName');
    print('  Version: $version');
    print('  File size: $actualFileSize bytes');
    print('  Signature: ${signResult.signature}');
  } catch (e) {
    print('Error generating appcast.xml: $e');
    exit(1);
  }
}
