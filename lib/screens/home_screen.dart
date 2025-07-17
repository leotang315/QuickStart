import 'dart:math';

import 'package:flutter/material.dart';
import '../models/program.dart';
import '../services/database_service.dart';
import '../services/icon_service.dart';
import '../services/launcher_service.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPrograms() async {
    final programs = await _databaseService.getPrograms();
    final categories = programs
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
      builder: (context) => AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 侧边栏部分
          MouseRegion(
            onEnter: (_) => setState(() => _isSidebarHovered = true),
            onExit: (_) => setState(() => _isSidebarHovered = false),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: _isSidebarHovered ? 220 : 60,
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
                  // // 侧边栏头部
                  Container(
                    height: 60,
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        //  if (_isSidebarHovered)
                        Expanded(
                          child: AnimatedOpacity(
                            opacity: _isSidebarHovered ? 1.0 : 0.0,
                            duration: Duration(milliseconds: 300),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: '搜索程序...',
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Color(0xFFDEE2E6),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Color(0xFFDEE2E6),
                                  ),
                                ),
                                isDense: true,
                              ),
                              style: TextStyle(fontSize: 14),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                        ),

                        if (!_isSidebarHovered)
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: Icon(Icons.search, color: Color(0xFF495057)),
                          ),
                      ],
                    ),
                  ),
                  // // 类别列表
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        final icon = category == 'All'
                            ? '📱'
                            : category == '工作'
                            ? '💼'
                            : category == '娱乐'
                            ? '🎮'
                            : category == '工具'
                            ? '🔧'
                            : '📁';

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          onHover: (isHovering) {
                            if (_isSidebarHovered && isHovering) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            }
                          },
                          child: Container(
                            alignment: Alignment.center,
                            height: 50,
                            padding: EdgeInsets.symmetric(horizontal: 13),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(0xFFE3F2FD)
                                  : Colors.transparent,
                              border: Border(
                                right: BorderSide(
                                  color: isSelected
                                      ? Color(0xFF2196F3)
                                      : Colors.transparent,
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
                                  child: Text(
                                    icon,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),

                                Flexible(
                                  child: AnimatedOpacity(
                                    opacity: _isSidebarHovered ? 1.0 : 0.0,
                                    duration: Duration(milliseconds: 200),
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: _isSidebarHovered ? 12 : 0,
                                      ),
                                      child: Text(
                                        category,
                                        overflow: TextOverflow
                                            .clip, // 或使用 TextOverflow.ellipsis
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF495057),
                                          fontWeight: isSelected
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
                        );
                      },
                    ),
                  ),
                  // 添加类别按钮
                  InkWell(
                    onTap: _showAddCategoryDialog,
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE9ECEF), width: 1),
                        ),
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
                              opacity: _isSidebarHovered ? 1.0 : 0.0,
                              duration: Duration(milliseconds: 200),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: _isSidebarHovered ? 12 : 0,
                                ),
                                child: Text(
                                  '添加类别',
                                  overflow: TextOverflow
                                      .clip, // 或使用 TextOverflow.ellipsis
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6C757D),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 主内容区域
          Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200), // 与侧边栏动画持续时间相同
              curve: Curves.easeInOut,
              child: Column(
                children: [
                  // 内容头部
                  Container(
                    height: 60,
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _selectedCategory,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF212529),
                      ),
                    ),
                  ),
                  // 程序显示区域
                  Expanded(
                    child: Container(
                      color: Color(0xFFF8F9FA),
                      padding: EdgeInsets.all(24),
                      child: DragTarget<String>(
                        onWillAccept: (data) {
                          setState(() {
                            _isDragging = true;
                          });
                          return data != null &&
                              (data.endsWith('.exe') || data.endsWith('.lnk'));
                        },
                        onAccept: (data) {
                          setState(() {
                            _isDragging = false;
                          });
                          _showAddProgramDialog(data);
                        },
                        onLeave: (data) {
                          setState(() {
                            _isDragging = false;
                          });
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            padding: EdgeInsets.all(8),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isDragging
                                    ? Color(0xFF2196F3)
                                    : Colors.transparent,
                                width: 2,
                                style: _isDragging
                                    ? BorderStyle.solid
                                    : BorderStyle.none,
                              ),
                            ),
                            child: _filteredPrograms.isEmpty
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
                                : // 替换 GridView.builder 部分
                                  SingleChildScrollView(
                                    child: Wrap(
                                      spacing: 16, // 水平间距
                                      runSpacing: 16, // 垂直间距
                                      children: _filteredPrograms.map((
                                        program,
                                      ) {
                                        return SizedBox(
                                          width: 120, // 固定宽度
                                          height: 120, // 固定高度
                                          child: _buildProgramTile(program),
                                        );
                                      }).toList(),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProgramScreen()),
          );
          if (result == true) {
            _loadPrograms();
          }
        },
        tooltip: '添加程序',
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddProgramDialog(String filePath) {
    final fileName = filePath.split('\\').last.split('.').first;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加程序'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('是否添加以下程序？'),
            SizedBox(height: 8),
            Text(filePath, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddProgramScreen(
                    program: Program(
                      name: fileName,
                      path: filePath,
                      category: _selectedCategory == 'All'
                          ? null
                          : _selectedCategory,
                    ),
                  ),
                ),
              ).then((value) {
                if (value == true) {
                  _loadPrograms();
                }
              });
            },
            child: Text('添加'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramTile(Program program) {
    return Stack(
      children: [
        InkWell(
          onTap: () async {
            await _launcherService.launchProgram(program);
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child:
                        IconService.getFileIcon(
                          program.path,
                          size: IconSize.jumbo,
                        ) ??
                        Icon(
                          Icons.insert_drive_file,
                          color: Colors.white,
                          size: 24,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    program.name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(fontSize: 12, color: Color(0xFF495057)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
