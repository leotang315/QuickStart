import 'package:auto_updater/auto_updater.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'log_service.dart';

class AutoUpdateService {
  static const String _feedUrl = 'http://localhost:80/appcast.xml';

  static bool _isInitialized = false;

  /// 初始化自动更新服务
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 只在桌面平台启用
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await autoUpdater.setFeedURL(_feedUrl);
        await autoUpdater.setScheduledCheckInterval(3600); // 每小时检查一次
        _isInitialized = true;
        LogService.info('AutoUpdater initialized successfully');
      }
    } catch (e) {
      LogService.error('Failed to initialize AutoUpdater', e);
    }
  }

  /// 检查更新
  static Future<bool> checkForUpdates({bool silent = true}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // 检查网络连接
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (!silent) LogService.warning('No internet connection');
        return false;
      }

      // auto_updater 会自动显示更新对话框
      await autoUpdater.checkForUpdates();
      return true;
    } catch (e) {
      if (!silent) LogService.error('Error checking for updates', e);
      return false;
    }
  }

  /// 获取当前应用信息
  static Future<Map<String, String>> getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
    };
  }
}
