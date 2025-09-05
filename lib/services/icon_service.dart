import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/custom_icon.dart';
import 'database_service.dart';

/// 图标资源类型枚举
enum IconResourceType {
  icon, // 预定义图标 (icon:name)
  emoji, // emoji (emoji:char)
  customIcon, // 自定义图标 (custom:id)
  file, // 本地文件 (file:path)
  network, // 网络图片 (network:url)
  unknown, // 未知类型
}

/// 图标服务类
/// 提供统一的图标Widget获取接口
class IconService {
  static final IconService _instance = IconService._internal();
  factory IconService() => _instance;
  IconService._internal();

  static IconService get instance => _instance;

  /// 默认的fallback图标
  static const IconData _defaultFallbackIcon = Icons.help_outline;

  /// 预定义图标列表
  static const Map<String, String> _predefinedIconsMap = {
    'home': 'icon:home',
    'settings': 'icon:settings',
    'search': 'icon:search',
    'favorite': 'icon:favorite',
    'star': 'icon:star',
    'folder': 'icon:folder',
    'file': 'icon:file',
    'edit': 'icon:edit',
    'delete': 'icon:delete',
    'add': 'icon:add',
    'remove': 'icon:remove',
    'save': 'icon:save',
    'download': 'icon:download',
    'upload': 'icon:upload',
    'share': 'icon:share',
    'copy': 'icon:copy',
    'cut': 'icon:cut',
    'paste': 'icon:paste',
    'undo': 'icon:undo',
    'redo': 'icon:redo',
  };

  /// 常用emoji列表
  static const Map<String, String> _commonEmojisMap = {
    '😀': 'emoji:😀',
    '😃': 'emoji:😃',
    '😄': 'emoji:😄',
    '😁': 'emoji:😁',
    '😆': 'emoji:😆',
    '😅': 'emoji:😅',
    '😂': 'emoji:😂',
    '🤣': 'emoji:🤣',
    '😊': 'emoji:😊',
    '😇': 'emoji:😇',
    '🙂': 'emoji:🙂',
    '🙃': 'emoji:🙃',
    '😉': 'emoji:😉',
    '😌': 'emoji:😌',
    '😍': 'emoji:😍',
    '🥰': 'emoji:🥰',
    '😘': 'emoji:😘',
    '😗': 'emoji:😗',
    '😙': 'emoji:😙',
    '😚': 'emoji:😚',
    '😋': 'emoji:😋',
    '😛': 'emoji:😛',
    '😝': 'emoji:😝',
    '😜': 'emoji:😜',
    '🤪': 'emoji:🤪',
    '🤨': 'emoji:🤨',
    '🧐': 'emoji:🧐',
    '🤓': 'emoji:🤓',
    '😎': 'emoji:😎',
    '🤩': 'emoji:🤩',
    '🥳': 'emoji:🥳',
    '😏': 'emoji:😏',
    '⭐': 'emoji:⭐',
    '🌟': 'emoji:🌟',
    '💫': 'emoji:💫',
    '✨': 'emoji:✨',
    '🔥': 'emoji:🔥',
    '💯': 'emoji:💯',
    '💢': 'emoji:💢',
    '💥': 'emoji:💥',
    '💦': 'emoji:💦',
    '💨': 'emoji:💨',
    '🕳️': 'emoji:🕳️',
    '💣': 'emoji:💣',
    '💬': 'emoji:💬',
    '👁️‍🗨️': 'emoji:👁️‍🗨️',
    '🗨️': 'emoji:🗨️',
    '🗯️': 'emoji:🗯️',
    '💭': 'emoji:💭',
    '💤': 'emoji:💤',
    '👋': 'emoji:👋',
    '🤚': 'emoji:🤚',
    '🖐️': 'emoji:🖐️',
    '✋': 'emoji:✋',
    '🖖': 'emoji:🖖',
    '👌': 'emoji:👌',
    '🤏': 'emoji:🤏',
    '✌️': 'emoji:✌️',
    '🤞': 'emoji:🤞',
    '🤟': 'emoji:🤟',
    '🤘': 'emoji:🤘',
    '🤙': 'emoji:🤙',
    '👈': 'emoji:👈',
    '👉': 'emoji:👉',
    '👆': 'emoji:👆',
    '🖕': 'emoji:🖕',
    '👇': 'emoji:👇',
    '☝️': 'emoji:☝️',
    '👍': 'emoji:👍',
    '👎': 'emoji:👎',
    '✊': 'emoji:✊',
    '👊': 'emoji:👊',
    '🤛': 'emoji:🤛',
    '🤜': 'emoji:🤜',
    '👏': 'emoji:👏',
    '🙌': 'emoji:🙌',
    '👐': 'emoji:👐',
    '🤲': 'emoji:🤲',
    '🤝': 'emoji:🤝',
    '🙏': 'emoji:🙏',
  };

  /// 根据iconResource参数获取对应的Widget
  ///
  /// 支持的格式：
  /// - icon:icon_name (预定义图标)
  /// - emoji:emoji_char (emoji)
  /// - file:path (本地文件)
  /// - custom:id (自定义图标)
  /// - network:url (网络图片)
  ///
  /// [iconResource] 图标资源字符串，可以为null
  /// [size] 图标大小，默认24.0
  /// [color] 图标颜色，可选
  /// [fallback] 当图标无法加载时的备用Widget
  ///
  /// 返回对应的Widget，如果iconResource为null或无效，返回默认图标
  Widget getIconWidget(
    String? iconResource, {
    double size = 24.0,
    Color? color,
  }) {
    final fallbackWidget = Icon(
      _defaultFallbackIcon,
      size: size,
      color: color ?? Colors.grey,
    );
    // 如果iconResource为null或空字符串，返回默认图标
    if (iconResource == null || iconResource.isEmpty) {
      return fallbackWidget;
    }

    final type = getIconResourceType(iconResource);

    switch (type) {
      case IconResourceType.icon:
        return _buildPreDefinedIcon(iconResource, size, color, fallbackWidget);
      case IconResourceType.emoji:
        return _buildEmojiIcon(iconResource, size, color, fallbackWidget);
      case IconResourceType.customIcon:
        return _buildCustomIcon(iconResource, size, color, fallbackWidget);
      case IconResourceType.file:
        return _buildFileIcon(iconResource, size, color, fallbackWidget);
      case IconResourceType.network:
        return _buildNetworkIcon(iconResource, size, color, fallbackWidget);
      default:
        return fallbackWidget;
    }
  }

  /// 构建预定义图标
  Widget _buildPreDefinedIcon(
    String iconResource,
    double size,
    Color? color,
    Widget fallback,
  ) {
    final iconName = iconResource.substring(5); // 移除 "icon:" 前缀
    final iconMap = _getPreDefinedIconMap();

    final iconData = iconMap[iconName];
    if (iconData != null) {
      return Icon(iconData, size: size, color: color);
    }
    return fallback;
  }

  /// 构建Emoji图标
  Widget _buildEmojiIcon(
    String iconResource,
    double size,
    Color? color,
    Widget fallback,
  ) {
    final emoji = iconResource.substring(6); // 移除 "emoji:" 前缀
    if (emoji.isNotEmpty) {
      return Text(emoji, style: TextStyle(fontSize: size, color: color));
    }
    return fallback;
  }

  /// 构建自定义图标
  Widget _buildCustomIcon(
    String iconResource,
    double size,
    Color? color,
    Widget fallback,
  ) {
    final idStr = iconResource.substring(7); // 移除 "custom:" 前缀
    final id = int.tryParse(idStr);

    if (id != null) {
      return FutureBuilder<CustomIcon?>(
        future: DatabaseService().getCustomIconById(id),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!.imageData,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            );
          }
          return fallback;
        },
      );
    }
    return fallback;
  }

  /// 构建文件图标
  Widget _buildFileIcon(
    String iconResource,
    double size,
    Color? color,
    Widget fallback,
  ) {
    final filePath = iconResource.substring(5); // 移除 "file:" 前缀
    final file = File(filePath);

    if (file.existsSync()) {
      return Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }
    return fallback;
  }

/// 构建网络图标
  Widget _buildNetworkIcon(
    String iconResource,
    double size,
    Color? color,
    Widget fallback,
  ) {
    final url = iconResource.substring(8); // 移除 "network:" 前缀

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  /// 验证图标资源是否有效
  ///
  /// [iconResource] 图标资源字符串
  /// 返回true表示资源有效，false表示无效
  Future<bool> isIconResourceValid(String? iconResource) async {
    if (iconResource == null || iconResource.isEmpty) {
      return false;
    }

    final type = getIconResourceType(iconResource);

    switch (type) {
      case IconResourceType.icon:
        final iconName = iconResource.substring(5);
        return _getPreDefinedIconMap().containsKey(iconName);
      case IconResourceType.emoji:
        final emoji = iconResource.substring(6);
        return emoji.isNotEmpty;
      case IconResourceType.file:
        final filePath = iconResource.substring(5);
        return File(filePath).existsSync();
      case IconResourceType.customIcon:
        final idStr = iconResource.substring(7);
        final id = int.tryParse(idStr);
        if (id != null) {
          final customIcon = await DatabaseService().getCustomIconById(id);
          return customIcon != null;
        }
        return false;

      case IconResourceType.network:
        final url = iconResource.substring(8);
        return Uri.tryParse(url) != null;
      default:
        return false;
    }
  }

  /// 获取图标资源类型
  ///
  /// [iconResource] 图标资源字符串
  /// 返回对应的IconResourceType枚举值
  IconResourceType getIconResourceType(String? iconResource) {
    if (iconResource == null || iconResource.isEmpty) {
      return IconResourceType.unknown;
    }

    if (iconResource.startsWith('icon:')) {
      return IconResourceType.icon;
    } else if (iconResource.startsWith('emoji:')) {
      return IconResourceType.emoji;
    } else if (iconResource.startsWith('file:')) {
      return IconResourceType.file;
    } else if (iconResource.startsWith('custom:')) {
      return IconResourceType.customIcon;
    } else if (iconResource.startsWith('network:')) {
      return IconResourceType.network;
    }

    return IconResourceType.unknown;
  }

  /// 获取预定义图标映射表
  Map<String, IconData> _getPreDefinedIconMap() {
    return {
      'folder': Icons.folder,
      'file': Icons.insert_drive_file,
      'app': Icons.apps,
      'settings': Icons.settings,
      'home': Icons.home,
      'search': Icons.search,
      'favorite': Icons.favorite,
      'star': Icons.star,
      'play': Icons.play_arrow,
      'pause': Icons.pause,
      'stop': Icons.stop,
      'refresh': Icons.refresh,
      'delete': Icons.delete,
      'edit': Icons.edit,
      'add': Icons.add,
      'remove': Icons.remove,
      'close': Icons.close,
      'check': Icons.check,
      'arrow_back': Icons.arrow_back,
      'arrow_forward': Icons.arrow_forward,
      'arrow_up': Icons.arrow_upward,
      'arrow_down': Icons.arrow_downward,
    };
  }

  /// 获取所有可用的图标
  ///
  /// 返回包含预定义图标、emoji和自定义图标的列表
  Future<Map<String, List<String>>> getAllAvailableIcons() async {
    final result = <String, List<String>>{};

    // 预定义图标
    result['predefined'] = _predefinedIconsMap.values.toList();

    // 常用emoji
    result['emoji'] = _commonEmojisMap.values.toList();

    // 自定义图标
    final customIcons = await DatabaseService().getCustomIcons();
    result['custom'] = customIcons.map((icon) => 'custom:${icon.id}').toList();

    return result;
  }

  /// 上传自定义图标
  ///
  /// [name] 图标名称
  /// [filePath] 可选的文件路径
  /// 返回创建的CustomIcon对象，失败时返回null
  Future<CustomIcon?> uploadCustomIcon({
    required String name,
    String? filePath,
  }) async {
    try {
      // 如果没有提供文件路径，使用文件选择器
      String? selectedFilePath = filePath;
      if (selectedFilePath == null) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.single.path != null) {
          selectedFilePath = result.files.single.path!;
        } else {
          return null;
        }
      }

      final file = File(selectedFilePath);
      if (!file.existsSync()) {
        return null;
      }

      // 检查文件格式
      if (!isSupportedImageFormat(selectedFilePath)) {
        return null;
      }

      // 检查名称是否已存在
      if (await DatabaseService().isCustomIconNameExists(name)) {
        return null;
      }

      // 读取文件数据
      final imageData = await file.readAsBytes();
      final fileSize = imageData.length;

      // 获取MIME类型
      String mimeType = 'image/png';
      final extension = selectedFilePath.split('.').last.toLowerCase();
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
      }

      // 创建CustomIcon对象
      final customIcon = CustomIcon(
        name: name,
        originalPath: selectedFilePath,
        imageData: imageData,
        mimeType: mimeType,
        fileSize: fileSize,
        createdAt: DateTime.now(),
      );

      // 保存到数据库
      final id = await DatabaseService().insertCustomIcon(customIcon);

      // 返回带有ID的CustomIcon对象
      return CustomIcon(
        id: id,
        name: name,
        originalPath: selectedFilePath,
        imageData: imageData,
        mimeType: mimeType,
        fileSize: fileSize,
        createdAt: customIcon.createdAt,
      );
    } catch (e) {
      return null;
    }
  }

  /// 删除自定义图标
  ///
  /// [id] 自定义图标ID
  /// 返回true表示删除成功，false表示失败
  Future<bool> deleteCustomIcon(int id) async {
    try {
      final result = await DatabaseService().deleteCustomIcon(id);
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  /// 获取所有自定义图标
  Future<List<CustomIcon>> getCustomIcons() async {
    return await DatabaseService().getCustomIcons();
  }

  /// 检查文件是否为支持的图片格式
  ///
  /// [fileName] 文件名
  /// 返回true表示支持，false表示不支持
  bool isSupportedImageFormat(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return getSupportedImageFormats().contains(extension);
  }

  /// 获取支持的图片格式列表
  ///
  /// 返回支持的文件扩展名列表
  List<String> getSupportedImageFormats() {
    return ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'ico'];
  }


}
