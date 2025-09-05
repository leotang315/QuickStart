import 'dart:io';
import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  // 统一资源标识符：icon:name, file:path, http://url
  final String? iconResource;

  Category({this.id, required this.name, this.iconResource});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'iconResource': iconResource};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      iconResource: map['iconResource'] 
    );
  }

  Category copyWith({int? id, String? name, String? iconResource}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconResource: iconResource ?? this.iconResource,
    );
  }

  static final Map<String, IconData> flutterIcons = {
    'apps': Icons.apps,
    'folder': Icons.folder,
    'settings': Icons.settings,
    'code': Icons.code,
    'web': Icons.web,
    'desktop_windows': Icons.desktop_windows,
    'phone_android': Icons.phone_android,
    'terminal': Icons.terminal,
    'storage': Icons.storage,
    'source': Icons.source,
    'work': Icons.work,
    'description': Icons.description,
    'calculate': Icons.calculate,
    'palette': Icons.palette,
    'music_note': Icons.music_note,
    'videocam': Icons.videocam,
    'games': Icons.games,
    'security': Icons.security,
    'build': Icons.build,
    'cloud': Icons.cloud,
    'school': Icons.school,
    'translate': Icons.translate,
    'more_horiz': Icons.more_horiz,
    'star': Icons.star,
    'folder_special': Icons.folder_special,
  };

  Widget getIcon({double size = 24.0}) {
    if (iconResource == null) {
      return Icon(Icons.folder, size: size); // 默认图标
    }

    final resource = iconResource!;

    // Flutter图标
    if (resource.startsWith('icon:')) {
      final iconName = resource.substring(5);
      final iconData = _getFlutterIcon(iconName);
      return Icon(iconData ?? Icons.help, size: size);
    }

    // 本地文件
    if (resource.startsWith('file:')) {
      final filePath = resource.substring(5);
      return Image.file(
        File(filePath),
        width: size,
        height: size,
        errorBuilder:
            (context, error, stackTrace) =>
                Icon(Icons.broken_image, size: size),
      );
    }



    // 网络图片
    if (resource.startsWith('http')) {
      return Image.network(
        resource,
        width: size,
        height: size,
        errorBuilder:
            (context, error, stackTrace) =>
                Icon(Icons.broken_image, size: size),
      );
    }

    return Icon(Icons.help, size: size);
  }

  IconData? _getFlutterIcon(String name) {
    return flutterIcons[name];
  }
}
