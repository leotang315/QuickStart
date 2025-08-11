import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomTitleBar extends StatefulWidget {
  final String title;
  final Function(String)? onLanguageChange;

  const CustomTitleBar({Key? key, required this.title, this.onLanguageChange})
    : super(key: key);

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    final isMaximized = await windowManager.isMaximized();
    setState(() {
      _isMaximized = isMaximized;
    });
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE1E5E9), width: 1)),
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
          // 应用图标和标题区域（可拖拽）
          Expanded(
            child: DragToMoveArea(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // 应用图标
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Color(0xFF0078D4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.rocket_launch,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    // 应用标题
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: Color(0xFF212529),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 语言切换按钮
          _buildLanguageButton(),
          // 窗口控制按钮
          _buildWindowControls(),
        ],
      ),
    );
  }

  Widget _buildLanguageButton() {
    return PopupMenuButton<String>(
      tooltip: AppLocalizations.of(context)!.languageToggle,
      onSelected: (String languageCode) {
        widget.onLanguageChange?.call(languageCode);
      },
      itemBuilder:
          (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'zh',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('🇨🇳'), SizedBox(width: 8), Text('中文 (简体)')],
              ),
            ),
            PopupMenuItem<String>(
              value: 'en',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('🇺🇸'), SizedBox(width: 8), Text('English')],
              ),
            ),
          ],
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(Icons.language, size: 16, color: Color(0xFF6C757D)),
      ),
    );
  }

  Widget _buildWindowControls() {
    return Row(
      children: [
        // 最小化按钮
        _buildControlButton(
          icon: Icons.remove,
          onTap: () => windowManager.minimize(),
          tooltip: AppLocalizations.of(context)!.minimize,
        ),
        // 最大化/还原按钮
        _buildControlButton(
          icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
          onTap: () async {
            if (_isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
          tooltip:
              _isMaximized
                  ? AppLocalizations.of(context)!.restore
                  : AppLocalizations.of(context)!.maximize,
        ),
        // 关闭按钮
        _buildControlButton(
          icon: Icons.close,
          onTap: () => windowManager.close(),
          tooltip: AppLocalizations.of(context)!.close,
          isClose: true,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isClose = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: isClose ? Color(0xFFE81123) : Color(0xFFF0F0F0),
          child: SizedBox(
            width: 46,
            height: 32,
            child: Icon(
              icon,
              size: 16,
              color: Colors.black,
              textDirection: TextDirection.ltr,
              semanticLabel: tooltip,
            ),
          ),
        ),
      ),
    );
  }
}

// 拖拽移动区域组件
class DragToMoveArea extends StatelessWidget {
  final Widget child;

  const DragToMoveArea({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        windowManager.startDragging();
      },
      onDoubleTap: () async {
        bool isMaximized = await windowManager.isMaximized();
        if (isMaximized) {
          windowManager.unmaximize();
        } else {
          windowManager.maximize();
        }
      },
      child: child,
    );
  }
}
