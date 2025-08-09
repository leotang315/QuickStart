import 'package:flutter/material.dart';
import '../services/category_icon_service.dart';

class CategoryIconSelector extends StatefulWidget {
  final String? selectedIconName;
  final Function(String?) onIconSelected;
  
  const CategoryIconSelector({
    super.key,
    this.selectedIconName,
    required this.onIconSelected,
  });
  
  @override
  State<CategoryIconSelector> createState() => _CategoryIconSelectorState();
}

class _CategoryIconSelectorState extends State<CategoryIconSelector> {
  String searchQuery = '';
  String? selectedIconName;
  
  @override
  void initState() {
    super.initState();
    selectedIconName = widget.selectedIconName;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择类别图标',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '为您的类别选择一个合适的图标',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          
          // 搜索框
          TextField(
            decoration: const InputDecoration(
              labelText: '搜索图标',
              hintText: '输入图标名称或描述',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // 图标网格
          Expanded(
            child: _buildIconGrid(),
          ),
          
          const SizedBox(height: 16),
          
          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  widget.onIconSelected(null);
                  Navigator.of(context).pop();
                },
                child: const Text('清除图标'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: selectedIconName != null ? () {
                  widget.onIconSelected(selectedIconName);
                  Navigator.of(context).pop();
                } : null,
                child: const Text('确定'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildIconGrid() {
    final icons = CategoryIconService.searchIcons(searchQuery);
    
    if (icons.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '没有找到匹配的图标',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final icon = icons[index];
        final isSelected = selectedIconName == icon.name;
        
        return InkWell(
          onTap: () {
            setState(() {
              selectedIconName = isSelected ? null : icon.name;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected 
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.grey.shade50,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon.icon,
                  size: 32,
                  color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.shade700,
                ),
                const SizedBox(height: 8),
                Text(
                  icon.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  icon.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected 
                        ? Theme.of(context).primaryColor.withOpacity(0.8)
                        : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 显示类别图标选择器的便捷方法
void showCategoryIconSelector({
  required BuildContext context,
  String? selectedIconName,
  required Function(String?) onIconSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => CategoryIconSelector(
      selectedIconName: selectedIconName,
      onIconSelected: onIconSelected,
    ),
  );
}