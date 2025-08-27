import 'dart:io';
import 'dart:math';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/program.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/launcher_service.dart';
import '../services/category_icon_service.dart';
import '../services/language_service.dart';
import '../services/desktop_scanner_service.dart';
import '../services/log_service.dart';
import '../widgets/animated_overlay.dart';
import '../widgets/program_tile.dart';
import '../widgets/custom_title_bar.dart';

class HomeScreen extends StatefulWidget {
  final Function(Locale) onLanguageChanged;

  const HomeScreen({super.key, required this.onLanguageChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final LauncherService _launcherService = LauncherService();
  final DesktopScannerService _desktopScannerService = DesktopScannerService();
  List<Program> _programs = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  Map<String, Category> _categoryData = {}; // 存储类别数据映射

  bool _isSidebarExpanded = false;
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isDragging = false;
  bool _isOverlayVisible = false;
  late VoidCallback _searchFocusListener;
  bool _isEditMode = false;

  bool _isCategoryEditMode = false;
  String? _categoryToDelete;

  // 桌面整理相关状态
  bool _hasDesktopBackup = false;

  // 语言切换方法
  void _changeLanguage(String languageCode) {
    widget.onLanguageChanged(Locale(languageCode));
  }

  @override
  void initState() {
    super.initState();
    _loadPrograms();
    _checkDesktopBackup();

    // 监听搜索框焦点变化
    _searchFocusListener = () {
      if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
        setState(() {
          _isSearchExpanded = false;
        });
      }
    };
    _searchFocusNode.addListener(_searchFocusListener);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_searchFocusListener);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 获取类别图标
  String _getCategoryIcon(String categoryName) {
    if (categoryName == 'All') {
      return '📱';
    }

    final categoryData = _categoryData[categoryName];
    if (categoryData?.iconName != null) {
      // 直接返回存储的图标名称，让_buildCategoryIconWidget处理
      return categoryData!.iconName!;
    }

    // 默认图标
    return '📁';
  }

  // 构建类别图标Widget
  Widget _buildCategoryIconWidget(String iconIdentifier) {
    LogService.debug("Icon identifier: $iconIdentifier");
    // 如果是emoji字符（如📱、📁），直接显示
    // if (_isEmoji(iconIdentifier)) {
    //   return Text(iconIdentifier, style: TextStyle(fontSize: 16));
    // }

    // 如果是CategoryIcon名称，查找对应的图标
    final categoryIcon = CategoryIconService.getIconByName(iconIdentifier);
    if (categoryIcon != null) {
      return Icon(categoryIcon.icon, color: Color(0xFF6C757D), size: 16);
    }

    // 默认显示为文本
    return Text(iconIdentifier, style: TextStyle(fontSize: 16));
  }

  Future<void> _loadPrograms() async {
    final programs = await _databaseService.getPrograms();
    final categories = await _databaseService.getCategories();

    // 从数据库获取类别名称列表
    final categoryNames = categories.map((c) => c.name).toList();

    // 确保'All'类别在第一位
    final sortedCategories = ['All'];
    for (final name in categoryNames) {
      if (name != 'All') {
        sortedCategories.add(name);
      }
    }

    setState(() {
      _programs = programs;
      _categories = sortedCategories;
      _categoryData = {for (var cat in categories) cat.name: cat}; // 存储类别数据映射
    });
  }

  Future<void> _deleteProgram(Program program) async {
    try {
      await _databaseService.deleteProgram(program.id!);
      await _loadPrograms(); // 重新加载程序列表

      // 显示删除成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.programDeleted(program.name),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // 显示删除失败提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deleteFailed(e.toString())),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // 检查桌面备份状态
  Future<void> _checkDesktopBackup() async {
    try {
      final hasBackup = await _desktopScannerService.hasBackup();
      setState(() {
        _hasDesktopBackup = hasBackup;
      });
    } catch (e) {
      LogService.error('Failed to check desktop backup status', e);
    }
  }

  // 整理桌面
  Future<void> _organizeDesktop() async {
    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("正在整理桌面..."),
              ],
            ),
          );
        },
      );

      // 扫描桌面项目
      final desktopItems = await _desktopScannerService.scanDesktopItems();

      if (desktopItems.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('桌面没有可整理的项目'), backgroundColor: Colors.orange),
        );
        return;
      }

      // 快速备份桌面文件（直接移动，无需拷贝）
      final backupInfo = await _desktopScannerService.fastBackupDesktopItems(
        desktopItems,
      );

      // 将桌面项目添加到程序列表
      for (final item in backupInfo.items) {
        // 根据文件类型确定类别
        String category;
        switch (item.type) {
          case DesktopItemType.executable:
          case DesktopItemType.shortcut:
          case DesktopItemType.urlShortcut:
            category = '桌面应用';
            break;
          case DesktopItemType.folder:
            category = '文件夹';
            break;
          case DesktopItemType.file:
            category = '文件';
            break;
        }

        final program = Program(
          name: item.name,
          path: item.backupPath,
          category: category,
        );

        try {
          await _databaseService.insertProgram(program);
        } catch (e) {
          LogService.error('Failed to add program: ${item.name}', e);
        }
      }

      // 注意：fastBackupDesktopItems已经移动了文件，无需再次清理

      // 更新状态
      setState(() {
        _hasDesktopBackup = true;
      });

      // 重新加载程序列表
      await _loadPrograms();

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('桌面整理完成！已备份 ${desktopItems.length} 个项目'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('桌面整理失败: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // 恢复桌面
  Future<void> _restoreDesktop() async {
    try {
      // 显示确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('确认恢复'),
            content: Text('确定要恢复桌面到整理前的状态吗？这将删除当前桌面上的所有文件并恢复备份的文件。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('确认'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("正在恢复桌面..."),
              ],
            ),
          );
        },
      );

      // 获取备份信息并删除对应的程序
      final backupInfo = await _desktopScannerService.getBackupInfo();
      if (backupInfo != null) {
        for (final item in backupInfo.items) {
          try {
            final programs = await _databaseService.getPrograms();
            final program = programs.firstWhere(
              (p) => p.name == item.name,
              orElse: () => throw Exception('程序未找到'),
            );
            await _databaseService.deleteProgram(program.id!);
          } catch (e) {
            LogService.error('Failed to delete program: ${item.name}', e);
          }
        }
      }

      // 快速恢复桌面文件（直接移动而非拷贝）
      await _desktopScannerService.fastRestoreDesktopItems();

      // 更新状态
      setState(() {
        _hasDesktopBackup = false;
      });

      // 重新加载程序列表
      await _loadPrograms();

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('桌面恢复完成！'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('桌面恢复失败: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteCategory(String category) async {
    try {
      // 获取该类别下的程序数量
      final programsInCategory = await _databaseService.getProgramsByCategory(
        category,
      );
      final programCount = programsInCategory.length;

      // 删除该类别下的所有程序
      await _databaseService.deleteProgramsByCategory(category);

      // 从数据库中删除类别记录
      final categoryData = _categoryData[category];
      if (categoryData?.id != null) {
        await _databaseService.deleteCategory(categoryData!.id!);
      }

      // 从类别列表中移除该类别
      setState(() {
        _categories.remove(category);
        _categoryData.remove(category);
        // 如果当前选中的是被删除的类别，切换到"全部"
        if (_selectedCategory == category) {
          _selectedCategory = 'All';
        }
      });

      // 重新加载程序列表
      await _loadPrograms();

      // 显示删除成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.categoryDeletedWithPrograms(category, programCount),
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // 显示删除失败提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  List<Program> get _filteredPrograms {
    return _programs.where((program) {
      final matchesSearch = program.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory =
          _selectedCategory == 'All' || program.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _showAddCategoryDialog() {
    final TextEditingController categoryNameController =
        TextEditingController();
    String? selectedIconName;
    IconData? selectedIcon;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 16,
            child: Container(
              width: 400,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题栏
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF0078D4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFF0078D4),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.addNewCategory,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  // 表单内容
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.categoryName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF424242),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: categoryNameController,
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context)!.categoryNameHint,
                          filled: true,
                          fillColor: Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Color(0xFFE1E5E9),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Color(0xFFE1E5E9),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Color(0xFF0078D4),
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.categoryIcon,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF424242),
                        ),
                      ),
                      SizedBox(height: 8),
                      StatefulBuilder(
                        builder:
                            (context, setDialogState) => Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Color(0xFFE1E5E9),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 当前选中的图标显示
                                  if (selectedIconName != null) ...[
                                    Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Color(
                                              0xFF0078D4,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Color(0xFF0078D4),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            selectedIcon,
                                            color: Color(0xFF0078D4),
                                            size: 16,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          selectedIconName!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF1F1F1F),
                                          ),
                                        ),
                                        Spacer(),
                                        GestureDetector(
                                          onTap: () {
                                            setDialogState(() {
                                              selectedIconName = null;
                                              selectedIcon = null;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Color(
                                                0xFF6C757D,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Color(0xFF6C757D),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                  ],
                                  // 图标网格
                                  Container(
                                    height: 140,
                                    child: SingleChildScrollView(
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 8,
                                              crossAxisSpacing: 6,
                                              mainAxisSpacing: 6,
                                              childAspectRatio: 1,
                                            ),
                                        itemCount:
                                            CategoryIconService
                                                .categoryIcons
                                                .length,
                                        itemBuilder: (context, index) {
                                          final categoryIcon =
                                              CategoryIconService
                                                  .categoryIcons[index];
                                          final isSelected =
                                              selectedIconName ==
                                              categoryIcon.name;

                                          return GestureDetector(
                                            onTap: () {
                                              setDialogState(() {
                                                selectedIconName =
                                                    categoryIcon.name;
                                                selectedIcon =
                                                    categoryIcon.icon;
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    isSelected
                                                        ? Color(
                                                          0xFF0078D4,
                                                        ).withOpacity(0.1)
                                                        : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color:
                                                      isSelected
                                                          ? Color(0xFF0078D4)
                                                          : Color(0xFFE1E5E9),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Icon(
                                                categoryIcon.icon,
                                                size: 16,
                                                color:
                                                    isSelected
                                                        ? Color(0xFF0078D4)
                                                        : Color(0xFF6C757D),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // 按钮区域
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 取消按钮
                      Container(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF424242),
                            side: BorderSide(
                              color: Color(0xFFE1E5E9),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.cancel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // 添加按钮
                      Container(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = categoryNameController.text.trim();
                            if (name.isNotEmpty &&
                                !_categories.contains(name)) {
                              try {
                                // 创建新类别对象
                                final newCategory = Category(
                                  name: name,
                                  iconName: selectedIconName,
                                );

                                // 保存到数据库
                                await _databaseService.insertCategory(
                                  newCategory,
                                );

                                // 重新加载数据以更新_categoryData
                                await _loadPrograms();

                                // 更新UI
                                setState(() {
                                  if (!_categories.contains(name)) {
                                    _categories.add(name);
                                  }
                                });

                                Navigator.pop(context);

                                // 显示成功提示
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.categoryAddSuccess(name),
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } catch (e) {
                                // 显示错误提示
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.addCategoryFailed(e.toString()),
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0078D4),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.add,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showDeleteCategoryDialog(String category) {
    if (category == 'All') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cannotDeleteAllCategory),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 16,
            child: Container(
              width: 400,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title area
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF6B35).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFFF6B35),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.confirmDeleteCategory,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Content
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.deleteCategoryMessage(category),
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.deleteCategoryWarning,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 24),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '取消',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _deleteCategory(category);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          '删除',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showAnimatedOverlay() {
    setState(() {
      _isOverlayVisible = true;
    });
  }

  void _hideAnimatedOverlay() {
    setState(() {
      _isOverlayVisible = false;
    });
  }

  void _hideAllDeleteButtons() {
    setState(() {
      _isEditMode = false;
      _isCategoryEditMode = false;
      _categoryToDelete = null;
    });
  }

  Future<void> _handleFileDrop(DropDoneDetails detail) async {
    {
      List<String> filePaths = detail.files.map((file) => file.path).toList();

      // // 显示加载指示器
      // showDialog(
      //   context: context,
      //   barrierDismissible: false,
      //   builder: (BuildContext context) {
      //     return AlertDialog(
      //       content: Row(
      //         children: [
      //           CircularProgressIndicator(),
      //           SizedBox(width: 16),
      //           Text(AppLocalizations.of(context)!.addingPrograms),
      //         ],
      //       ),
      //     );
      //   },
      // );

      int successCount = 0;
      List<String> failedFiles = [];

      // 处理每个文件
      for (String filePath in filePaths) {
        try {
          final fileName = filePath.split('\\').last.split('.').first;
          final program = Program(
            name: fileName,
            path: filePath,
            category: _selectedCategory == 'All' ? null : _selectedCategory,
          );

          await _databaseService.insertProgram(program);
          successCount++;
        } catch (e) {
          failedFiles.add(filePath);
        }
      }

      // // 关闭加载对话框
      // Navigator.pop(context);

      // 重新加载程序列表
      await _loadPrograms();

      // // 显示添加结果
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //       successCount > 0
      //           ? "成功添加 $successCount 个程序${failedFiles.isNotEmpty ? '，${failedFiles.length} 个添加失败' : ''}"
      //           : "添加失败，请检查文件格式",
      //     ),
      //     duration: Duration(seconds: 3),
      //   ),
      // );
    }

    // 直接添加程序到数据库
    Future<void> _addProgramsDirectly(List<String> filePaths) async {
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("正在添加程序..."),
              ],
            ),
          );
        },
      );

      int successCount = 0;
      List<String> failedFiles = [];

      // 处理每个文件
      for (String filePath in filePaths) {
        try {
          final fileName = filePath.split('\\').last.split('.').first;
          final program = Program(
            name: fileName,
            path: filePath,
            category: _selectedCategory == 'All' ? null : _selectedCategory,
          );

          await _databaseService.insertProgram(program);
          successCount++;
        } catch (e) {
          failedFiles.add(filePath);
        }
      }

      // 关闭加载对话框
      Navigator.pop(context);

      // 重新加载程序列表
      await _loadPrograms();

      // 显示添加结果
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successCount > 0
                ? AppLocalizations.of(
                  context,
                )!.programsAddedSuccess(successCount)
                : AppLocalizations.of(context)!.addProgramsFailed,
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hideAllDeleteButtons,
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 自定义标题栏
                CustomTitleBar(
                  title: AppLocalizations.of(context)!.appTitle,
                  onLanguageChange: _changeLanguage,
                ),
                // 头部区域
                _buildHeader(),
                Expanded(
                  child: Row(
                    children: [
                      // 侧边栏部分
                      _buildSidebar(),
                      // 主内容区域
                      _buildMainContent(),
                    ],
                  ),
                ),
              ],
            ),

            // 动画蒙板
            if (_isOverlayVisible)
              AnimatedOverlay(onClose: _hideAnimatedOverlay),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAnimatedOverlay,
          tooltip: AppLocalizations.of(context)!.addProgramTooltip,
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  // 头部组件函数
  Widget _buildHeader() {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 占位区域
          Expanded(child: Container()),
          // 搜索框
          _buildSearchBar(),
        ],
      ),
    );
  }

  // 搜索栏组件函数
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 60,
      width: _isSearchExpanded ? 250 : 60,
      padding: EdgeInsets.symmetric(horizontal: 15),

      child: Row(
        children: [
          if (!_isSearchExpanded)
            Tooltip(
              message: AppLocalizations.of(context)!.searchTooltip,
              preferBelow: false,
              verticalOffset: 20,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isSearchExpanded = true;
                  });
                  _searchFocusNode.requestFocus();
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  child: Icon(Icons.search, color: Color(0xFF495057), size: 20),
                ),
              ),
            ),
          if (_isSearchExpanded)
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchHint,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Color(0xFFDEE2E6)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Color(0xFFDEE2E6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Color(0xFF2196F3)),
                        ),
                        isDense: true,
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchController,
                          builder: (context, value, child) {
                            return value.text.isNotEmpty
                                ? IconButton(
                                  icon: Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                                : SizedBox.shrink();
                          },
                        ),
                      ),
                      style: TextStyle(fontSize: 14),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      onSubmitted: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _isSearchExpanded = false;
                          });
                          _searchFocusNode.unfocus();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 侧边栏组件函数
  Widget _buildSidebar() {
    return MouseRegion(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: _isSidebarExpanded ? 220 : 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // 汉堡菜单按钮
            _buildExpandedButton(),

            // 类别列表
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  final icon = _getCategoryIcon(category);

                  return _buildCategoryItem(
                    category: category,
                    icon: icon,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    onDelete:
                        category != 'All'
                            ? () => _deleteCategory(category)
                            : null,
                  );
                },
              ),
            ),

            // 桌面整理按钮
            _buildDesktopOrganizerButton(),

            // 添加类别按钮
            _buildAddCategoryButton(),
          ],
        ),
      ),
    );
  }

  // 汉堡菜单按钮
  Widget _buildExpandedButton() {
    return Tooltip(
      message:
          _isSidebarExpanded
              ? AppLocalizations.of(context)!.collapseSidebar
              : AppLocalizations.of(context)!.expandSidebar,
      preferBelow: false,
      verticalOffset: 20,
      child: InkWell(
        onTap: () {
          setState(() {
            _isSidebarExpanded = !_isSidebarExpanded;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                child: Icon(
                  _isSidebarExpanded ? Icons.menu_open : Icons.menu,
                  color: Color(0xFF6C757D),
                ),
              ),
              Flexible(
                child: AnimatedOpacity(
                  opacity: _isSidebarExpanded ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 200),
                  child: Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      AppLocalizations.of(context)!.category,
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                      style: TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 类别项组件方法
  Widget _buildCategoryItem({
    required String category,
    required String icon,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    bool showDeleteButton =
        _isEditMode && _isCategoryEditMode && category != 'All';

    return Stack(
      children: [
        MouseRegion(
          onEnter: (event) {
            // 鼠标悬停时自动选择类别
            if (!isSelected) {
              onTap();
            }
          },
          child: GestureDetector(
            onTap: onTap,
            onLongPress: () {
              if (onDelete != null && category != 'All') {
                setState(() {
                  _isEditMode = true;
                  _isCategoryEditMode = true;
                  _categoryToDelete = category;
                });
              }
            },
            child: Container(
              alignment: Alignment.center,
              height: 50,
              padding: EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFFE3F2FD) : Colors.transparent,
                border: Border(
                  right: BorderSide(
                    color: isSelected ? Color(0xFF2196F3) : Colors.transparent,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    color: Colors.transparent,
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    child: _buildCategoryIconWidget(icon),
                  ),
                  Flexible(
                    child: AnimatedOpacity(
                      opacity: _isSidebarExpanded ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 200),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: _isSidebarExpanded ? 12 : 0,
                        ),
                        child: Text(
                          category == 'All'
                              ? AppLocalizations.of(context)!.all
                              : category,
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF495057),
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDeleteButton)
          Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isEditMode = false;
                  _isCategoryEditMode = false;
                  _categoryToDelete = null;
                });
                onDelete?.call();
              },
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  // 桌面整理按钮组件函数
  Widget _buildDesktopOrganizerButton() {
    return Tooltip(
      message: _hasDesktopBackup ? '恢复桌面' : '整理桌面',
      preferBelow: false,
      verticalOffset: 20,
      child: InkWell(
        onTap: _hasDesktopBackup ? _restoreDesktop : _organizeDesktop,
        child: Container(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                child: Icon(
                  _hasDesktopBackup ? Icons.restore : Icons.desktop_windows,
                  color: _hasDesktopBackup ? Colors.orange : Color(0xFF6C757D),
                ),
              ),
              Flexible(
                child: AnimatedOpacity(
                  opacity: _isSidebarExpanded ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 200),
                  child: Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      _hasDesktopBackup ? '恢复桌面' : '整理桌面',
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            _hasDesktopBackup
                                ? Colors.orange
                                : Color(0xFF6C757D),
                        fontWeight:
                            _hasDesktopBackup
                                ? FontWeight.w600
                                : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 添加类别按钮组件函数
  Widget _buildAddCategoryButton() {
    return Tooltip(
      message: AppLocalizations.of(context)!.addNewCategory,
      preferBelow: false,
      verticalOffset: 20,
      child: InkWell(
        onTap: _showAddCategoryDialog,
        child: Container(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                child: Icon(Icons.add, color: Color(0xFF6C757D)),
              ),
              Flexible(
                child: AnimatedOpacity(
                  opacity: _isSidebarExpanded ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 200),
                  child: Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      '添加类别',
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                      style: TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 主内容区域组件函数
  Widget _buildMainContent() {
    return Expanded(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Color(0xFFF8F9FA),
                padding: EdgeInsets.all(8),
                child: DropTarget(
                  onDragDone: _handleFileDrop,
                  onDragEntered: (detail) {
                    setState(() {
                      _isDragging = true;
                    });
                  },
                  onDragExited: (detail) {
                    setState(() {
                      _isDragging = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            _isDragging
                                ? Color(0xFF2196F3)
                                : Colors.transparent,
                        width: 2,
                        style:
                            _isDragging ? BorderStyle.solid : BorderStyle.none,
                      ),
                    ),
                    child:
                        _filteredPrograms.isEmpty
                            ? Center(
                              child: Text(
                                AppLocalizations.of(context)!.noProgramsMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF6C757D),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                            : SingleChildScrollView(
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children:
                                    _filteredPrograms.map((program) {
                                      return SizedBox(
                                        width: 120,
                                        height: 120,
                                        child: ProgramTile(
                                          program: program,
                                          launcherService: _launcherService,
                                          onDelete:
                                              () => _deleteProgram(program),
                                          isEditMode: _isEditMode,
                                          onLongPress: () {
                                            if (!_isEditMode) {
                                              setState(() {
                                                _isEditMode = !_isEditMode;
                                              });
                                            }
                                          },
                                          onCategoryChanged: () {
                                            _loadPrograms(); // 重新加载程序列表
                                          },
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
