import 'package:flutter/material.dart';

class DefaultIconService {
  // 默认图标数据，使用 Material Icons
  static final List<DefaultIcon> defaultIcons = [
    // 应用程序类
    DefaultIcon(
      name: '应用程序',
      icon: Icons.apps,
      category: '应用程序',
    ),
    DefaultIcon(
      name: '桌面应用',
      icon: Icons.desktop_windows,
      category: '应用程序',
    ),
    DefaultIcon(
      name: '移动应用',
      icon: Icons.phone_android,
      category: '应用程序',
    ),
    DefaultIcon(
      name: '网页应用',
      icon: Icons.web,
      category: '应用程序',
    ),
    
    // 开发工具类
    DefaultIcon(
      name: '代码编辑器',
      icon: Icons.code,
      category: '开发工具',
    ),
    DefaultIcon(
      name: '终端',
      icon: Icons.terminal,
      category: '开发工具',
    ),
    DefaultIcon(
      name: '数据库',
      icon: Icons.storage,
      category: '开发工具',
    ),
    DefaultIcon(
      name: '调试器',
      icon: Icons.bug_report,
      category: '开发工具',
    ),
    DefaultIcon(
      name: 'Git',
      icon: Icons.source,
      category: '开发工具',
    ),
    
    // 办公软件类
    DefaultIcon(
      name: '文档编辑',
      icon: Icons.description,
      category: '办公软件',
    ),
    DefaultIcon(
      name: '表格处理',
      icon: Icons.table_chart,
      category: '办公软件',
    ),
    DefaultIcon(
      name: '演示文稿',
      icon: Icons.slideshow,
      category: '办公软件',
    ),
    DefaultIcon(
      name: 'PDF阅读器',
      icon: Icons.picture_as_pdf,
      category: '办公软件',
    ),
    DefaultIcon(
      name: '邮件客户端',
      icon: Icons.email,
      category: '办公软件',
    ),
    
    // 多媒体类
    DefaultIcon(
      name: '音乐播放器',
      icon: Icons.music_note,
      category: '多媒体',
    ),
    DefaultIcon(
      name: '视频播放器',
      icon: Icons.play_circle_filled,
      category: '多媒体',
    ),
    DefaultIcon(
      name: '图片查看器',
      icon: Icons.image,
      category: '多媒体',
    ),
    DefaultIcon(
      name: '录音软件',
      icon: Icons.mic,
      category: '多媒体',
    ),
    DefaultIcon(
      name: '摄像头',
      icon: Icons.camera_alt,
      category: '多媒体',
    ),
    
    // 游戏类
    DefaultIcon(
      name: '游戏',
      icon: Icons.games,
      category: '游戏',
    ),
    DefaultIcon(
      name: '手柄',
      icon: Icons.sports_esports,
      category: '游戏',
    ),
    DefaultIcon(
      name: '棋牌游戏',
      icon: Icons.casino,
      category: '游戏',
    ),
    
    // 系统工具类
    DefaultIcon(
      name: '文件管理器',
      icon: Icons.folder,
      category: '系统工具',
    ),
    DefaultIcon(
      name: '系统设置',
      icon: Icons.settings,
      category: '系统工具',
    ),
    DefaultIcon(
      name: '任务管理器',
      icon: Icons.task_alt,
      category: '系统工具',
    ),
    DefaultIcon(
      name: '计算器',
      icon: Icons.calculate,
      category: '系统工具',
    ),
    DefaultIcon(
      name: '记事本',
      icon: Icons.note,
      category: '系统工具',
    ),
    DefaultIcon(
      name: '压缩工具',
      icon: Icons.archive,
      category: '系统工具',
    ),
    
    // 网络工具类
    DefaultIcon(
      name: '浏览器',
      icon: Icons.language,
      category: '网络工具',
    ),
    DefaultIcon(
      name: '下载工具',
      icon: Icons.download,
      category: '网络工具',
    ),
    DefaultIcon(
      name: 'FTP客户端',
      icon: Icons.cloud_upload,
      category: '网络工具',
    ),
    DefaultIcon(
      name: '远程桌面',
      icon: Icons.desktop_access_disabled,
      category: '网络工具',
    ),
    
    // 安全工具类
    DefaultIcon(
      name: '杀毒软件',
      icon: Icons.security,
      category: '安全工具',
    ),
    DefaultIcon(
      name: '防火墙',
      icon: Icons.shield,
      category: '安全工具',
    ),
    DefaultIcon(
      name: '密码管理',
      icon: Icons.lock,
      category: '安全工具',
    ),
    
    // 其他类
    DefaultIcon(
      name: '其他',
      icon: Icons.more_horiz,
      category: '其他',
    ),
    DefaultIcon(
      name: '收藏',
      icon: Icons.star,
      category: '其他',
    ),
    DefaultIcon(
      name: '工具',
      icon: Icons.build,
      category: '其他',
    ),
  ];
  
  // 根据分类获取图标
  static List<DefaultIcon> getIconsByCategory(String category) {
    return defaultIcons.where((icon) => icon.category == category).toList();
  }
  
  // 获取所有分类
  static List<String> getAllCategories() {
    return defaultIcons.map((icon) => icon.category).toSet().toList();
  }
  
  // 搜索图标
  static List<DefaultIcon> searchIcons(String query) {
    if (query.isEmpty) return defaultIcons;
    
    return defaultIcons.where((icon) => 
      icon.name.toLowerCase().contains(query.toLowerCase()) ||
      icon.category.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}

class DefaultIcon {
  final String name;
  final IconData icon;
  final String category;
  
  const DefaultIcon({
    required this.name,
    required this.icon,
    required this.category,
  });
}