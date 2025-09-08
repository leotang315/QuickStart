import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../models/category.dart';

/// 类别本地化辅助类
/// 提供统一的类别名称国际化处理
class CategoryLocalizationHelper {
  /// 获取本地化的类别名称
  /// 
  /// 对于桌面类别，返回多语言翻译
  /// 对于其他类别，返回原始名称
  static String getLocalizedCategoryName(BuildContext context, String categoryName) {
    if (categoryName == DatabaseService.defaultDesktopCategoryName) {
      return AppLocalizations.of(context)!.desktopCategory;
    }
    return categoryName;
  }

  /// 获取本地化的类别名称（通过Category对象）
  static String getLocalizedCategoryNameFromCategory(BuildContext context, Category category) {
    return getLocalizedCategoryName(context, category.name);
  }

  /// 检查是否为桌面类别
  static bool isDesktopCategory(String categoryName) {
    return categoryName == DatabaseService.defaultDesktopCategoryName;
  }

  /// 检查是否为桌面类别（通过Category对象）
  static bool isDesktopCategoryFromCategory(Category category) {
    return isDesktopCategory(category.name);
  }
}