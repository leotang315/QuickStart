# QuickStart - 程序快速启动器

一个基于Flutter开发的桌面程序快速启动器，支持程序管理、分类、热键启动等功能。

## 功能特性

- 🚀 **快速启动** - 一键启动常用程序
- 📁 **分类管理** - 自定义程序分类
- 🔍 **智能搜索** - 快速查找程序
- ⌨️ **热键支持** - 全局热键调出

## 系统要求

- Windows 10/11 (x64)

## 安装使用

### Windows安装
1. 下载 `QuickStart-X.X.X-windows-setup.exe`
2. 运行安装程序
3. 按向导完成安装

### 基本使用
- **添加程序**：拖拽程序文件到界面或点击"+"按钮
- **启动程序**：单击程序图标
- **搜索程序**：使用顶部搜索框
- **管理分类**：在侧边栏创建和管理分类

## 开发编译

### 环境要求
- Flutter SDK 3.7.0+
- Dart SDK 3.0.0+
- Visual Studio 2019+ (Windows开发)

### 获取源码
```bash
git clone https://github.com/leotang315/QuickStart.git
cd QuickStart
```

### 安装依赖
```bash
flutter pub get
```

### 运行开发版本
```bash
# Windows平台
flutter run -d windows
```

### 构建发布版本
```bash
# 构建安装包（需要先配置NSIS）
cd installer
build_installer.bat
```

### 项目结构


