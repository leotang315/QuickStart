# QuickStart 多国语言功能设计方案

## 1. 项目现状分析

### 当前硬编码的中文文本
通过代码分析，发现以下需要国际化的文本：

#### 主界面文本
- 应用标题："QuickStart"
- 窗口标题："程序快速启动器"
- 搜索提示："搜索程序..."
- 工具提示："搜索程序"、"添加程序"、"收起侧边栏"、"展开侧边栏"

#### 类别管理
- "添加新类别"
- "类别名称"
- "请输入类别名称"
- "类别图标"
- "取消"、"添加"
- "确认删除类别"
- "确定要删除类别 \"xxx\" 吗？"
- "此操作将同时删除该类别下的所有快捷图标，且无法撤销。"
- "删除"

#### 提示消息
- "程序 \"xxx\" 已删除"
- "删除失败: xxx"
- "类别 \"xxx\" 添加成功"
- "添加类别失败: xxx"
- "类别 \"xxx\" 及其下的 x 个程序已删除"
- "无法删除\"全部\"类别"
- "正在添加程序..."
- "成功添加 x 个程序"
- "添加失败，请检查文件格式"

## 2. 技术方案设计

### 2.1 使用 Flutter 官方国际化方案

#### 依赖添加
在 `pubspec.yaml` 中添加：
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

dev_dependencies:
  intl_utils: ^2.8.7
```

#### 配置文件
在 `pubspec.yaml` 中添加：
```yaml
flutter:
  generate: true
```

创建 `l10n.yaml` 配置文件：
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

### 2.2 目录结构
```
lib/
├── l10n/
│   ├── app_en.arb     # 英文资源文件
│   ├── app_zh.arb     # 中文资源文件
│   └── app_ja.arb     # 日文资源文件（可选）
├── generated/
│   └── l10n/
│       └── app_localizations.dart  # 自动生成
└── ...
```

### 2.3 语言资源文件设计

#### app_en.arb (英文)
```json
{
  "appTitle": "QuickStart",
  "windowTitle": "Program Quick Launcher",
  "searchHint": "Search programs...",
  "searchTooltip": "Search programs",
  "addProgramTooltip": "Add program",
  "collapseSidebar": "Collapse sidebar",
  "expandSidebar": "Expand sidebar",
  "addNewCategory": "Add New Category",
  "categoryName": "Category Name",
  "categoryNameHint": "Enter category name",
  "categoryIcon": "Category Icon",
  "cancel": "Cancel",
  "add": "Add",
  "delete": "Delete",
  "confirmDeleteCategory": "Confirm Delete Category",
  "deleteCategoryMessage": "Are you sure you want to delete category \"{categoryName}\"?",
  "deleteCategoryWarning": "This operation will also delete all shortcuts in this category and cannot be undone.",
  "programDeleted": "Program \"{programName}\" has been deleted",
  "deleteFailed": "Delete failed: {error}",
  "categoryAddSuccess": "Category \"{categoryName}\" added successfully",
  "addCategoryFailed": "Failed to add category: {error}",
  "categoryDeletedWithPrograms": "Category \"{categoryName}\" and its {count} programs have been deleted",
  "cannotDeleteAllCategory": "Cannot delete \"All\" category",
  "addingPrograms": "Adding programs...",
  "programsAddedSuccess": "Successfully added {count} programs",
  "addProgramsFailed": "Failed to add programs, please check file format",
  "all": "All"
}
```

#### app_zh.arb (中文)
```json
{
  "appTitle": "QuickStart",
  "windowTitle": "程序快速启动器",
  "searchHint": "搜索程序...",
  "searchTooltip": "搜索程序",
  "addProgramTooltip": "添加程序",
  "collapseSidebar": "收起侧边栏",
  "expandSidebar": "展开侧边栏",
  "addNewCategory": "添加新类别",
  "categoryName": "类别名称",
  "categoryNameHint": "请输入类别名称",
  "categoryIcon": "类别图标",
  "cancel": "取消",
  "add": "添加",
  "delete": "删除",
  "confirmDeleteCategory": "确认删除类别",
  "deleteCategoryMessage": "确定要删除类别 \"{categoryName}\" 吗？",
  "deleteCategoryWarning": "此操作将同时删除该类别下的所有快捷图标，且无法撤销。",
  "programDeleted": "程序 \"{programName}\" 已删除",
  "deleteFailed": "删除失败: {error}",
  "categoryAddSuccess": "类别 \"{categoryName}\" 添加成功",
  "addCategoryFailed": "添加类别失败: {error}",
  "categoryDeletedWithPrograms": "类别 \"{categoryName}\" 及其下的 {count} 个程序已删除",
  "cannotDeleteAllCategory": "无法删除\"全部\"类别",
  "addingPrograms": "正在添加程序...",
  "programsAddedSuccess": "成功添加 {count} 个程序",
  "addProgramsFailed": "添加失败，请检查文件格式",
  "all": "全部"
}
```

### 2.4 语言切换功能设计

#### 语言设置服务
```dart
// lib/services/language_service.dart
class LanguageService {
  static const String _languageKey = 'selected_language';
  
  static Future<Locale> getSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'zh';
    return Locale(languageCode);
  }
  
  static Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }
}
```

#### 语言切换UI组件
在侧边栏底部添加语言切换按钮：
- 中文 (简体)
- English
- 日本語 (可选)

### 2.5 实施步骤

1. **第一阶段：基础配置**
   - 添加国际化依赖
   - 创建语言资源文件
   - 配置应用支持的语言

2. **第二阶段：文本替换**
   - 替换所有硬编码的中文文本
   - 使用 AppLocalizations 获取本地化文本
   - 处理带参数的文本（如删除确认消息）

3. **第三阶段：语言切换**
   - 实现语言设置持久化
   - 添加语言切换UI
   - 实现动态语言切换

4. **第四阶段：测试优化**
   - 测试各语言显示效果
   - 调整UI布局适应不同语言文本长度
   - 优化用户体验

## 3. 实施建议

### 3.1 优先级
- **高优先级**：中英文支持
- **中优先级**：语言切换UI
- **低优先级**：其他语言支持（日文、韩文等）

### 3.2 注意事项
1. **文本长度**：不同语言的文本长度差异较大，需要确保UI布局的适应性
2. **文化差异**：考虑不同文化背景下的用户习惯
3. **字体支持**：确保选择的字体支持所有目标语言的字符
4. **RTL语言**：如果未来需要支持阿拉伯语等RTL语言，需要额外考虑布局方向

### 3.3 测试策略
1. **功能测试**：确保所有功能在不同语言下正常工作
2. **UI测试**：检查不同语言下的界面显示效果
3. **用户体验测试**：邀请不同语言背景的用户进行测试

## 4. 预期效果

实施完成后，QuickStart 将支持：
- 多语言界面显示
- 动态语言切换
- 语言设置持久化
- 良好的国际化用户体验

这将使应用能够服务更广泛的用户群体，提升应用的国际化水平。