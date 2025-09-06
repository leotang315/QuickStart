import 'dart:io';
import 'dart:math';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logger/web.dart';
import 'package:quick_start/services/icon_service.dart';
import '../models/program.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/launcher_service.dart';
import '../services/language_service.dart';
import '../services/desktop_scanner_service.dart';
import '../services/log_service.dart';
import '../widgets/animated_overlay.dart';
import '../widgets/program_tile.dart';
import '../widgets/custom_title_bar.dart';
import '../widgets/add_category_dialog.dart';
import '../controllers/category_dialog_controller.dart';

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
  List<Category> _categories = [];
  Category? _selectedCategory;
  String _searchQuery = '';
  bool _isSidebarExpanded = false;
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late VoidCallback _searchFocusListener;
  bool _isDragging = false;
  bool _isOverlayVisible = false;
  bool _isProgramEditMode = false;
  bool _isCategoryEditMode = false;
  bool _hasDesktopBackup = false;

  @override
  void initState() {
    super.initState();
    _loadProgramsAndCategories();
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

  // 语言切换方法
  void _changeLanguage(String languageCode) {
    widget.onLanguageChanged(Locale(languageCode));
  }

  Future<void> _loadProgramsAndCategories() async {
    final programs = await _databaseService.getPrograms();
    final categories = await _databaseService.getCategories();

    setState(() {
      _programs = programs;
      _categories = categories;

      // 如果当前选中的类别不存在，选择第一个类别或清空选择
      if (_selectedCategory != null &&
          !_categories.any((c) => c.id == _selectedCategory!.id)) {
        _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
      } else if (_selectedCategory == null && _categories.isNotEmpty) {
        _selectedCategory = _categories.first;
      }
    });
  }

  Future<void> _deleteProgram(Program program) async {
    try {
      await _databaseService.deleteProgram(program.id!);
      await _loadProgramsAndCategories();

      _showMessage(AppLocalizations.of(context)!.programDeleted(program.name));
    } catch (e) {
      _showMessage(
        AppLocalizations.of(context)!.deleteFailed(e.toString()),
        color: Colors.red,
      );
    }
  }

  Future<void> _deleteCategory(Category category) async {
    try {
      // 保护桌面类别，不允许删除
      if (category.name == '桌面') {
        _showMessage(
          AppLocalizations.of(context)!.desktopCategoryCannotDelete,
          color: Colors.orange,
        );
        return;
      }

      // 检查分类ID是否有效
      if (category.id == null) {
        LogService.error('Category ID is null: ${category.name}', null);
        return;
      }

      final categoryId = category.id!;

      // 获取该类别下的程序数量
      final programsInCategory = await _databaseService.getProgramsByCategoryId(
        categoryId,
      );
      final programCount = programsInCategory.length;

      // 删除该类别下的所有程序
      await _databaseService.deleteProgramsByCategoryId(categoryId);

      // 从数据库中删除类别记录
      await _databaseService.deleteCategory(categoryId);

      // 如果当前选中的是被删除的类别，清空选择（重新加载时会自动选择第一个类别）
      if (_selectedCategory?.id == category.id) {
        setState(() {
          _selectedCategory = null;
        });
      }

      // 重新加载程序和类别列表
      await _loadProgramsAndCategories();

      _showMessage(
        AppLocalizations.of(
          context,
        )!.categoryDeletedWithPrograms(category.name, programCount),
      );
    } catch (e) {
      _showMessage(
        AppLocalizations.of(context)!.deleteFailed(e.toString()),
        color: Colors.red,
      );
    }
  }

  List<Program> get _filteredPrograms {
    return _programs.where((program) {
      final matchesSearch = program.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      // 如果有搜索内容，则搜索所有程序；否则按类别过滤
      bool matchesCategory =
          _searchQuery.isNotEmpty || _selectedCategory == null;

      if (!matchesCategory && _selectedCategory != null) {
        // 直接使用选中的分类ID
        matchesCategory = program.categoryId == _selectedCategory!.id;
      }

      return matchesSearch && matchesCategory;
    }).toList();
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
        _showMessage(
          AppLocalizations.of(context)!.noDesktopItemsToOrganize,
          color: Colors.orange,
        );
        return;
      }

      // 快速备份桌面文件（直接移动，无需拷贝）
      final backupInfo = await _desktopScannerService.fastBackupDesktopItems(
        desktopItems,
      );

      // 获取桌面分类（固定ID=0）
      Category? desktopCategory = await _databaseService.getCategoryById(0);
      if (desktopCategory == null) {
        LogService.error('Desktop category not found', null);
        throw 'Desktop category not found';
      }

      // 将桌面项目添加到程序列表
      for (final item in backupInfo.items) {
        final program = Program(
          name: item.name,
          path: item.backupPath,
          categoryId: desktopCategory.id,
          frequency: 0,
        );

        try {
          await _databaseService.insertProgram(program);
        } catch (e) {
          LogService.error('Failed to add program: ${item.name}', e);
        }
      }

      // 更新状态
      setState(() {
        _hasDesktopBackup = true;
      });

      // 重新加载程序列表
      await _loadProgramsAndCategories();

      Navigator.pop(context);

      _showMessage(
        AppLocalizations.of(
          context,
        )!.desktopOrganizeSuccess(desktopItems.length),
        color: Colors.green,
        duration: 3,
      );
    } catch (e) {
      Navigator.pop(context);
      _showMessage(
        AppLocalizations.of(context)!.desktopOrganizeFailed(e.toString()),
        color: Colors.red,
        duration: 3,
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
        // 先获取桌面类别
        final desktopCategory = await _databaseService.getCategoryByName('桌面');
        if (desktopCategory != null) {
          // 只在桌面类别中查找程序
          final desktopPrograms = await _databaseService
              .getProgramsByCategoryId(desktopCategory.id);

          for (final item in backupInfo.items) {
            try {
              final program = desktopPrograms.firstWhere(
                (p) => p.name == item.name,
                orElse: () => throw Exception('程序未找到'),
              );
              await _databaseService.deleteProgram(program.id!);
            } catch (e) {
              LogService.error('Failed to delete program: ${item.name}', e);
            }
          }
          // 桌面类别保持永久存在，不删除
        }
      }

      // 快速恢复桌面文件（直接移动而非拷贝）
      await _desktopScannerService.fastRestoreDesktopItems();

      // 更新状态
      setState(() {
        _hasDesktopBackup = false;
      });

      // 重新加载程序列表
      await _loadProgramsAndCategories();

      Navigator.pop(context);

      _showMessage(
        AppLocalizations.of(context)!.desktopRestoreSuccess,
        color: Colors.green,
      );
    } catch (e) {
      Navigator.pop(context);
      _showMessage(
        AppLocalizations.of(context)!.desktopRestoreFailed(e.toString()),
        color: Colors.red,
      );
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,

      barrierColor: Colors.black.withOpacity(0.3),
      builder:
          (context) =>
              AddCategoryDialog(onCategoryAdded: _loadProgramsAndCategories),
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
      _isProgramEditMode = false;
      _isCategoryEditMode = false;
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

          // 获取分类ID
          int? categoryId = _selectedCategory?.id;

          final program = Program(
            name: fileName,
            path: filePath,
            categoryId: categoryId,
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
      await _loadProgramsAndCategories();

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

          // 获取分类ID
          int? categoryId = _selectedCategory?.id;

          final program = Program(
            name: fileName,
            path: filePath,
            categoryId: categoryId,
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
      await _loadProgramsAndCategories();

      // 显示添加结果
      _showMessage(
        successCount > 0
            ? AppLocalizations.of(context)!.programsAddedSuccess(successCount)
            : AppLocalizations.of(context)!.addProgramsFailed,
      );
    }
  }

  void _showMessage(
    String message, {
    Color? color = Colors.green,
    int duration = 2,
  }) {
    // 显示删除成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: duration),
        backgroundColor: color,
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
                  final isSelected = _selectedCategory?.id == category.id;

                  return _buildCategoryItem(
                    category: category,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    onDelete: () => _deleteCategory(category),
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
    required Category category,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    bool showDeleteButton = _isProgramEditMode && category.name != '桌面';

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
              if (onDelete != null) {
                setState(() {
                  _isProgramEditMode = true;
                  _isCategoryEditMode = true;
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
                    child: IconService.instance.getIconWidget(
                      category.iconResource,
                    ),
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
                          category.name,
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
                _hideAllDeleteButtons();
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
                                          isEditMode: _isProgramEditMode,
                                          onLongPress: () {
                                            if (!_isProgramEditMode) {
                                              setState(() {
                                                _isProgramEditMode =
                                                    !_isProgramEditMode;
                                              });
                                            }
                                          },
                                          onCategoryChanged: () {
                                            _loadProgramsAndCategories(); // 重新加载程序列表
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
