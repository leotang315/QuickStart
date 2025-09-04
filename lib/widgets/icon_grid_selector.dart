import 'package:flutter/material.dart';
import '../models/category.dart';

/// 图标网格选择器组件
/// 用于显示和选择图标的网格界面
class IconGridSelector extends StatelessWidget {
  final String selectedIconResource;
  final Function(String iconResource, IconData icon) onIconSelected;
  final double height;
  final int crossAxisCount;

  const IconGridSelector({
    Key? key,
    required this.selectedIconResource,
    required this.onIconSelected,
    this.height = 140,
    this.crossAxisCount = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: SingleChildScrollView(
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: Category.flutterIcons.length,
          itemBuilder: (context, index) {
            final entry = Category.flutterIcons.entries.elementAt(index);
            final iconKey = entry.key;
            final iconData = entry.value;
            final iconResource = "icon:" + iconKey;
            final isSelected = selectedIconResource == iconResource;

            return _IconGridItem(
              iconData: iconData,
              iconResource: iconResource,
              isSelected: isSelected,
              onTap: () => onIconSelected(iconResource, iconData),
            );
          },
        ),
      ),
    );
  }
}

/// 图标网格项组件
class _IconGridItem extends StatelessWidget {
  final IconData iconData;
  final String iconResource;
  final bool isSelected;
  final VoidCallback onTap;

  const _IconGridItem({
    Key? key,
    required this.iconData,
    required this.iconResource,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF0078D4).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? Color(0xFF0078D4)
                : Color(0xFFE1E5E9),
            width: 1,
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
  }
}