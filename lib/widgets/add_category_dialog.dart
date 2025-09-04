import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../controllers/category_dialog_controller.dart';
import '../widgets/icon_grid_selector.dart';
import '../models/category.dart';

/// 添加类别对话框组件
/// 独立的对话框 Widget，用于添加新的类别
class AddCategoryDialog extends StatefulWidget {
  final List<Category> existingCategories;
  final VoidCallback onCategoryAdded;
  final Function(String, {Color? color}) onShowMessage;

  const AddCategoryDialog({
    Key? key,
    required this.existingCategories,
    required this.onCategoryAdded,
    required this.onShowMessage,
  }) : super(key: key);

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  late TextEditingController _categoryNameController;
  late String _selectedIconResource;
  late IconData _selectedIcon;
  bool _isLoading = false;
  late CategoryDialogController _controller;

  @override
  void initState() {
    super.initState();
    _categoryNameController = TextEditingController();
    _controller = CategoryDialogController(
      onShowMessage: widget.onShowMessage,
    );
    _selectedIconResource = _controller.getDefaultIconResource();
    _selectedIcon = _controller.getDefaultIcon();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 480,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: 20),
            _buildNameInput(context),
            SizedBox(height: 20),
            _buildIconSelector(context),
            SizedBox(height: 20),
            _buildButtons(context),
          ],
        ),
      ),
    );
  }

  /// 构建对话框头部
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.add_circle_outline,
          size: 24,
          color: Color(0xFF0078D4),
        ),
        SizedBox(width: 12),
        Text(
          AppLocalizations.of(context)!.addCategory,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212529),
          ),
        ),
        Spacer(),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Color(0xFF6C757D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.close,
              size: 14,
              color: Color(0xFF6C757D),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建名称输入框
  Widget _buildNameInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.categoryName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF495057),
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 40,
          child: TextField(
            controller: _categoryNameController,
            enabled: !_isLoading,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enterCategoryName,
              hintStyle: TextStyle(
                color: Color(0xFF6C757D),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Color(0xFFE1E5E9),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Color(0xFFE1E5E9),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: Color(0xFF0078D4),
                  width: 1,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF212529),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建图标选择器
  Widget _buildIconSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.selectIcon,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF495057),
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Color(0xFF0078D4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedIcon,
                    size: 14,
                    color: Color(0xFF0078D4),
                  ),
                  SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.selected,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0078D4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        IconGridSelector(
          selectedIconResource: _selectedIconResource,
          onIconSelected: (iconResource, icon) {
            setState(() {
              _selectedIconResource = iconResource;
              _selectedIcon = icon;
            });
          },
        ),
      ],
    );
  }

  /// 构建按钮区域
  Widget _buildButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 取消按钮
        Container(
          height: 36,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFF424242),
              side: BorderSide(
                color: Color(0xFFE1E5E9),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        // 添加按钮
        Container(
          height: 36,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleAddCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0078D4),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.add,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// 处理添加类别
  Future<void> _handleAddCategory() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _controller.addCategory(
        name: _categoryNameController.text,
        iconResource: _selectedIconResource,
        context: context,
        existingCategories: widget.existingCategories,
        onCategoryAdded: widget.onCategoryAdded,
      );

      if (success && mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}