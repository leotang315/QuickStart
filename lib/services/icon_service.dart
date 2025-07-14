import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/widgets.dart';

import '../utls/raw_image_provider.dart';

class IconService {
  static Image? getFileIcon(String filePath, {bool smallIcon = true}) {
    // 分配内存
    final psfi = calloc<SHFILEINFO>();
    final pathPtr = filePath.toNativeUtf16();

    try {
      final result = SHGetFileInfo(
        pathPtr,
        0,
        psfi,
        sizeOf<SHFILEINFO>(),
        SHGFI_ICON | (smallIcon ? SHGFI_SMALLICON : SHGFI_LARGEICON),
      );

      if (result == 0) return null;

      final iconHandle = psfi.ref.hIcon;
      if (iconHandle == NULL) return null;

      // 获取图标信息
      final iconInfo = calloc<ICONINFO>();
      if (GetIconInfo(iconHandle, iconInfo) == 0) {
        free(iconInfo);
        DestroyIcon(iconHandle);
        return null;
      }

      // 创建设备上下文
      final hdc = CreateCompatibleDC(NULL);
      SelectObject(hdc, iconInfo.ref.hbmColor);

      // 获取位图信息
      final bmpColor = calloc<BITMAP>();
      if (GetObject(iconInfo.ref.hbmColor, sizeOf<BITMAP>(), bmpColor) == 0) {
        free(bmpColor);
        DeleteObject(iconInfo.ref.hbmColor);
        DeleteObject(iconInfo.ref.hbmMask);
        free(iconInfo);
        DestroyIcon(iconHandle);
        return null;
      }

      final width = bmpColor.ref.bmWidth;
      final height = bmpColor.ref.bmHeight;

      // 创建 BITMAPINFO 结构体
      final bi = calloc<BITMAPINFOHEADER>();
      bi.ref.biSize = sizeOf<BITMAPINFOHEADER>();
      bi.ref.biWidth = width;
      bi.ref.biHeight = -height; // 负值表示从上到下的扫描行
      bi.ref.biPlanes = 1;
      bi.ref.biBitCount = 32;
      bi.ref.biCompression = BI_RGB;

      // 分配像素数据缓冲区
      final lpBits = calloc<Uint8>(width * height * 4);

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
        ReleaseDC(NULL, hdc);
        free(lpBits);
        free(bi); // 添加这行
        free(bmpColor);
        DeleteObject(iconInfo.ref.hbmColor);
        DeleteObject(iconInfo.ref.hbmMask);
        free(iconInfo);
        DestroyIcon(iconHandle);
        return null;
      }
      // 获取位图数据
      final pixels = lpBits.asTypedList(width * height * 4);

      // 清理资源
      ReleaseDC(NULL, hdc);
      free(lpBits);
      free(bi);
      free(bmpColor);
      DeleteObject(iconInfo.ref.hbmColor);
      DeleteObject(iconInfo.ref.hbmMask);
      free(iconInfo);
      DestroyIcon(iconHandle);

      // 创建 Flutter 图像
      var raw = RawImageData(
        pixels, // 像素数据
        width, // 宽度
        height, // 高度
        pixelFormat: PixelFormat.rgba8888, // 像素
      );

      return Image(image: RawImageProvider(raw));
    } finally {
      free(pathPtr);
      free(psfi);
    }
  }
}
