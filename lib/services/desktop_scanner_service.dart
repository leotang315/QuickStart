import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'log_service.dart';

class BackupItem {
  final String srcPath;
  final String dstPath;

  BackupItem({required this.srcPath, required this.dstPath});

  Map<String, dynamic> toJson() {
    return {'srcPath': srcPath, 'dstPath': dstPath};
  }

  factory BackupItem.fromJson(Map<String, dynamic> json) {
    return BackupItem(srcPath: json['srcPath'], dstPath: json['dstPath']);
  }
}

class BackupInfo {
  final List<BackupItem> items;

  BackupInfo({required this.items});

  Map<String, dynamic> toJson() {
    return {'items': items.map((item) => item.toJson()).toList()};
  }

  factory BackupInfo.fromJson(Map<String, dynamic> json) {
    return BackupInfo(
      items:
          (json['items'] as List)
              .map((item) => BackupItem.fromJson(item))
              .toList(),
    );
  }
}

class DesktopScannerService {
  static const String _backupKey = 'desktop_backup_info';
  static const String _backupFolderName = 'QuickStart_Desktop_Backup';

  List<String> getDesktopPath() {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        return [
          path.join(userProfile, 'Desktop'),
          'C:\\Users\\Public\\Desktop',
        ];
      }
    }
    throw Exception('Failed to get desktop path');
  }

  // Get backup directory in user documents
  Future<String> _getBackupDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final backupDir = path.join(
      documentsDir.path,
      'QuickStart',
      'Desktop_Backup',
    );

    // Ensure backup directory exists
    final dir = Directory(backupDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    return backupDir;
  }

  // Get backup subdirectory for specific desktop path
  Future<String> _getDesktopBackupPath(String desktopPath) async {
    final baseBackupDir = await _getBackupDirectory();

    // Create a safe folder name from desktop path
    String folderName;
    if (desktopPath.contains('Public')) {
      folderName = 'Public_Desktop';
    } else {
      folderName = 'User_Desktop';
    }

    final backupPath = path.join(baseBackupDir, folderName);
    final dir = Directory(backupPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    return backupPath;
  }

  Future<BackupInfo> backupDesktop() async {
    final desktopPaths = getDesktopPath();
    final backupInfo = BackupInfo(items: []);

    // Process each desktop directory
    for (final desktopPath in desktopPaths) {
      final desktopDir = Directory(desktopPath);
      if (!desktopDir.existsSync()) {
        LogService.info('Desktop directory does not exist: $desktopPath');
        continue;
      }

      try {
        // Get backup directory for this desktop path
        final backupPath = await _getDesktopBackupPath(desktopPath);

        LogService.info('Backing up $desktopPath to $backupPath');

        // Scan and backup items in this desktop directory
        final items =
            desktopDir
                .listSync()
                .where((item) => path.basename(item.path) != _backupFolderName)
                .toList();

        for (final item in items) {
          try {
            final fileName = path.basename(item.path);
            final backupItemPath = path.join(backupPath, fileName);

            if (item is File) {
              // Move file to backup location
              await item.rename(backupItemPath);
            } else if (item is Directory) {
              // Move directory to backup location
              await item.rename(backupItemPath);
            }

            final backupItem = BackupItem(
              srcPath: item.path,
              dstPath: backupItemPath,
            );

            backupInfo.items.add(backupItem);
            LogService.info('Successfully backed up: ${item.path}');
          } catch (e) {
            LogService.error('Failed to backup item: ${item.path}', e);
          }
        }
      } catch (e) {
        LogService.error(
          'Failed to process desktop directory: $desktopPath',
          e,
        );
        continue;
      }
    }

    // Save backup information
    await _saveBackupInfo(backupInfo);
    LogService.info('Backup completed with ${backupInfo.items.length} items');
    return backupInfo;
  }

  Future<void> restoreDesktop() async {
    final backupInfo = await _loadBackupInfo();
    if (backupInfo == null) {
      throw Exception(
        'Failed to restore desktop items: No backup information found',
      );
    }

    for (final item in backupInfo.items) {
      try {
        final backupFile = File(item.dstPath);
        final backupDir = Directory(item.dstPath);

        if (backupFile.existsSync()) {
          // Move file back to original location
          await backupFile.rename(item.srcPath);
          LogService.info('Restored file: ${item.srcPath}');
        } else if (backupDir.existsSync()) {
          // Move directory back to original location
          await backupDir.rename(item.srcPath);
          LogService.info('Restored directory: ${item.srcPath}');
        }
      } catch (e) {
        LogService.error('Failed to restore item: ${item.srcPath}', e);
      }
    }

    // Clear backup information
    await _clearBackupInfo();

    // Clean up backup directories
    try {
      final backupBaseDir = await _getBackupDirectory();
      final dir = Directory(backupBaseDir);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        LogService.info('Cleaned up backup directory');
      }
    } catch (e) {
      LogService.error('Failed to clean up backup directory', e);
    }
  }

  // Add getBackupInfo method for compatibility
  Future<BackupInfo?> getBackupInfo() async {
    return await _loadBackupInfo();
  }

  Future<bool> hasBackup() async {
    final backupInfo = await _loadBackupInfo();
    return backupInfo != null;
  }

  Future<void> _saveBackupInfo(BackupInfo backupInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(backupInfo.toJson());
    await prefs.setString(_backupKey, json);
  }

  Future<BackupInfo?> _loadBackupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_backupKey);

    if (json != null) {
      try {
        final data = jsonDecode(json);
        return BackupInfo.fromJson(data);
      } catch (e) {
        LogService.error('Failed to load backup information', e);
      }
    }

    return null;
  }

  Future<void> _clearBackupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backupKey);
  }
}
