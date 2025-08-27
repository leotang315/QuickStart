import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class DesktopScannerService {
  static const String _backupKey = 'desktop_backup_info';
  static const String _backupFolderName = 'QuickStart_Desktop_Backup';

  /// 获取桌面路径
  String getDesktopPath() {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        return path.join(userProfile, 'Desktop');
      }
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        return path.join(home, 'Desktop');
      }
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        return path.join(home, 'Desktop');
      }
    }
    throw Exception('无法获取桌面路径');
  }

  /// 获取备份文件夹路径
  String getBackupPath() {
    final desktopPath = getDesktopPath();
    return path.join(desktopPath, _backupFolderName);
  }

  /// 扫描桌面文件和快捷方式
  Future<List<DesktopItem>> scanDesktopItems() async {
    final desktopPath = getDesktopPath();
    final directory = Directory(desktopPath);
    final items = <DesktopItem>[];

    if (!directory.existsSync()) {
      throw Exception('桌面目录不存在');
    }

    final entities = directory.listSync();

    for (final entity in entities) {
      if (entity is File) {
        final fileName = path.basename(entity.path);

        // 跳过备份文件夹
        if (fileName == _backupFolderName) continue;

        final extension = path.extension(fileName).toLowerCase();

        // 处理所有文件类型
        final item = DesktopItem(
          name: path.basenameWithoutExtension(fileName),
          originalPath: entity.path,
          type: _getItemType(extension),
          targetPath: await _resolveShortcutTarget(entity.path),
        );
        items.add(item);
      } else if (entity is Directory) {
        final dirName = path.basename(entity.path);

        // 跳过备份文件夹
        if (dirName == _backupFolderName) continue;

        final item = DesktopItem(
          name: dirName,
          originalPath: entity.path,
          type: DesktopItemType.folder,
          targetPath: entity.path,
        );
        items.add(item);
      }
    }

    return items;
  }

  /// 快速备份桌面文件（使用移动而非拷贝）
  Future<BackupInfo> fastBackupDesktopItems(List<DesktopItem> items) async {
    final backupPath = getBackupPath();
    final backupDir = Directory(backupPath);

    // 创建备份文件夹
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }

    final backupInfo = BackupInfo(
      backupPath: backupPath,
      backupTime: DateTime.now(),
      items: [],
    );

    for (final item in items) {
      try {
        final originalFile = File(item.originalPath);
        final originalDir = Directory(item.originalPath);
        final fileName = path.basename(item.originalPath);
        final backupItemPath = path.join(backupPath, fileName);

        if (originalFile.existsSync()) {
          // 直接移动文件到备份位置
          await originalFile.rename(backupItemPath);
        } else if (originalDir.existsSync()) {
          // 直接移动文件夹到备份位置
          await originalDir.rename(backupItemPath);
        }

        final backupItem = BackupItem(
          originalPath: item.originalPath,
          backupPath: backupItemPath,
          name: item.name,
          type: item.type,
        );

        backupInfo.items.add(backupItem);
      } catch (e) {
        print('快速备份文件失败: ${item.originalPath}, 错误: $e');
      }
    }

    // 保存备份信息
    await _saveBackupInfo(backupInfo);

    return backupInfo;
  }

  /// 快速恢复桌面文件（使用移动而非拷贝）
  Future<void> fastRestoreDesktopItems() async {
    final backupInfo = await _loadBackupInfo();
    if (backupInfo == null) {
      throw Exception('没有找到备份信息');
    }

    for (final item in backupInfo.items) {
      try {
        final backupFile = File(item.backupPath);
        final backupDir = Directory(item.backupPath);

        if (backupFile.existsSync()) {
          // 直接移动文件回原位置
          await backupFile.rename(item.originalPath);
        } else if (backupDir.existsSync()) {
          // 直接移动文件夹回原位置
          await backupDir.rename(item.originalPath);
        }
      } catch (e) {
        print('快速恢复文件失败: ${item.originalPath}, 错误: $e');
      }
    }

    // 清除备份信息
    await _clearBackupInfo();

    final backupPath = getBackupPath();
    final backupDir = Directory(backupPath);

    if (backupDir.existsSync()) {
      await backupDir.delete(recursive: true);
    }
  }

  /// 检查是否有备份
  Future<bool> hasBackup() async {
    final backupInfo = await _loadBackupInfo();
    return backupInfo != null;
  }

  /// 获取备份信息
  Future<BackupInfo?> getBackupInfo() async {
    return await _loadBackupInfo();
  }

  // 私有方法
  DesktopItemType _getItemType(String extension) {
    switch (extension.toLowerCase()) {
      case '.exe':
        return DesktopItemType.executable;
      case '.lnk':
        return DesktopItemType.shortcut;
      case '.url':
        return DesktopItemType.urlShortcut;
      case '.app':
      case '.dmg':
      case '.pkg':
      case '.deb':
      case '.rpm':
      case '.appimage':
      case '.desktop':
        return DesktopItemType.executable;
      default:
        return DesktopItemType.file;
    }
  }

  Future<String?> _resolveShortcutTarget(String shortcutPath) async {
    // 这里可以实现快捷方式目标解析
    // 对于Windows .lnk文件，可能需要使用FFI调用Windows API
    // 暂时返回原路径
    return shortcutPath;
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!destination.existsSync()) {
      destination.createSync(recursive: true);
    }

    await for (final entity in source.list()) {
      final newPath = path.join(destination.path, path.basename(entity.path));

      if (entity is File) {
        await entity.copy(newPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      }
    }
  }

  /// 保存备份信息
  Future<void> _saveBackupInfo(BackupInfo backupInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(backupInfo.toJson());
    await prefs.setString(_backupKey, json);
  }

  /// 加载备份信息
  Future<BackupInfo?> _loadBackupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_backupKey);

    if (json != null) {
      try {
        final data = jsonDecode(json);
        return BackupInfo.fromJson(data);
      } catch (e) {
        print('加载备份信息失败: $e');
      }
    }

    return null;
  }

  /// 清除备份信息
  Future<void> _clearBackupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backupKey);
  }
}

/// 桌面项目类型
enum DesktopItemType { executable, shortcut, urlShortcut, folder, file }

/// 桌面项目
class DesktopItem {
  final String name;
  final String originalPath;
  final DesktopItemType type;
  final String? targetPath;

  DesktopItem({
    required this.name,
    required this.originalPath,
    required this.type,
    this.targetPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'originalPath': originalPath,
      'type': type.index,
      'targetPath': targetPath,
    };
  }

  factory DesktopItem.fromJson(Map<String, dynamic> json) {
    return DesktopItem(
      name: json['name'],
      originalPath: json['originalPath'],
      type: DesktopItemType.values[json['type']],
      targetPath: json['targetPath'],
    );
  }
}

/// 备份项目
class BackupItem {
  final String originalPath;
  final String backupPath;
  final String name;
  final DesktopItemType type;

  BackupItem({
    required this.originalPath,
    required this.backupPath,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalPath': originalPath,
      'backupPath': backupPath,
      'name': name,
      'type': type.index,
    };
  }

  factory BackupItem.fromJson(Map<String, dynamic> json) {
    return BackupItem(
      originalPath: json['originalPath'],
      backupPath: json['backupPath'],
      name: json['name'],
      type: DesktopItemType.values[json['type']],
    );
  }
}

/// 备份信息
class BackupInfo {
  final String backupPath;
  final DateTime backupTime;
  final List<BackupItem> items;

  BackupInfo({
    required this.backupPath,
    required this.backupTime,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'backupPath': backupPath,
      'backupTime': backupTime.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory BackupInfo.fromJson(Map<String, dynamic> json) {
    return BackupInfo(
      backupPath: json['backupPath'],
      backupTime: DateTime.parse(json['backupTime']),
      items:
          (json['items'] as List)
              .map((item) => BackupItem.fromJson(item))
              .toList(),
    );
  }
}
