import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/widgets.dart';

import '../utls/raw_image_provider.dart';

// 在文件顶部添加 DLL 引用
final shell32 = DynamicLibrary.open('shell32.dll');
final comctl32 = DynamicLibrary.open('comctl32.dll');

// IImageList GUID
const String IID_IImageList = '{46EB5926-582E-4017-9FDF-E8998DAA0950}';
// IImageList GUID

// Shell image list size constants
const int SHIL_LARGE = 0x0; // 32x32 = 0x0;      // 32x32
const int SHIL_SMALL = 0x1; // 16x16
const int SHIL_EXTRALARGE = 0x2; // 48x48
const int SHIL_SYSSMALL = 0x3; // 系统小图标尺寸
const int SHIL_JUMBO = 0x4; // 256x256
const int ILD_TRANSPARENT = 0x1;
// 添加 SHGetImageList 函数定义
final SHGetImageList = shell32
    .lookupFunction<
      Int32 Function(
        Int32 iImageList,
        Pointer<GUID> riid,
        Pointer<Pointer> ppv,
      ),
      int Function(int iImageList, Pointer<GUID> riid, Pointer<Pointer> ppv)
    >('SHGetImageList');

// 添加 IImageList_GetIcon 函数定义
final IImageList_GetIcon = comctl32
    .lookupFunction<
      Int32 Function(
        Pointer handle,
        Int32 i,
        Int32 flags,
        Pointer<IntPtr> icon,
      ),
      int Function(Pointer handle, int i, int flags, Pointer<IntPtr> icon)
    >('ImageList_GetIcon');
final ImageList_GetIcon = comctl32
    .lookupFunction<
      IntPtr Function(Pointer himl, Int32 i, Uint32 flags),
      int Function(Pointer himl, int i, int flags)
    >('ImageList_GetIcon');

// 在类外部定义枚举
enum IconSize {
  small, // 16x16
  large, // 32x32
  jumbo, // 256x256
}

class IconService {
  static bool _isInitialized = false;
  static final Map<String, Image> _iconCache = {};

  static Image? getFileIcon(String filePath, {IconSize size = IconSize.small}) {
    // 检查缓存
    final cacheKey = '$filePath-${size.toString()}';
    if (_iconCache.containsKey(cacheKey)) {
      return _iconCache[cacheKey];
    }
    _ensureInitialized();
    final psfi = calloc<SHFILEINFO>();
    final pathPtr = filePath.toNativeUtf16();
    Image? icon;

    try {
      // 获取图标
      icon = size == IconSize.jumbo
          ? _getJumboIcon(pathPtr, psfi)
          : _getNormalIcon(pathPtr, psfi, size);

      // 添加到缓存
      if (icon != null) {
        _iconCache[cacheKey] = icon;
      }

      return icon;
    } finally {
      free(pathPtr);
      free(psfi);
    }
  }

  static void _ensureInitialized() {
    if (!_isInitialized) {
      CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
      _isInitialized = true;
    }
  }

  static void dispose() {
    if (_isInitialized) {
      CoUninitialize();
      _isInitialized = false;
      _iconCache.clear();
    }
  }

  // 将大图标获取逻辑拆分到单独的方法
  static Image? _getJumboIcon(
    Pointer<Utf16> pathPtr,
    Pointer<SHFILEINFO> psfi,
  ) {
    final imageList = calloc<Pointer>();
    final iidImageList = GUIDFromString(IID_IImageList);
    try {
      final hr = SHGetImageList(SHIL_JUMBO, iidImageList, imageList.cast());

      if (FAILED(hr)) {
        free(iidImageList);
        free(imageList);
        return null;
      }

      // 获取文件信息以得到图标索引
      final result = SHGetFileInfo(
        pathPtr,
        0,
        psfi,
        sizeOf<SHFILEINFO>(),
        SHGFI_SYSICONINDEX,
      );

      if (result == 0) {
        free(iidImageList);
        free(imageList);
        return null;
      }

      // 从图像列表中获取图标
      final hIcon = ImageList_GetIcon(
        imageList.value,
        psfi.ref.iIcon,
        ILD_TRANSPARENT,
      );

      if (hIcon == NULL) {
        free(iidImageList);
        free(imageList);
        return null;
      }

      final iconHandle = hIcon;
      free(iidImageList);
      free(imageList);

      final icon = _processIcon(iconHandle);
      if (icon == null) {
        return _getNormalIcon(pathPtr, psfi, IconSize.large);
      }
      return icon;
    } catch (e) {
      free(iidImageList);
      free(imageList);

      return null;
    }
  }

  // 将普通图标获取逻辑拆分到单独的方法
  static Image? _getNormalIcon(
    Pointer<Utf16> pathPtr,
    Pointer<SHFILEINFO> psfi,
    IconSize size,
  ) {
    final result = SHGetFileInfo(
      pathPtr,
      0,
      psfi,
      sizeOf<SHFILEINFO>(),
      SHGFI_ICON | (size == IconSize.small ? SHGFI_SMALLICON : SHGFI_LARGEICON),
    );

    if (result == 0) return null;

    final iconHandle = psfi.ref.hIcon;
    if (iconHandle == NULL) return null;

    return _processIcon(iconHandle);
  }

  // 将图标处理逻辑提取到单独的方法中
  static Image? _processIcon(int iconHandle) {
    // 获取图标信息
    final iconInfo = calloc<ICONINFO>();
    final bmpColor = calloc<BITMAP>();
    Pointer<Uint8>? lpBits;
    Pointer<BITMAPINFOHEADER>? bi;
    int? hdc;
    try {
      if (GetIconInfo(iconHandle, iconInfo) == 0) {
        throw Exception('Failed to get icon info');
      }
      // 创建设备上下文
      hdc = CreateCompatibleDC(NULL);
      if (hdc == NULL) {
        throw Exception('Failed to create DC');
      }
      // 选择位图对象
      final oldBitmap = SelectObject(hdc, iconInfo.ref.hbmColor);
      if (oldBitmap == NULL) {
        throw Exception('Failed to select bitmap');
      }

      // 获取位图信息
      if (GetObject(iconInfo.ref.hbmColor, sizeOf<BITMAP>(), bmpColor) == 0) {
        // SelectObject(hdc, oldBitmap);
        // ReleaseDC(NULL, hdc);
        throw Exception('Failed to get bitmap info');
      }

      final width = bmpColor.ref.bmWidth;
      final height = bmpColor.ref.bmHeight;

      // 创建 BITMAPINFO 结构体
      bi = calloc<BITMAPINFOHEADER>();
      bi.ref.biSize = sizeOf<BITMAPINFOHEADER>();
      bi.ref.biWidth = width;
      bi.ref.biHeight = -height; // 负值表示从上到下的扫描行
      bi.ref.biPlanes = 1;
      bi.ref.biBitCount = 32;
      bi.ref.biCompression = BI_RGB;

      // 分配像素数据缓冲区
      lpBits = calloc<Uint8>(width * height * 4);

      // 获取位图数据
      if (GetDIBits(
            hdc,
            iconInfo.ref.hbmColor,
            0,
            height,
            lpBits.cast(),
            bi.cast(),
            DIB_RGB_COLORS,
          ) ==
          0) {
        throw Exception('Failed to get bitmap bits');
      }

      // 获取位图数据
      final pixels = Uint8List(width * height * 4);
      final srcPixels = lpBits.asTypedList(width * height * 4);
      if (width == 256 && height == 256) {
        // 分析图标的实际内容区域
        int contentLeft = width;
        int contentRight = 0;
        int contentTop = height;
        int contentBottom = 0;

        for (var y = 0; y < height; y++) {
          for (var x = 0; x < width; x++) {
            final i = (y * width + x) * 4;
            // 检查像素是否不透明（alpha > 0）
            if (srcPixels[i + 3] > 0) {
              contentLeft = min(contentLeft, x);
              contentRight = max(contentRight, x);
              contentTop = min(contentTop, y);
              contentBottom = max(contentBottom, y);
            }
          }
        }

        // 计算实际内容区域的大小
        final contentWidth = contentRight - contentLeft + 1;
        final contentHeight = contentBottom - contentTop + 1;

        // 如果实际内容区域明显小于 256x256，说明是小图标被放在大画布中
        if (contentWidth <= 48 && contentHeight <= 48) {
          return null;
        }
      }

      // 转换 BGRA 到 RGBA
      for (var i = 0; i < srcPixels.length; i += 4) {
        pixels[i] = srcPixels[i + 2]; // R = B
        pixels[i + 1] = srcPixels[i + 1]; // G = G
        pixels[i + 2] = srcPixels[i]; // B = R
        pixels[i + 3] = srcPixels[i + 3]; // A = A
      }

      // 创建 Flutter 图像
      var raw = RawImageData(
        pixels,
        width,
        height,
        pixelFormat: PixelFormat.rgba8888,
      );

      return Image(image: RawImageProvider(raw));
    } catch (e) {
      debugPrint('Error processing icon: $e');
      return null;
    } finally {
      // 清理所有资源
      if (lpBits != null) free(lpBits);
      if (bi != null) free(bi);
      free(bmpColor);
      if (iconInfo.ref.hbmColor != NULL) DeleteObject(iconInfo.ref.hbmColor);
      if (iconInfo.ref.hbmMask != NULL) DeleteObject(iconInfo.ref.hbmMask);
      if (hdc != NULL) DeleteDC(hdc!);
      free(iconInfo);
      DestroyIcon(iconHandle);
    }
  }

  // 添加清除缓存的方法
  static void clearCache() {
    _iconCache.clear();
  }
}
