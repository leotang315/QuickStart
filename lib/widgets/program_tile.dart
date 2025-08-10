import 'package:flutter/material.dart';

import '../models/program.dart';
import '../services/icon_service.dart';
import '../services/launcher_service.dart';
import '../services/database_service.dart';
import '../models/category.dart';
import '../services/category_icon_service.dart';

class ProgramTile extends StatefulWidget {
  final Program program;
  final LauncherService launcherService;
  final VoidCallback? onDelete;
  final bool isEditMode;
  final VoidCallback? onLongPress;
  final VoidCallback? onCategoryChanged;

  const ProgramTile({
    Key? key,
    required this.program,
    required this.launcherService,
    this.onDelete,
    this.isEditMode = false,
    this.onLongPress,
    this.onCategoryChanged,
  }) : super(key: key);

  @override
  _ProgramTileState createState() => _ProgramTileState();
}

class _ProgramTileState extends State<ProgramTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.isEditMode) {
             widget.launcherService.launchProgram(widget.program);
        }
      },
      onLongPress: () {
        if (!widget.isEditMode) {
          widget.onLongPress?.call();
        }
      },
      onSecondaryTapDown: (details) {
        if (!widget.isEditMode) {
          _showContextMenu(details.globalPosition);
        }
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovering = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isHovering = false;
          });
        },
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color:
                    _isHovering
                        ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.7)
                        : Colors.transparent,
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
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child:
                          IconService.getFileIcon(
                            widget.program.path,
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
                      widget.program.name,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(fontSize: 12, color: Color(0xFF495057)),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isEditMode && widget.onDelete != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    widget.onDelete?.call();
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(Offset position) async {
    if (widget.onDelete == null) return;

    final DatabaseService databaseService = DatabaseService();
    final categories = await databaseService.getCategories();
    final availableCategories = categories.where((cat) => cat.name != 'All').toList();

    if (!mounted) return;

    List<PopupMenuEntry<dynamic>> menuItems = [];
    
    // 类别选择区域标题
    menuItems.add(
      PopupMenuItem<dynamic>(
        enabled: false,
        height: 28,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.category, size: 14, color: Colors.blue[600]),
              SizedBox(width: 6),
              Text(
                '更改类别',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Segoe UI',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    // 无类别选项
    menuItems.add(
      PopupMenuItem<String>(
        value: 'category_none',
        height: 32,
        child: Container(
          padding: EdgeInsets.only(left: 12),
          child: Row(
            children: [
              Icon(Icons.clear, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text(
                '无类别',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontFamily: 'Segoe UI',
                ),
              ),
              if (widget.program.category == null) ...[
                Spacer(),
                Icon(Icons.check, size: 16, color: Colors.green[600]),
              ],
            ],
          ),
        ),
      ),
    );
    
    // 现有类别选项
    for (final category in availableCategories) {
      menuItems.add(
        PopupMenuItem<String>(
          value: 'category_${category.name}',
          height: 32,
          child: Container(
            padding: EdgeInsets.only(left: 12),
            child: Row(
              children: [
                Icon(
                   () {
                     final iconData = CategoryIconService.getIconByName(category.iconName ?? '');
                     return iconData?.icon ?? Icons.folder;
                   }(),
                   size: 16,
                   color: Color(0xFF495057),
                 ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontFamily: 'Segoe UI',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.program.category == category.name) ...[
                  SizedBox(width: 8),
                  Icon(Icons.check, size: 16, color: Colors.green[600]),
                ],
              ],
            ),
          ),
        ),
      );
    }
    
    // 分隔线
    menuItems.add(PopupMenuDivider(height: 1));
    
    // 删除选项
    menuItems.add(
      PopupMenuItem<String>(
        value: 'delete',
        height: 32,
        child: Row(
          children: [
            SizedBox(width: 4),
            Icon(Icons.delete, size: 16, color: Colors.red[600]),
            SizedBox(width: 8),
            Text(
              '删除',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[600],
                fontFamily: 'Segoe UI',
              ),
            ),
          ],
        ),
      ),
    );

    showMenu<dynamic>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide(color: Colors.grey[400]!, width: 1),
      ),
      items: menuItems,
    ).then((value) {
      if (value != null) {
        if (value == 'delete') {
          _showDeleteConfirmDialog();
        } else if (value.toString().startsWith('category_')) {
          final categoryValue = value.toString().substring(9); // 移除 'category_' 前缀
          if (categoryValue == 'none') {
            _changeProgramCategory(null);
          } else {
            _changeProgramCategory(categoryValue);
          }
        }
      }
    });

  }


  void _changeProgramCategory(String? newCategory) async {
    try {
      final DatabaseService databaseService = DatabaseService();
      
      // 创建更新后的程序对象
      final updatedProgram = Program(
        id: widget.program.id,
        name: widget.program.name,
        path: widget.program.path,
        arguments: widget.program.arguments,
        iconPath: widget.program.iconPath,
        category: newCategory,
        isFrequent: widget.program.isFrequent,
      );
      
      // 更新数据库
      await databaseService.updateProgram(updatedProgram);
      
      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newCategory != null 
                ? '程序 "${widget.program.name}" 已移动到类别 "$newCategory"'
                : '程序 "${widget.program.name}" 已移除类别分类'
          ),
          duration: Duration(seconds: 2),
        ),
      );
      
      // 通知父组件刷新
      widget.onCategoryChanged?.call();
      
    } catch (e) {
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更改类别失败: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('确认删除'),
            ],
          ),
          content: Text('确定要删除程序 "${widget.program.name}" 吗？\n\n此操作无法撤销。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDelete?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('删除'),
            ),
          ],
        );
      },
    );
  }
}
