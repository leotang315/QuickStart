import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/icon_service.dart';

/// 多功能图标选择器
/// 支持Emoji、Icons和自定义上传图标
class MultiIconSelector extends StatefulWidget {
  final String selectedIconResource;
  final Function(String iconResource) onIconSelected;
  final double height;

  const MultiIconSelector({
    Key? key,
    required this.selectedIconResource,
    required this.onIconSelected,
    this.height = 300,
  }) : super(key: key);

  @override
  _MultiIconSelectorState createState() => _MultiIconSelectorState();
}

class _MultiIconSelectorState extends State<MultiIconSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, List<String>>> _availableIcons;

  // 从 IconService 获取的 emoji 数据
  List<String> _emojiList = [];
  List<String> _iconList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _availableIcons = IconService.instance.getAllAvailableIcons();
    _loadEmojiData();
  }

  /// 从 IconService 加载 emoji 数据
  void _loadEmojiData() async {
    final icons = await _availableIcons;
    setState(() {
      _emojiList = icons['emoji'] ?? [];
      _iconList = icons['icon'] ?? [];
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE1E5E9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildEmojiTab(), _buildIconsTab()],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标签栏
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Color(0xFF0078D4),
        unselectedLabelColor: Color(0xFF6C757D),
        indicatorColor: Color(0xFF0078D4),
        indicatorWeight: 2,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: [Tab(text: 'Emoji'), Tab(text: 'Icons')],
      ),
    );
  }

  /// 构建Emoji标签页
  Widget _buildEmojiTab() {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: _emojiList.length,
            itemBuilder: (context, index) {
              final emojiResource = _emojiList[index];
              final emoji = IconService.instance.getIconWidget(
                emojiResource,
                size: 20,
              );
              final isSelected = widget.selectedIconResource == emojiResource;

              return GestureDetector(
                onTap: () {
                  widget.onIconSelected(emojiResource);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Color(0xFF0078D4).withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color:
                          isSelected ? Color(0xFF0078D4) : Colors.transparent,
                    ),
                  ),
                  child: Center(child: emoji),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建Icons标签页
  Widget _buildIconsTab() {
    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: _iconList.length,

      itemBuilder: (context, index) {
        final iconResource = _iconList[index];
        final icon = IconService.instance.getIconWidget(iconResource, size: 20);
        final isSelected = widget.selectedIconResource == iconResource;

        return GestureDetector(
          onTap: () {
            widget.onIconSelected(iconResource);
          },
          child: Container(
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Color(0xFF0078D4).withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? Color(0xFF0078D4) : Colors.transparent,
              ),
            ),
            child: Center(child: icon),
          ),
        );
      },
    );
  }
}
