import 'dart:io';
import 'dart:math';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:win32/win32.dart';
import '../models/program.dart';
import '../services/database_service.dart';
import '../services/icon_service.dart';
import '../services/launcher_service.dart';
import '../widgets/animated_overlay.dart';
import '../widgets/program_tile.dart';
import 'add_program_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final LauncherService _launcherService = LauncherService();
  List<Program> _programs = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  bool _isSidebarHovered = false;
  bool _isSidebarExpanded = false;
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isDragging = false;
  bool _isOverlayVisible = false;
  late VoidCallback _searchFocusListener;

  @override
  void initState() {
    super.initState();
    _loadPrograms();

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

  Future<void> _loadPrograms() async {
    final programs = await _databaseService.getPrograms();
    final categories =
        programs
            .map((p) => p.category)
            .where((c) => c != null && c.isNotEmpty)
            .map((c) => c!)
            .toSet()
            .toList();

    setState(() {
      _programs = programs;
      _categories = ['All', ...categories];
    });
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
    final TextEditingController categoryIconController =
        TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('添加新类别'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: categoryNameController,
                  decoration: InputDecoration(
                    labelText: '类别名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: categoryIconController,
                  decoration: InputDecoration(
                    labelText: '图标 (emoji)',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final name = categoryNameController.text.trim();
                  if (name.isNotEmpty && !_categories.contains(name)) {
                    setState(() {
                      _categories.add(name);
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text('添加'),
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部区域
              _buildHeader(
                isSidebarExpanded: _isSidebarExpanded,
                isSearchExpanded: _isSearchExpanded,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                onMenuTap: () {
                  setState(() {
                    _isSidebarExpanded = !_isSidebarExpanded;
                  });
                },
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onExpandSearch: () {
                  setState(() {
                    _isSearchExpanded = true;
                  });
                },
                onCollapseSearch: () {
                  setState(() {
                    _isSearchExpanded = false;
                  });
                },
              ),
              Expanded(
                child: Row(
                  children: [
                    // 侧边栏部分
                    _buildSidebar(
                      isSidebarExpanded: _isSidebarExpanded,
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      onAddCategory: _showAddCategoryDialog,
                      onSiderbarExpanded: () {
                        setState(() {
                          _isSidebarExpanded = !_isSidebarExpanded;
                        });
                      },
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },

                      onHoverChanged: (isHovered) {
                        setState(() {
                          _isSidebarHovered = isHovered;
                        });
                      },
                    ),
                    // 主内容区域
                    _buildMainContent(
                      filteredPrograms: _filteredPrograms,
                      isDragging: _isDragging,
                      launcherService: _launcherService,
                      onFileDrop: _handleFileDrop,
                      onDragEntered: () {
                        setState(() {
                          _isDragging = true;
                        });
                      },
                      onDragExited: () {
                        setState(() {
                          _isDragging = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 动画蒙板
          if (_isOverlayVisible) AnimatedOverlay(onClose: _hideAnimatedOverlay),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAnimatedOverlay,
        tooltip: '添加程序',
        child: Icon(Icons.add),
      ),
    );
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
      //           Text("正在添加程序..."),
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
                ? "成功添加 $successCount 个程序${failedFiles.isNotEmpty ? '，${failedFiles.length} 个添加失败' : ''}"
                : "添加失败，请检查文件格式",
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

// 头部组件函数
Widget _buildHeader({
  required bool isSidebarExpanded,
  required bool isSearchExpanded,
  required TextEditingController searchController,
  required FocusNode searchFocusNode,
  required VoidCallback onMenuTap,
  required ValueChanged<String> onSearchChanged,
  required VoidCallback onExpandSearch,
  required VoidCallback onCollapseSearch,
}) {
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
        // 标题区域
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Text(
              'QuickStart',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212529),
              ),
            ),
          ),
        ),
        // 搜索框
        buildSearchBar(
          isSearchExpanded: isSearchExpanded,
          searchController: searchController,
          searchFocusNode: searchFocusNode,
          onSearchChanged: onSearchChanged,
          onExpandSearch: onExpandSearch,
          onCollapseSearch: onCollapseSearch,
        ),
      ],
    ),
  );
}

// 搜索栏组件函数
Widget buildSearchBar({
  required bool isSearchExpanded,
  required TextEditingController searchController,
  required FocusNode searchFocusNode,
  required ValueChanged<String> onSearchChanged,
  required VoidCallback onExpandSearch,
  required VoidCallback onCollapseSearch,
}) {
  return AnimatedContainer(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    height: 60,
    width: isSearchExpanded ? 250 : 60,
    padding: EdgeInsets.symmetric(horizontal: 15),

    child: Row(
      children: [
        if (!isSearchExpanded)
          InkWell(
            onTap: () {
              onExpandSearch();
              searchFocusNode.requestFocus();
            },
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              child: Icon(Icons.search, color: Color(0xFF495057), size: 20),
            ),
          ),
        if (isSearchExpanded)
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    decoration: InputDecoration(
                      hintText: '搜索程序...',
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
                        valueListenable: searchController,
                        builder: (context, value, child) {
                          return value.text.isNotEmpty
                              ? IconButton(
                                icon: Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  onSearchChanged('');
                                },
                              )
                              : SizedBox.shrink();
                        },
                      ),
                    ),
                    style: TextStyle(fontSize: 14),
                    onChanged: onSearchChanged,
                    onSubmitted: (value) {
                      if (value.isEmpty) {
                        onCollapseSearch();
                        searchFocusNode.unfocus();
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
Widget _buildSidebar({
  required bool isSidebarExpanded,
  required List<String> categories,
  required String selectedCategory,
  required ValueChanged<String> onCategorySelected,
  required VoidCallback onAddCategory,
  required VoidCallback onSiderbarExpanded,
  required ValueChanged<bool> onHoverChanged,
}) {
  return MouseRegion(
    onEnter: (_) => onHoverChanged(true),
    onExit: (_) => onHoverChanged(false),
    child: AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: isSidebarExpanded ? 220 : 60,
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
          _buildExpandedButton(
            isSidebarExpanded: isSidebarExpanded,
            onTap: onSiderbarExpanded,
          ),
        
          // 类别列表
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                final icon =
                    category == 'All'
                        ? '📱'
                        : category == '工作'
                        ? '💼'
                        : category == '娱乐'
                        ? '🎮'
                        : category == '工具'
                        ? '🔧'
                        : '📁';

                return _buildCategoryItem(
                  category: category,
                  icon: icon,
                  isSelected: isSelected,
                  isSidebarExpanded: isSidebarExpanded,
                  onTap: () => onCategorySelected(category),
                );
              },
            ),
          ),
          
          // 添加类别按钮
          _buildAddCategoryButton(
            isSidebarExpanded: isSidebarExpanded,
            onTap: onAddCategory,
          ),
        ],
      ),
    ),
  );
}

// 汉堡菜单按钮
Widget _buildExpandedButton({
  required bool isSidebarExpanded,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
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
              isSidebarExpanded ? Icons.menu_open : Icons.menu,
              color: Color(0xFF6C757D),
            ),
          ),
        ],
      ),
    ),
  );
}

// 添加类别按钮组件函数
Widget _buildAddCategoryButton({
  required bool isSidebarExpanded,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
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
              opacity: isSidebarExpanded ? 1.0 : 0.0,
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
  );
}

// 类别项组件函数
Widget _buildCategoryItem({
  required String category,
  required String icon,
  required bool isSelected,
  required bool isSidebarExpanded,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
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
            child: Text(icon, style: TextStyle(fontSize: 16)),
          ),
          Flexible(
            child: AnimatedOpacity(
              opacity: isSidebarExpanded ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: Padding(
                padding: EdgeInsets.only(left: isSidebarExpanded ? 12 : 0),
                child: Text(
                  category,
                  overflow: TextOverflow.clip,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF495057),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
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

// 主内容区域组件函数
Widget _buildMainContent({
  required List<Program> filteredPrograms,
  required bool isDragging,
  required LauncherService launcherService,
  required Function(DropDoneDetails) onFileDrop,
  required VoidCallback onDragEntered,
  required VoidCallback onDragExited,
}) {
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
                onDragDone: onFileDrop,
                onDragEntered: (detail) => onDragEntered(),
                onDragExited: (detail) => onDragExited(),
                child: Container(
                  padding: EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isDragging ? Color(0xFF2196F3) : Colors.transparent,
                      width: 2,
                      style: isDragging ? BorderStyle.solid : BorderStyle.none,
                    ),
                  ),
                  child:
                      filteredPrograms.isEmpty
                          ? Center(
                            child: Text(
                              '暂无程序\n拖拽程序文件到此区域添加',
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
                                  filteredPrograms.map((program) {
                                    return SizedBox(
                                      width: 120,
                                      height: 120,
                                      child: ProgramTile(
                                        program: program,
                                        launcherService: launcherService,
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
