import 'dart:io';
import 'dart:convert';
import 'package:yaml/yaml.dart';

// Build configuration
class BuildConfig {
  final String configuration;
  final bool clean;
  final bool verbose;
  final String? target;
  final bool outputProjectInfo;
  final String outputFormat;

  BuildConfig({
    this.configuration = 'Release',
    this.clean = false,
    this.verbose = false,
    this.target,
    this.outputProjectInfo = false,
    this.outputFormat = 'env',
  });
}

// Project information
class ProjectInfo {
  final String name;
  final String displayName;
  final String version;
  final String description;
  final String installerFilename;
  final String appId;
  final String publisher;
  final String homepage;
  final String repository;
  final String changelog;

  static String get projectRoot {
    final scriptFile = File(Platform.script.toFilePath());
    return scriptFile.parent.parent.parent.path;
  }

  static String get scriptsDir =>
      '$projectRoot${Platform.pathSeparator}build_tools${Platform.pathSeparator}scripts';
  static String get buildDir =>
      '$projectRoot${Platform.pathSeparator}build${Platform.pathSeparator}windows${Platform.pathSeparator}x64${Platform.pathSeparator}runner${Platform.pathSeparator}Release';
  static String get updaterDir =>
      '$projectRoot${Platform.pathSeparator}dist${Platform.pathSeparator}updater';
  static String get installerDir =>
      '$projectRoot${Platform.pathSeparator}dist${Platform.pathSeparator}installer';
  static String get keyPrivatePath =>
      '$projectRoot${Platform.pathSeparator}build_tools${Platform.pathSeparator}keys${Platform.pathSeparator}dsa_priv.pem';
  static String get pubspecPath =>
      '$projectRoot${Platform.pathSeparator}pubspec.yaml';
  static String get changelogPath =>
      '$projectRoot${Platform.pathSeparator}docs${Platform.pathSeparator}CHANGELOG.md';
  static String get distDir => '$projectRoot${Platform.pathSeparator}dist';
  static String get appcastPath =>
      '$updaterDir${Platform.pathSeparator}appcast.xml';
  String get installerOutputPath =>
      '${ProjectInfo.installerDir}${Platform.pathSeparator}$installerFilename';
  String get buildOutputPath =>
      '${ProjectInfo.buildDir}${Platform.pathSeparator}$name.exe';

  ProjectInfo({
    required this.name,
    required this.displayName,
    required this.version,
    required this.description,
    required this.installerFilename,
    required this.appId,
    required this.publisher,
    required this.homepage,
    required this.repository,
    required this.changelog,
  });

  factory ProjectInfo.fromYaml(dynamic yaml) {
    final name = yaml['name'] ?? 'unknown';
    final version = yaml['version'] ?? '1.0.0';
    final changelog = _extractChangelog(version);

    return ProjectInfo(
      name: name,
      displayName: yaml['display_name'] ?? name,
      version: version,
      description: yaml['description'] ?? '',
      installerFilename: '$name-$version-windows-setup',
      appId: 'com.$name.app',
      publisher: yaml['publisher'] ?? 'Unknown Publisher',
      homepage: yaml['homepage'] ?? '',
      repository: yaml['repository'] ?? '',
      changelog: changelog,
    );
  }

  // Extract changelog content for specific version
  static String _extractChangelog(String version) {
    try {
      final changelogFile = File(changelogPath);
      if (!changelogFile.existsSync()) {
        return 'Release $version';
      }

      final content = changelogFile.readAsStringSync();
      final lines = content.split('\n');

      // Remove 'v' prefix if present
      final versionNoV =
          version.startsWith('v') ? version.substring(1) : version;

      // Find the start line for this version
      int? startLine;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('## [$versionNoV]')) {
          startLine = i;
          break;
        }
      }

      if (startLine == null) {
        return 'Release $version';
      }

      // Find the next version section
      int? endLine;
      for (int i = startLine + 1; i < lines.length; i++) {
        if (lines[i].startsWith('## [')) {
          endLine = i;
          break;
        }
      }

      // Extract content between start and end
      final extractedLines =
          endLine != null
              ? lines.sublist(startLine, endLine)
              : lines.sublist(startLine);

      return extractedLines.join('\n').trim();
    } catch (e) {
      return 'Release $version';
    }
  }

  // Convert to map for output
  Map<String, String> toMap() {
    return {
      'name': name,
      'display_name': displayName,
      'version': version,
      'description': description,
      'installer_filename': installerFilename,
      'app_id': appId,
      'publisher': publisher,
      'homepage': homepage,
      'repository': repository,
      'changelog': changelog,
      'pubspec_path': ProjectInfo.pubspecPath,
      'changelog_path': ProjectInfo.changelogPath,

      'project_root': ProjectInfo.projectRoot,
      'scripts_dir': ProjectInfo.scriptsDir,
      'build_dir': ProjectInfo.buildDir,
      'dist_dir': ProjectInfo.distDir,
      'updater_dir': ProjectInfo.updaterDir,
      'installer_dir': ProjectInfo.installerDir,
      'key_private_path': ProjectInfo.keyPrivatePath,
      'installer_output_path': installerOutputPath,
      'build_output_path': buildOutputPath,
      'appcast_path': ProjectInfo.appcastPath,
    };
  }

  // Output project info in different formats
  void outputProjectInfo(String format) {
    final info = toMap();

    switch (format.toLowerCase()) {
      case 'json':
        stdout.write(jsonEncode(info));
        break;
      case 'yaml':
        info.forEach((key, value) => stdout.writeln('$key: $value'));
        break;
      case 'env':
      default:
        // GitHub Actions environment variable format
        info.forEach((key, value) {
          final envKey = key.toUpperCase().replaceAll(' ', '_');
          stdout.writeln('$envKey=$value');
        });
        break;
    }
  }
}

// Sign update result
class SignUpdateResult {
  final String signature;
  final int length;

  SignUpdateResult({required this.signature, required this.length});
}

// Build steps
class BuildSteps {
  final ProjectInfo projectInfo;
  final BuildConfig config;

  BuildSteps(this.projectInfo, this.config);

  // Get project information from pubspec.yaml
  static Future<ProjectInfo> getProjectInfo([bool silent = false]) async {
    if (!silent) {
      print('📋 Getting project information...');
    }

    // Find pubspec.yaml file
    final pubspecFile = File(ProjectInfo.pubspecPath);

    if (!await pubspecFile.exists()) {
      throw Exception('pubspec.yaml not found at: ${pubspecFile.path}');
    }

    try {
      // Read and parse pubspec.yaml
      final content = await pubspecFile.readAsString();
      final yaml = loadYaml(content);

      return ProjectInfo.fromYaml(yaml);
    } catch (e) {
      throw Exception('Error parsing pubspec.yaml: $e');
    }
  }

  // Validate build environment
  Future<void> validateEnvironment() async {
    print('🔍 Validating build environment...');

    try {
      // Check if Flutter is installed
      final flutterResult = await Process.run('flutter', [
        '--version',
      ], runInShell: true);
      if (flutterResult.exitCode != 0) {
        throw Exception(
          'Flutter not found in PATH. Please install Flutter and add it to your PATH.',
        );
      }
      print('   ✓ Flutter found');
    } catch (e) {
      throw Exception(
        'Flutter not found in PATH. Please install Flutter and add it to your PATH.',
      );
    }

    try {
      // Check if Dart is available
      final dartResult = await Process.run('dart', [
        '--version',
      ], runInShell: true);
      if (dartResult.exitCode != 0) {
        throw Exception(
          'Dart not found in PATH. Dart should be included with Flutter installation.',
        );
      }
      print('   ✓ Dart found');
    } catch (e) {
      throw Exception(
        'Dart not found in PATH. Dart should be included with Flutter installation.',
      );
    }

    // Check if Inno Setup is available for Windows builds
    final platform = config.target ?? _detectPlatform();
    if (platform == 'windows') {
      try {
        final isccResult = await Process.run('iscc', [], runInShell: true);
        if (isccResult.exitCode == 0 ||
            isccResult.stderr.toString().contains('Usage:')) {
          print('   ✓ Inno Setup found');
        } else {
          print(
            '   ⚠️  Warning: Inno Setup not found in PATH. Installer creation may fail.',
          );
        }
      } catch (e) {
        print(
          '   ⚠️  Warning: Inno Setup not found in PATH. Installer creation may fail.',
        );
      }
    }

    // Check if pubspec.yaml exists
    final pubspecFile = File(ProjectInfo.pubspecPath);
    if (!await pubspecFile.exists()) {
      print(
        '   ⚠️  Warning: pubspec.yaml not found at ${ProjectInfo.pubspecPath}.',
      );
    } else {
      print('   ✓ pubspec.yaml found');
    }

    // Check if CHANGELOG.md exists
    final changelogFile = File(ProjectInfo.changelogPath);
    if (!await changelogFile.exists()) {
      print(
        '   ⚠️  Warning: CHANGELOG.md not found at ${ProjectInfo.changelogPath}. Default changelog will be used.',
      );
    } else {
      print('   ✓ CHANGELOG.md found');
    }

    // Check if OpenSSL is available for auto-update signing
    try {
      final opensslResult = await Process.run('openssl', [
        'version',
      ], runInShell: true);
      if (opensslResult.exitCode == 0) {
        print('   ✓ OpenSSL found');
      } else {
        print(
          '   ⚠️  Warning: OpenSSL not working properly. Auto-update signing may fail.',
        );
      }
    } catch (e) {
      print(
        '   ⚠️  Warning: OpenSSL not found in PATH. Auto-update signing will fail.',
      );
    }

    // Check if private key exists
    final keyFile = File(ProjectInfo.keyPrivatePath);
    if (!await keyFile.exists()) {
      print(
        '   ⚠️  Warning: Private key not found at ${ProjectInfo.keyPrivatePath}. Auto-update signing will be skipped.',
      );
    } else {
      print('   ✓ Private key found');
    }

    print('✅ Environment validation completed');
  }

  // Initialize directories and clean build artifacts
  Future<void> initializeDirectories() async {
    print('📁 Initializing directories...');

    // Clean existing dist directory if clean flag is set
    if (config.clean) {
      final distDir = Directory(ProjectInfo.distDir);
      if (await distDir.exists()) {
        print('🧹 Cleaning existing dist directory...');
        await distDir.delete(recursive: true);
      }
    }

    // Create necessary directories
    final directories = [
      Directory(ProjectInfo.distDir),
      Directory(ProjectInfo.installerDir),
      Directory(ProjectInfo.updaterDir),
    ];

    for (final dir in directories) {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        print('   Created: ${dir.path}');
      }
    }

    print('✅ Directories initialized');

    // Clean build artifacts if clean flag is set
    print('🧹 Cleaning build artifacts...');

    final result = await Process.run(
      'flutter',
      ['clean'],
      workingDirectory: ProjectInfo.projectRoot,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      throw Exception('Flutter clean failed: ${result.stderr}');
    }

    print('✅ Clean completed');
  }

  // Get dependencies and build Flutter application
  Future<void> buildFlutterApp() async {
    // Get Flutter dependencies
    print('📦 Getting Flutter dependencies...');

    final pubGetResult = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: ProjectInfo.projectRoot,
      runInShell: true,
    );

    if (pubGetResult.exitCode != 0) {
      throw Exception('Flutter pub get failed: ${pubGetResult.stderr}');
    }

    print('✅ Dependencies retrieved');

    // Build Flutter application
    print('🔨 Building Flutter application...');

    final platform = config.target ?? _detectPlatform();
    print('   Target: $platform');
    print('   Configuration: ${config.configuration}');

    final args = ['build', platform];

    if (config.configuration.toLowerCase() == 'release') {
      args.add('--release');
    } else {
      args.add('--debug');
    }

    if (config.verbose) {
      args.add('--verbose');
    }

    final buildResult = await Process.run(
      'flutter',
      args,
      workingDirectory: ProjectInfo.projectRoot,
      runInShell: true,
    );

    if (buildResult.exitCode != 0) {
      throw Exception('Flutter build failed: ${buildResult.stderr}');
    }

    // Verify build output
    final buildOutput = File(projectInfo.buildOutputPath);
    if (!await buildOutput.exists()) {
      throw Exception('Build output not found at: ${buildOutput.path}');
    }

    print('✅ Flutter build completed');
  }

  // Create installer
  Future<void> createInstaller() async {
    final platform = config.target ?? _detectPlatform();

    if (platform == 'windows') {
      await _createWindowsInstaller();
    } else {
      print('⚠️  Installer creation not supported for $platform');
    }
  }

  // Create Windows installer using Inno Setup
  Future<void> _createWindowsInstaller() async {
    print('📦 Creating Windows installer...');

    // Check if Inno Setup is available
    final isccPaths = [
      'C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe',
      'C:\\Program Files\\Inno Setup 6\\ISCC.exe',
      'iscc', // If in PATH
    ];

    String? isccPath;
    for (final path in isccPaths) {
      if (await File(path).exists() || path == 'iscc') {
        isccPath = path;
        break;
      }
    }

    if (isccPath == null) {
      throw Exception(
        'Inno Setup not found. Please install Inno Setup and add it to your PATH.',
      );
    }

    final installerOutputPath = projectInfo.installerOutputPath;

    final result = await Process.run(
      isccPath,
      [
        '/DPROJECT_ROOT=${ProjectInfo.projectRoot}',
        '/DPROJECT_OUTPUT=$installerOutputPath',
        'installer.iss',
      ],
      workingDirectory: ProjectInfo.scriptsDir,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      throw Exception('Installer creation failed: ${result.stderr}');
    }

    // Verify installer was created
    final installerFile = File('$installerOutputPath.exe');
    if (!await installerFile.exists()) {
      throw Exception('Installer file not found at: ${installerFile.path}');
    }

    final fileSize = await installerFile.length();
    print(
      '✅ Windows installer created: ${projectInfo.installerFilename}.exe (Size: $fileSize bytes)',
    );
  }

  // Generate update files
  Future<void> generateUpdateFiles() async {
    print('🔄 Generating update files...');

    // Check if private key exists
    final keyFile = File(ProjectInfo.keyPrivatePath);
    if (!await keyFile.exists()) {
      print('⚠️  Private key not found, skipping auto-update signing');
      return;
    }

    final installerPath = '${projectInfo.installerOutputPath}.exe';

    try {
      // Generate signature using auto_updater
      final signResult = await Process.run(
        'dart',
        [
          'run',
          'auto_updater:sign_update',
          installerPath,
          ProjectInfo.keyPrivatePath,
        ],
        workingDirectory: ProjectInfo.projectRoot,
        runInShell: true,
      );

      if (signResult.exitCode != 0) {
        throw Exception('Failed to generate signature: ${signResult.stderr}');
      }

      final signOutput = signResult.stdout.toString().trim();
      print('   Signature generated: $signOutput');

      // Generate appcast.xml
      await _generateAppcast(installerPath, signOutput);

      print('✅ Update files generated');
    } catch (e) {
      print('⚠️  Update file generation failed: $e');
    }
  }

  // Generate appcast.xml file
  Future<void> _generateAppcast(String installerPath, String signOutput) async {
    print('   Generating appcast.xml...');

    try {
      // Parse signature output
      final signResult = _parseSignOutput(signOutput);

      // Get installer file size
      final installerFile = File(installerPath);
      if (!await installerFile.exists()) {
        throw Exception('Installer file not found: $installerPath');
      }

      final actualFileSize = await installerFile.length();
      print('   Actual installer file size: $actualFileSize bytes');

      // Generate RFC 2822 formatted date
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

      // Generate download filename
      final fileName = installerFile.uri.pathSegments.last;

      // Generate GitHub release download URL
      final downloadUrl = '${projectInfo.repository}/releases/download/v${projectInfo.version}/$fileName';
      
      // Generate appcast.xml content
      final appcastXml = '''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>${projectInfo.displayName} Updates</title>
    <description>Updates for ${projectInfo.displayName}</description>
    <language>en</language>
    <item>
      <title>${projectInfo.displayName} ${projectInfo.version}</title>
      <description><![CDATA[
        ${projectInfo.changelog}
      ]]></description>
      <pubDate>$pubDate</pubDate>
      <enclosure
        url="$downloadUrl"
        sparkle:version="${projectInfo.version}"
        sparkle:dsaSignature="${signResult.signature}"
        length="$actualFileSize"
        type="application/octet-stream" />
    </item>
  </channel>
</rss>
''';

      // Write appcast.xml file
      final appcastFile = File(ProjectInfo.appcastPath);
      await appcastFile.writeAsString(appcastXml);

      print('   ✓ appcast.xml generated successfully!');
      print('     File: ${appcastFile.absolute.path}');
      print('     Project: ${projectInfo.displayName}');
      print('     Version: ${projectInfo.version}');
      print('     File size: $actualFileSize bytes');
      print('     Signature: ${signResult.signature}');
    } catch (e) {
      throw Exception('Error generating appcast.xml: $e');
    }
  }

  // Parse sign update output
  SignUpdateResult _parseSignOutput(String signOutput) {
    // Try format without quotes first
    RegExp regex = RegExp(r'sparkle:(dsa|ed)Signature=([^\s]+)\s+length=(\d+)');
    RegExpMatch? match = regex.firstMatch(signOutput);

    if (match == null) {
      // Try format with quotes
      RegExp quotedRegex = RegExp(
        r'sparkle:(dsa|ed)Signature="([^"]+)"\s+length="(\d+)"',
      );
      match = quotedRegex.firstMatch(signOutput);

      if (match == null) {
        throw Exception('Failed to parse sign update output: $signOutput');
      }
    }

    return SignUpdateResult(
      signature: match.group(2)!,
      length: int.tryParse(match.group(3)!) ?? 0,
    );
  }

  // Detect current platform
  String _detectPlatform() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    throw Exception('Unsupported platform: ${Platform.operatingSystem}');
  }
}

// Main build function
Future<void> main(List<String> args) async {
  try {
    // Parse command line arguments
    final config = _parseArguments(args);

    // If only outputting project info, do that and exit
    if (config.outputProjectInfo) {
      final projectInfo = await BuildSteps.getProjectInfo(true);
      projectInfo.outputProjectInfo(config.outputFormat);
      return;
    }

    // Get project information
    final projectInfo = await BuildSteps.getProjectInfo();

    print('🚀 Building ${projectInfo.displayName} v${projectInfo.version}');
    print('   Platform: ${config.target ?? _detectPlatform()}');
    print('   Configuration: ${config.configuration}');
    print('');

    final buildSteps = BuildSteps(projectInfo, config);

    // Execute build steps
    await buildSteps.validateEnvironment();
    await buildSteps.initializeDirectories();
    await buildSteps.buildFlutterApp();
    await buildSteps.createInstaller();
    await buildSteps.generateUpdateFiles();

    // Check if appcast.xml was generated
    final appcastFile = File(ProjectInfo.appcastPath);
    final hasAppcast = await appcastFile.exists();

    print('');
    print('🎉 Build completed successfully!');
    print('   Project: ${projectInfo.displayName} v${projectInfo.version}');
    print('   Installer: ${projectInfo.installerFilename}.exe');
    if (hasAppcast) {
      print('   Appcast: ${appcastFile.path}');
    }
  } catch (e) {
    print('');
    print('❌ Build failed: $e');
    exit(1);
  }
}

// Parse command line arguments
BuildConfig _parseArguments(List<String> args) {
  String configuration = 'Release';
  bool clean = false;
  bool verbose = false;
  String? target;
  bool outputProjectInfo = false;
  String outputFormat = 'env';

  for (int i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--configuration':
      case '-c':
        if (i + 1 < args.length) {
          configuration = args[++i];
        }
        break;
      case '--clean':
        clean = true;
        break;
      case '--verbose':
      case '-v':
        verbose = true;
        break;
      case '--target':
      case '-t':
        if (i + 1 < args.length) {
          target = args[++i];
        }
        break;
      case '--project-info':
        outputProjectInfo = true;
        break;
      case '--format':
        if (i + 1 < args.length) {
          outputFormat = args[++i];
        }
        break;
      case '--help':
      case '-h':
        _printUsage();
        exit(0);
    }
  }

  return BuildConfig(
    configuration: configuration,
    clean: clean,
    verbose: verbose,
    target: target,
    outputProjectInfo: outputProjectInfo,
    outputFormat: outputFormat,
  );
}

// Print usage information
void _printUsage() {
  print('Usage: dart build.dart [options]');
  print('');
  print('Options:');
  print(
    '  -c, --configuration <config>  Build configuration (Debug/Release) [default: Release]',
  );
  print(
    '  -t, --target <platform>       Target platform (windows/linux/macos)',
  );
  print('      --clean                   Clean before build');
  print('  -v, --verbose                 Verbose output');
  print('      --project-info            Output project information only');
  print(
    '      --format <format>         Output format for project info (env/json/yaml) [default: env]',
  );
  print('  -h, --help                    Show this help message');
  print('');
  print('Examples:');
  print(
    '  dart build.dart                           # Build release for current platform',
  );
  print(
    '  dart build.dart --clean --verbose         # Clean build with verbose output',
  );
  print('  dart build.dart -c Debug -t linux         # Debug build for Linux');
  print(
    '  dart build.dart --project-info            # Output project info in env format',
  );
  print(
    '  dart build.dart --project-info --format json  # Output project info in JSON format',
  );
}

// Detect current platform
String _detectPlatform() {
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  if (Platform.isMacOS) return 'macos';
  throw Exception('Unsupported platform: ${Platform.operatingSystem}');
}
