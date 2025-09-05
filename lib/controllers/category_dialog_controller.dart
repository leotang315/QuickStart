import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

typedef MessageCallback = void Function(String message, {Color? color});

/// 类别对话框控制器
/// 负责处理添加类别对话框的业务逻辑
class CategoryDialogController {
  final DatabaseService _databaseService = DatabaseService();
  final MessageCallback? onShowMessage;

  CategoryDialogController({
    this.onShowMessage,
  });

  /// 验证类别名称
  Future<String?> validateCategoryName(String name, BuildContext context) async {
    final trimmedName = name.trim();
    
    if (trimmedName.isEmpty) {
      return AppLocalizations.of(context)!.categoryNameCannotBeEmpty;
    }
    
    final existingCategories = await _databaseService.getCategories();
    final existingNames = existingCategories.map((c) => c.name).toList();
    if (existingNames.contains(trimmedName)) {
      return AppLocalizations.of(context)!.categoryNameAlreadyExists;
    }
    
    return null;
  }

  /// 添加新类别
  Future<bool> addCategory({
    required String name,
    required String iconResource,
    required BuildContext context,
    VoidCallback? onCategoryAdded,
  }) async {
    try {
      // 验证名称
      final validationError = await validateCategoryName(name, context);
      if (validationError != null) {
        onShowMessage?.call(validationError, color: Colors.red);
        return false;
      }

      // 创建新类别对象
      final newCategory = Category(
        name: name.trim(),
        iconResource: iconResource,
      );

      // 保存到数据库
      await _databaseService.insertCategory(newCategory);

      // 通知父组件更新数据
      onCategoryAdded?.call();

      // 显示成功提示
      onShowMessage?.call(
        AppLocalizations.of(context)!.categoryAddSuccess(name.trim()),
        color: Colors.green,
      );

      return true;
    } catch (e) {
      // 显示错误提示
      onShowMessage?.call(
        AppLocalizations.of(context)!.addCategoryFailed(e.toString()),
        color: Colors.red,
      );
      return false;
    }
  }

  /// 获取默认图标资源
  String getDefaultIconResource() {
    if (Category.flutterIcons.isNotEmpty) {
      return "icon:" + Category.flutterIcons.keys.first;
    }
    return "icon:category";
  }

  /// 获取默认图标
  IconData getDefaultIcon() {
    if (Category.flutterIcons.isNotEmpty) {
      return Category.flutterIcons.values.first;
    }
    return Icons.category;
  }
}