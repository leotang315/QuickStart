import 'package:flutter/material.dart';

import '../models/category.dart';

/// 多功能图标选择器
/// 支持Emoji、Icons和自定义上传图标
class MultiIconSelector extends StatefulWidget {
  final String selectedIconResource;
  final Function(String iconResource, IconData? icon, String? imagePath) onIconSelected;
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


  // Emoji数据
  final List<String> _emojiCategories = [ '表情', '人物', '动物', '食物', '活动', '旅行', '物品', '符号'];
  final Map<String, List<String>> _emojiData = {
    '表情': [
      '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
      '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚',
      '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🤩',
      '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣',
      '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬'
    ],
    '人物': [
      '👶', '🧒', '👦', '👧', '🧑', '👱', '👨', '🧔', '👩', '🧓',
      '👴', '👵', '🙍', '🙎', '🙅', '🙆', '💁', '🙋', '🧏', '🙇',
      '🤦', '🤷', '👮', '🕵️', '💂', '👷', '🤴', '👸', '👳', '👲'
    ],
    '动物': [
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
      '🦁', '🐮', '🐷', '🐽', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒',
      '🐔', '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦅', '🦉', '🦇'
    ],
    '食物': [
      '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🫐', '🍈',
      '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🍆', '🥑', '🥦',
      '🥬', '🥒', '🌶️', '🫑', '🌽', '🥕', '🫒', '🧄', '🧅', '🥔'
    ],
    '活动': [
      '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱',
      '🪀', '🏓', '🏸', '🏒', '🏑', '🥍', '🏏', '🪃', '🥅', '⛳'
    ],
    '旅行': [
      '🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚐',
      '🛻', '🚚', '🚛', '🚜', '🏍️', '🛵', '🚲', '🛴', '🛹', '🛼'
    ],
    '物品': [
      '⌚', '📱', '📲', '💻', '⌨️', '🖥️', '🖨️', '🖱️', '🖲️', '🕹️',
      '🗜️', '💽', '💾', '💿', '📀', '📼', '📷', '📸', '📹', '🎥'
    ],
    '符号': [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
      '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '☮️'
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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
              children: [
                _buildEmojiTab(),
                _buildIconsTab(),
              ],
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
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(text: 'Emoji'),
          Tab(text: 'Icons'),
        ],
      ),
    );
  }

  /// 构建Emoji标签页
  Widget _buildEmojiTab() {
    return Column(
      children: [
        // Emoji分类标签
        Container(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _emojiCategories.length,
            itemBuilder: (context, index) {
              final category = _emojiCategories[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(
                    category,
                    style: TextStyle(fontSize: 12),
                  ),
                  selected: false,
                  onSelected: (selected) {
                    // TODO: 实现分类切换
                  },
                ),
              );
            },
          ),
        ),
        // Emoji网格
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: _emojiData['表情']!.length,
            itemBuilder: (context, index) {
              final emoji = _emojiData['表情']![index];
              final isSelected = widget.selectedIconResource == 'emoji:$emoji';
              
              return GestureDetector(
                onTap: () {
                  widget.onIconSelected('emoji:$emoji', null, null);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(0xFF0078D4).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? Color(0xFF0078D4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
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
      itemCount: Category.flutterIcons.length,
      itemBuilder: (context, index) {
        final entry = Category.flutterIcons.entries.elementAt(index);
        final iconKey = entry.key;
        final iconData = entry.value;
        final iconResource = 'icon:$iconKey';
        final isSelected = widget.selectedIconResource == iconResource;

        return GestureDetector(
          onTap: () {
            widget.onIconSelected(iconResource, iconData, null);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Color(0xFF0078D4).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected
                    ? Color(0xFF0078D4)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              iconData,
              size: 16,
              color: isSelected
                  ? Color(0xFF0078D4)
                  : Color(0xFF6C757D),
            ),
          ),
        );
      },
    );
  }






}