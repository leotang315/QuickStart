import 'dart:io';
import 'dart:typed_data';

/// 自定义图标模型
/// 用于存储用户上传的自定义图标数据
class CustomIcon {
  final int? id;
  final String name;           // 图标名称
  final String originalPath;   // 原始文件路径
  final Uint8List imageData;   // 图片二进制数据
  final String mimeType;       // MIME类型 (image/png, image/jpeg等)
  final int fileSize;          // 文件大小(字节)
  final DateTime createdAt;    // 创建时间
  final DateTime? updatedAt;   // 更新时间

  CustomIcon({
    this.id,
    required this.name,
    required this.originalPath,
    required this.imageData,
    required this.mimeType,
    required this.fileSize,
    required this.createdAt,
    this.updatedAt,
  });

  /// 从Map创建CustomIcon对象
  factory CustomIcon.fromMap(Map<String, dynamic> map) {
    return CustomIcon(
      id: map['id'],
      name: map['name'],
      originalPath: map['original_path'],
      imageData: map['image_data'],
      mimeType: map['mime_type'],
      fileSize: map['file_size'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: map['updated_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  /// 转换为Map用于数据库存储
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'original_path': originalPath,
      'image_data': imageData,
      'mime_type': mimeType,
      'file_size': fileSize,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// 从文件创建CustomIcon对象
  static Future<CustomIcon> fromFile(File file, {String? customName}) async {
    final imageData = await file.readAsBytes();
    final fileName = customName ?? _getFileNameWithoutExtension(file.path);
    final mimeType = _getMimeTypeFromExtension(file.path);
    
    return CustomIcon(
      name: fileName,
      originalPath: file.path,
      imageData: imageData,
      mimeType: mimeType,
      fileSize: imageData.length,
      createdAt: DateTime.now(),
    );
  }

  /// 获取不带扩展名的文件名
  static String _getFileNameWithoutExtension(String filePath) {
    final fileName = filePath.split('/').last.split('\\').last;
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex != -1 ? fileName.substring(0, dotIndex) : fileName;
  }

  /// 根据文件扩展名获取MIME类型
  static String _getMimeTypeFromExtension(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      case 'ico':
        return 'image/x-icon';
      default:
        return 'image/png'; // 默认为PNG
    }
  }

  /// 复制对象并更新指定字段
  CustomIcon copyWith({
    int? id,
    String? name,
    String? originalPath,
    Uint8List? imageData,
    String? mimeType,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomIcon(
      id: id ?? this.id,
      name: name ?? this.name,
      originalPath: originalPath ?? this.originalPath,
      imageData: imageData ?? this.imageData,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 验证图片数据是否有效
  bool isValidImage() {
    return imageData.isNotEmpty && 
           mimeType.startsWith('image/') && 
           fileSize > 0;
  }

  /// 获取图标资源标识符
  /// 格式: custom:id
  String get iconResource => 'custom:$id';

  @override
  String toString() {
    return 'CustomIcon{id: $id, name: $name, mimeType: $mimeType, fileSize: $fileSize}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomIcon &&
        other.id == id &&
        other.name == name &&
        other.originalPath == originalPath &&
        other.mimeType == mimeType &&
        other.fileSize == fileSize;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        originalPath.hashCode ^
        mimeType.hashCode ^
        fileSize.hashCode;
  }
}