import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  
  /// 获取保存的语言设置
  static Future<Locale> getSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'zh';
    return Locale(languageCode);
  }
  
  /// 保存语言设置
  static Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }
  
  /// 获取支持的语言列表
  static List<Locale> getSupportedLocales() {
    return [
      const Locale('zh'), // 中文
      const Locale('en'), // 英文
    ];
  }
  
  /// 获取语言显示名称
  static String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'zh':
        return '中文 (简体)';
      case 'en':
        return 'English';
      default:
        return languageCode;
    }
  }
}