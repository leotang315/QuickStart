import 'package:flutter/material.dart';

import '../models/program.dart';
import '../services/icon_service.dart';
import '../services/launcher_service.dart';

class ProgramTile extends StatefulWidget {
  final Program program;
  final LauncherService launcherService;
  final VoidCallback? onDelete;
  final bool isEditMode;
  final VoidCallback? onLongPress;

  const ProgramTile({
    Key? key,
    required this.program,
    required this.launcherService,
    this.onDelete,
    this.isEditMode = false,
    this.onLongPress,
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

  void _showContextMenu(Offset position) {
    if (widget.onDelete == null) return;

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
      items: [
        PopupMenuItem<dynamic>(
          height: 32,
          child: Row(
            children: [
              SizedBox(width: 4),
              Text(
                '删除',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontFamily: 'Segoe UI',
                ),
              ),
            ],
          ),
          onTap: () {
            // 延迟执行，确保菜单先关闭
            Future.delayed(Duration.zero, () {
              _showDeleteConfirmDialog();
            });
          },
        ),
        PopupMenuItem<dynamic>(
          height: 1,
          enabled: false,
          child: Divider(height: 1, thickness: 1, color: Colors.grey[300]),
        ),
        PopupMenuItem<dynamic>(
          height: 32,
          child: Row(
            children: [
              SizedBox(width: 4),
              Text(
                '属性',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontFamily: 'Segoe UI',
                ),
              ),
            ],
          ),
          onTap: () {
            // 可以在这里添加属性功能
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('属性功能待实现')));
          },
        ),
      ],
    );
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
