import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/category.dart';
import '../models/custom_icon.dart';
import '../services/icon_service.dart';

/// 多功能图标选择器
/// 支持Emoji、Icons、自定义图标显示和上传图标
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

  // 从 IconService 获取的数据
  List<String> _emojiList = [];
  List<String> _iconList = [];
  List<String> _customIconList = [];
  List<CustomIcon> _customIcons = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _availableIcons = IconService.instance.getAllAvailableIcons();
    _loadIconData();
  }

  /// 从 IconService 加载图标数据
  void _loadIconData() async {
    final icons = await _availableIcons;
    final customIcons = await IconService.instance.getCustomIcons();
    setState(() {
      _emojiList = icons['emoji'] ?? [];
      _iconList = icons['icon'] ?? [];
      _customIconList = icons['custom'] ?? [];
      _customIcons = customIcons;
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
              children: [
                _buildEmojiTab(),
                _buildIconsTab(),
                _buildCustomIconsTab(),
                _buildUploadTab(),
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
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: [
          Tab(text: AppLocalizations.of(context)!.tabEmoji),
          Tab(text: AppLocalizations.of(context)!.tabIcons),
          Tab(text: AppLocalizations.of(context)!.tabCustom),
          Tab(text: AppLocalizations.of(context)!.tabUpload),
        ],
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

  /// 构建自定义图标标签页
  Widget _buildCustomIconsTab() {
    if (_customIcons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 48, color: Color(0xFF6C757D)),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noCustomIcons,
              style: TextStyle(color: Color(0xFF6C757D), fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.clickUploadTabToAdd,
              style: TextStyle(color: Color(0xFF6C757D), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: _customIcons.length,
      itemBuilder: (context, index) {
        final customIcon = _customIcons[index];
        final iconResource = 'custom:${customIcon.id}';
        final isSelected = widget.selectedIconResource == iconResource;

        return GestureDetector(
          onTap: () {
            widget.onIconSelected(iconResource);
          },
          onLongPress: () {
            _showCustomIconOptions(customIcon);
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.memory(
                customIcon.imageData,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.broken_image, color: Color(0xFF6C757D));
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建上传标签页
  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(8),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          //  minHeight: MediaQuery.of(context).size.height * 0.3,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 20,
              color: Color(0xFF0078D4),
            ),
            SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.uploadCustomIcon,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212529),
              ),
            ),
            SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.supportedFormats,
              style: TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadCustomIcon,
              icon:
                  _isUploading
                      ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Icon(Icons.add_photo_alternate),
              label: Text(_isUploading ? AppLocalizations.of(context)!.uploading : AppLocalizations.of(context)!.selectImage),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0078D4),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 上传自定义图标
  Future<void> _uploadCustomIcon() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // 先选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) {
        // 用户取消了文件选择
        return;
      }

      final selectedFilePath = result.files.single.path!;

      // 上传图标（传入文件路径）
      final customIcon = await IconService.instance.uploadCustomIcon(
        name: path.basename(selectedFilePath),
        filePath: selectedFilePath,
      );

      if (customIcon != null) {
        // 刷新自定义图标列表
        _loadIconData();

        // 自动选择新上传的图标
        widget.onIconSelected('custom:${customIcon.id}');

        // 切换到自定义图标标签页
        _tabController.animateTo(2);

        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.iconUploadSuccess), backgroundColor: Colors.green),
        );
      } else {
        // 显示失败消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.iconUploadFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.uploadError), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  /// 显示自定义图标选项菜单
  void _showCustomIconOptions(CustomIcon customIcon) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text(AppLocalizations.of(context)!.iconInfo),
                subtitle: Text(
                  '${customIcon.name} • ${(customIcon.fileSize / 1024).toStringAsFixed(1)} KB',
                ),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(AppLocalizations.of(context)!.deleteIcon, style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteCustomIcon(customIcon);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 删除自定义图标
  Future<void> _deleteCustomIcon(CustomIcon customIcon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmDeleteIcon),
          content: Text(AppLocalizations.of(context)!.deleteIconMessage(customIcon.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await IconService.instance.deleteCustomIcon(
        customIcon.id!,
      );
      if (success) {
        _loadIconData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.iconDeleteSuccess), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.iconDeleteFailed), backgroundColor: Colors.red),
        );
      }
    }
  }
}
