import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../controllers/category_dialog_controller.dart';
import '../widgets/multi_icon_selector.dart';
import '../services/icon_service.dart';

class AddCategoryDialog extends StatefulWidget {
  final VoidCallback onCategoryAdded;

  const AddCategoryDialog({Key? key, required this.onCategoryAdded})
    : super(key: key);

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  late TextEditingController _categoryNameController;
  late CategoryDialogController _categoryDialogController;
  late String _selectedIconResource = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _categoryDialogController = CategoryDialogController();
    _categoryNameController = TextEditingController();
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.add_circle_outline, size: 24, color: Color(0xFF0078D4)),
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
            child: Icon(Icons.close, size: 14, color: Color(0xFF6C757D)),
          ),
        ),
      ],
    );
  }

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
              hintStyle: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Color(0xFFE1E5E9), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Color(0xFFE1E5E9), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Color(0xFF0078D4), width: 1),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: TextStyle(fontSize: 14, color: Color(0xFF212529)),
          ),
        ),
      ],
    );
  }

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
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF0078D4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSelectedIconDisplay(),
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
        MultiIconSelector(
          selectedIconResource: _selectedIconResource,
          onIconSelected: (iconResource) {
            setState(() {
              _selectedIconResource = iconResource;
            });
          },
          height: 200,
        ),
      ],
    );
  }

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
              side: BorderSide(color: Color(0xFFE1E5E9), width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child:
                _isLoading
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
      final success = await _categoryDialogController.addCategory(
        name: _categoryNameController.text,
        iconResource: _selectedIconResource,
        context: context,
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

  /// 构建选中图标的显示
  Widget _buildSelectedIconDisplay() {
    return IconService.instance.getIconWidget(
      _selectedIconResource,
      size: 14.0,
      color: Color(0xFF0078D4),
    );
  }
}
