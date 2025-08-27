import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'models/program.dart';
import 'services/database_service.dart';
import 'services/launcher_service.dart';
import 'services/language_service.dart';
import 'services/auto_update_service.dart';
import 'services/log_service.dart';
import 'screens/home_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 sqflite_ffi
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // 初始化窗口管理器
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = WindowOptions(
    size: Size(800, 600),
    center: true,
    title: '程序快速启动器',
    minimumSize: Size(400, 300),
    windowButtonVisibility: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 初始化热键管理器
  await hotKeyManager.unregisterAll();

  // 初始化日志服务
  await LogService.init(enableFileOutput: true);
  LogService.info('Application started');

  // 初始化自动更新服务
  await AutoUpdateService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _setupAutoUpdate();
  }

  Future<void> _loadLanguage() async {
    final locale = await LanguageService.getSavedLanguage();
    setState(() {
      _locale = locale;
    });
  }

  void _setupAutoUpdate() {
    // 延迟检查更新，避免影响启动速度
    Future.delayed(const Duration(seconds: 3), () {
      AutoUpdateService.checkForUpdates();
    });
  }

  void changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
    LanguageService.saveLanguage(locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickStart',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LanguageService.getSupportedLocales(),
      home: HomeScreen(onLanguageChanged: changeLanguage),
      debugShowCheckedModeBanner: false,
    );
  }
}
