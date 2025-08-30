import 'package:flutter/material.dart';

class CategoryIconService {
  // 专门用于类别的默认图标数据
  static final List<CategoryIcon> categoryIcons = [
    // 应用程序类别
    CategoryIcon(
      name: '应用程序',
      icon: Icons.apps,
      description: '通用应用程序',
    ),
    CategoryIcon(
      name: '桌面应用',
      icon: Icons.desktop_windows,
      description: '桌面软件',
    ),
    CategoryIcon(
      name: '移动应用',
      icon: Icons.phone_android,
      description: '移动端应用',
    ),
    CategoryIcon(
      name: '网页应用',
      icon: Icons.web,
      description: '网页和浏览器应用',
    ),
    
    // 开发工具类别
    CategoryIcon(
      name: '开发工具',
      icon: Icons.code,
      description: '编程和开发工具',
    ),
    CategoryIcon(
      name: '终端工具',
      icon: Icons.terminal,
      description: '命令行和终端工具',
    ),
    CategoryIcon(
      name: '数据库',
      icon: Icons.storage,
      description: '数据库管理工具',
    ),
    CategoryIcon(
      name: '版本控制',
      icon: Icons.source,
      description: 'Git和版本控制工具',
    ),
    
    // 办公软件类别
    CategoryIcon(
      name: '办公软件',
      icon: Icons.business_center,
      description: '办公和商务软件',
    ),
    CategoryIcon(
      name: '文档处理',
      icon: Icons.description,
      description: '文档编辑和处理',
    ),
    CategoryIcon(
      name: '表格工具',
      icon: Icons.table_chart,
      description: '电子表格和数据分析',
    ),
    CategoryIcon(
      name: '演示工具',
      icon: Icons.slideshow,
      description: '演示文稿和幻灯片',
    ),
    CategoryIcon(
      name: '邮件通讯',
      icon: Icons.email,
      description: '邮件和通讯工具',
    ),
    
    // 多媒体类别
    CategoryIcon(
      name: '多媒体',
      icon: Icons.perm_media,
      description: '多媒体和娱乐',
    ),
    CategoryIcon(
      name: '音频工具',
      icon: Icons.music_note,
      description: '音乐和音频处理',
    ),
    CategoryIcon(
      name: '视频工具',
      icon: Icons.video_library,
      description: '视频播放和编辑',
    ),
    CategoryIcon(
      name: '图像处理',
      icon: Icons.image,
      description: '图片查看和编辑',
    ),
    CategoryIcon(
      name: '录制工具',
      icon: Icons.mic,
      description: '录音和录屏工具',
    ),
    
    // 游戏类别
    CategoryIcon(
      name: '游戏',
      icon: Icons.games,
      description: '游戏和娱乐软件',
    ),
    CategoryIcon(
      name: '电竞游戏',
      icon: Icons.sports_esports,
      description: '电子竞技和在线游戏',
    ),
    CategoryIcon(
      name: '休闲游戏',
      icon: Icons.casino,
      description: '休闲和益智游戏',
    ),
    
    // 系统工具类别
    CategoryIcon(
      name: '系统工具',
      icon: Icons.settings_applications,
      description: '系统管理和工具',
    ),
    CategoryIcon(
      name: '文件管理',
      icon: Icons.folder_open,
      description: '文件和文件夹管理',
    ),
    CategoryIcon(
      name: '系统设置',
      icon: Icons.settings,
      description: '系统配置和设置',
    ),
    CategoryIcon(
      name: '任务管理',
      icon: Icons.task_alt,
      description: '进程和任务管理',
    ),
    CategoryIcon(
      name: '实用工具',
      icon: Icons.build,
      description: '实用小工具',
    ),
    CategoryIcon(
      name: '压缩工具',
      icon: Icons.archive,
      description: '文件压缩和解压',
    ),
    
    // 网络工具类别
    CategoryIcon(
      name: '网络工具',
      icon: Icons.language,
      description: '网络和互联网工具',
    ),
    CategoryIcon(
      name: '浏览器',
      icon: Icons.public,
      description: '网页浏览器',
    ),
    CategoryIcon(
      name: '下载工具',
      icon: Icons.download,
      description: '文件下载管理',
    ),
    CategoryIcon(
      name: '云存储',
      icon: Icons.cloud,
      description: '云存储和同步',
    ),
    CategoryIcon(
      name: '远程工具',
      icon: Icons.desktop_access_disabled,
      description: '远程桌面和控制',
    ),
    
    // 安全工具类别
    CategoryIcon(
      name: '安全工具',
      icon: Icons.security,
      description: '安全和防护软件',
    ),
    CategoryIcon(
      name: '防病毒',
      icon: Icons.shield,
      description: '杀毒和安全防护',
    ),
    CategoryIcon(
      name: '密码管理',
      icon: Icons.lock,
      description: '密码和认证管理',
    ),
    CategoryIcon(
      name: '隐私保护',
      icon: Icons.privacy_tip,
      description: '隐私和数据保护',
    ),
    
    // 学习教育类别
    CategoryIcon(
      name: '教育学习',
      icon: Icons.school,
      description: '教育和学习软件',
    ),
    CategoryIcon(
      name: '语言学习',
      icon: Icons.translate,
      description: '语言学习和翻译',
    ),
    CategoryIcon(
      name: '科学计算',
      icon: Icons.calculate,
      description: '科学计算和数学',
    ),
    
    // 其他类别
    CategoryIcon(
      name: '其他',
      icon: Icons.more_horiz,
      description: '其他未分类软件',
    ),
    CategoryIcon(
      name: '收藏夹',
      icon: Icons.star,
      description: '收藏和书签',
    ),
    CategoryIcon(
      name: '临时文件',
      icon: Icons.folder_special,
      description: '临时和测试文件',
    ),
  ];
  
  // 搜索类别图标
  static List<CategoryIcon> searchIcons(String query) {
    if (query.isEmpty) return categoryIcons;
    
    return categoryIcons.where((icon) => 
      icon.name.toLowerCase().contains(query.toLowerCase()) ||
      icon.description.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
  
  // 根据名称获取图标
  static CategoryIcon? getIconByName(String name) {
    try {
      return categoryIcons.firstWhere((icon) => icon.name == name);
    } catch (e) {
      return null;
    }
  }
  
  // 获取iconResource格式的字符串
  static String getIconResource(String name) {
    final categoryIcon = getIconByName(name);
    if (categoryIcon == null) {
      return 'icon:folder'; // 默认图标
    }
    
    // 将CategoryIcon转换为iconResource格式
    final iconName = _getIconNameFromIconData(categoryIcon.icon);
    return 'icon:$iconName';
  }
  
  // 获取所有可用的iconResource列表
  static List<String> getAllIconResources() {
    return categoryIcons.map((categoryIcon) {
      final iconName = _getIconNameFromIconData(categoryIcon.icon);
      return 'icon:$iconName';
    }).toList();
  }
  
  // 根据IconData获取图标名称
  static String _getIconNameFromIconData(IconData iconData) {
    final iconMap = {
      Icons.apps: 'apps',
      Icons.desktop_windows: 'desktop_windows',
      Icons.phone_android: 'phone_android',
      Icons.web: 'web',
      Icons.code: 'code',
      Icons.terminal: 'terminal',
      Icons.storage: 'storage',
      Icons.source: 'source',
      Icons.work: 'work',
      Icons.description: 'description',
      Icons.calculate: 'calculate',
      Icons.palette: 'palette',
      Icons.music_note: 'music_note',
      Icons.videocam: 'videocam',
      Icons.games: 'games',
      Icons.security: 'security',
      Icons.build: 'build',
      Icons.cloud: 'cloud',
      Icons.school: 'school',
      Icons.translate: 'translate',
      Icons.more_horiz: 'more_horiz',
      Icons.star: 'star',
      Icons.folder_special: 'folder_special',
    };
    return iconMap[iconData] ?? 'folder';
  }
  
  // 根据iconResource获取CategoryIcon（用于UI显示）
  static CategoryIcon? getCategoryIconFromResource(String iconResource) {
    if (!iconResource.startsWith('icon:')) {
      return null;
    }
    
    final iconName = iconResource.substring(5);
    return categoryIcons.firstWhere(
      (icon) => _getIconNameFromIconData(icon.icon) == iconName,
      orElse: () => CategoryIcon(
        name: '未知图标',
        icon: Icons.help,
        description: '未知的图标类型',
      ),
    );
  }
}

class CategoryIcon {
  final String name;
  final IconData icon;
  final String description;
  
  const CategoryIcon({
    required this.name,
    required this.icon,
    required this.description,
  });
}