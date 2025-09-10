# CI/CD 开发指南

本文档详细介绍了 QuickStart 项目的持续集成和持续部署流程，包括开发新特性、版本发布、自动化构建等完整工作流程。

## 目录

- [工作流概览](#工作流概览)
- [开发新特性](#开发新特性)
- [版本发布流程](#版本发布流程)
- [CHANGELOG 编写规范](#changelog-编写规范)
- [自动化构建与发布](#自动化构建与发布)
- [分支保护策略](#分支保护策略)
- [故障排除](#故障排除)

## 工作流概览

### GitHub Actions 工作流

项目使用两个主要的 GitHub Actions 工作流：

#### 1. CI 工作流 (`.github/workflows/ci.yml`)

**触发条件：**
- 推送到任意分支（除标签推送）
- 创建或更新 Pull Request

**执行任务：**
- 代码检出
- Flutter 环境设置 (v3.29.0)
- 依赖包安装 (`flutter pub get`)
- 单元测试执行 (`flutter test`)
- Windows 应用构建 (`flutter build windows --release`)

**运行环境：** Windows Latest

#### 2. Release 工作流 (`.github/workflows/release.yml`)

**触发条件：**
- 推送版本标签 (`v*.*.*` 格式)
- 手动触发 (workflow_dispatch)

**执行任务：**
- 从 CHANGELOG.md 提取版本说明
- 创建 GitHub Release
- 构建 Windows 应用
- 打包并上传发布资产

**运行环境：** Ubuntu (创建发布) + Windows (构建应用)

## 开发新特性

### 1. 创建功能分支

```bash
# 从主分支创建新的功能分支
git checkout main
git pull origin main
git checkout -b feature/your-feature-name
```

### 2. 本地开发环境设置

```bash
# 安装依赖
flutter pub get

# 启用 Windows 桌面支持
flutter config --enable-windows-desktop

# 运行开发版本
flutter run -d windows
```

### 3. 开发过程中的质量检查

#### 代码分析
```bash
# 运行代码分析
flutter analyze

# 格式化代码
flutter format .
```

#### 测试执行
```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/widget_test.dart

# 生成测试覆盖率报告
flutter test --coverage
```

#### 构建验证
```bash
# 构建 Windows 版本
flutter build windows --release

# 构建其他平台（如需要）
flutter build web
flutter build apk
```

### 4. 提交代码

```bash
# 添加更改
git add .

# 提交更改（使用规范的提交信息）
git commit -m "feat: add new feature description"

# 推送到远程分支
git push origin feature/your-feature-name
```

### 5. 创建 Pull Request

1. 在 GitHub 上创建 Pull Request
2. 填写 PR 描述，包括：
   - 功能说明
   - 测试情况
   - 相关 Issue 链接
3. 等待 CI 检查通过
4. 请求代码审查
5. 根据反馈修改代码
6. 合并到主分支

## 版本发布流程

### 1. 准备发布

#### 更新版本号

编辑 `pubspec.yaml` 文件：
```yaml
name: quickstart
description: A Flutter desktop application for quick program launching
version: 1.2.0+3  # 更新版本号
```

版本号格式说明：
- `major.minor.patch+build`
- 例如：`1.2.0+3` 表示版本 1.2.0，构建号 3

#### 更新 CHANGELOG

在 `docs/CHANGELOG.md` 中添加新版本记录（详见 [CHANGELOG 编写规范](#changelog-编写规范)）。

### 2. 自动发布

#### 方式一：标签推送触发

```bash
# 提交版本更新
git add pubspec.yaml docs/CHANGELOG.md
git commit -m "chore: bump version to v1.2.0"
git push origin main

# 创建并推送版本标签
git tag v1.2.0
git push origin v1.2.0
```

#### 方式二：手动触发

1. 进入 GitHub Actions 页面
2. 选择 "Release" 工作流
3. 点击 "Run workflow"
4. 输入版本号（如 `v1.2.0`）
5. 点击 "Run workflow" 执行

### 3. 发布后验证

1. 检查 GitHub Release 页面
2. 验证发布资产是否正确上传
3. 测试下载的安装包
4. 确认自动更新功能正常

## CHANGELOG 编写规范

### 格式标准

遵循 [Keep a Changelog](https://keepachangelog.com/) 标准：

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2024-01-15

### Added
- 新增程序分类功能
- 添加全局热键支持
- 实现自动更新机制

### Changed
- 优化程序启动速度
- 改进用户界面设计
- 更新依赖包版本

### Fixed
- 修复程序图标显示问题
- 解决内存泄漏问题
- 修正多语言切换bug

### Removed
- 移除过时的配置选项

## [1.1.0] - 2024-01-01
...
```

### 变更类型说明

- **Added** - 新增功能
- **Changed** - 功能变更
- **Deprecated** - 即将废弃的功能
- **Removed** - 移除的功能
- **Fixed** - 问题修复
- **Security** - 安全相关修复

### 编写要点

1. **版本格式**：使用 `[x.y.z]` 格式，不包含 `v` 前缀
2. **日期格式**：使用 ISO 8601 格式 (YYYY-MM-DD)
3. **描述清晰**：每个变更都要有清晰的描述
4. **用户视角**：从用户角度描述变更影响
5. **链接引用**：可以包含相关 Issue 或 PR 链接

## 自动化构建与发布

### CI 流程详解

#### 触发机制

```yaml
# ci.yml 触发条件
on:
  push:
    branches: ['**']
    tags-ignore: ['**']
  pull_request:
    branches: ['**']
```

#### 构建步骤

1. **环境准备**
   - 检出代码
   - 设置 Flutter 环境
   - 配置缓存

2. **依赖安装**
   - 执行 `flutter pub get`
   - 验证依赖完整性

3. **质量检查**
   - 运行单元测试
   - 执行代码分析（可选）

4. **应用构建**
   - 构建 Windows 发布版本
   - 验证构建产物

### Release 流程详解

#### 版本信息提取

```bash
# 从标签获取版本号
VERSION=${GITHUB_REF#refs/tags/}
VERSION_NO_V=${VERSION#v}

# 从 CHANGELOG.md 提取版本说明
START_LINE=$(grep -n "^## \[$VERSION_NO_V\]" docs/CHANGELOG.md | cut -d: -f1)
```

#### 发布资产创建

1. **构建应用**
   ```bash
   flutter build windows --release
   ```

2. **打包资产**
   ```bash
   cd build/windows/x64/runner/Release
   7z a -tzip ../../../../../QuickStart-Windows.zip *
   ```

3. **上传到 Release**
   - 自动创建 GitHub Release
   - 上传构建的 ZIP 文件
   - 设置版本说明

### 环境变量配置

```yaml
env:
  FLUTTER_VERSION: '3.29.0'  # Flutter 版本
  
permissions: write-all  # Release 工作流需要写权限
```

## 分支保护策略

### 推荐配置

为确保代码质量，建议在 GitHub 仓库中配置以下分支保护规则：

#### 配置步骤

1. **进入仓库设置**
   - 仓库页面 → Settings → Branches

2. **添加保护规则**
   - 点击 "Add rule"
   - Branch name pattern: `main`

3. **启用保护选项**
   ```
   ✅ Require status checks to pass before merging
   ✅ Require branches to be up to date before merging
   ✅ Require pull request reviews before merging
   ✅ Dismiss stale PR approvals when new commits are pushed
   ✅ Restrict pushes that create files larger than 100MB
   ```

#### 必需状态检查

- `test` - 单元测试必须通过
- `build-windows` - Windows 构建必须成功

#### 保护效果

- ❌ 直接推送到 `main` 分支被阻止
- ✅ 只能通过 Pull Request 合并
- ✅ CI 检查失败时无法合并
- ✅ 需要代码审查通过

## 故障排除

### CI 失败常见问题

#### 1. 测试失败

**症状：** `flutter test` 命令失败

**排查步骤：**
```bash
# 本地运行测试
flutter test

# 查看详细错误信息
flutter test --verbose

# 运行特定测试
flutter test test/widget_test.dart
```

**常见原因：**
- 测试代码错误
- 依赖版本冲突
- 测试环境配置问题

#### 2. 构建失败

**症状：** `flutter build windows` 命令失败

**排查步骤：**
```bash
# 清理构建缓存
flutter clean
flutter pub get

# 重新构建
flutter build windows --verbose

# 检查依赖
flutter doctor
```

**常见原因：**
- Flutter 版本不匹配
- 依赖包版本冲突
- Windows SDK 配置问题

#### 3. 依赖问题

**症状：** `flutter pub get` 失败

**解决方法：**
```bash
# 清理依赖缓存
flutter clean
rm pubspec.lock

# 重新获取依赖
flutter pub get

# 检查依赖冲突
flutter pub deps
```

### Release 失败常见问题

#### 1. 版本未找到

**错误信息：** "Version v1.2.0 not found in docs/CHANGELOG.md"

**解决方法：**
- 确保 CHANGELOG.md 中存在对应版本记录
- 检查版本格式：使用 `[1.2.0]` 而非 `[v1.2.0]`
- 验证文件路径：`docs/CHANGELOG.md`

#### 2. 标签格式错误

**错误信息：** 工作流未触发

**解决方法：**
- 使用正确的标签格式：`v*.*.*`
- 示例：`v1.2.0`、`v2.0.0-beta.1`

#### 3. 权限问题

**错误信息：** "Resource not accessible by integration"

**解决方法：**
- 检查 `permissions: write-all` 配置
- 确认 GitHub Token 权限
- 验证仓库设置中的 Actions 权限

### 调试技巧

#### 1. 本地模拟 CI 环境

```bash
# 使用与 CI 相同的 Flutter 版本
fvm install 3.29.0
fvm use 3.29.0

# 执行 CI 相同的命令序列
flutter pub get
flutter test
flutter build windows --release
```

#### 2. 查看详细日志

- 在 GitHub Actions 页面查看完整日志
- 使用 `--verbose` 参数获取详细输出
- 检查每个步骤的执行时间和状态

#### 3. 增量调试

- 逐步添加构建步骤
- 使用 `echo` 命令输出调试信息
- 临时禁用某些检查来定位问题

## 最佳实践

### 开发流程

1. **小步快跑**：频繁提交小的更改
2. **测试先行**：编写测试用例覆盖新功能
3. **代码审查**：所有代码都要经过审查
4. **文档同步**：及时更新相关文档

### 版本管理

1. **语义化版本**：遵循 SemVer 规范
2. **定期发布**：建立稳定的发布节奏
3. **向后兼容**：谨慎处理破坏性变更
4. **安全更新**：及时修复安全问题

### 质量保证

1. **自动化测试**：保持高测试覆盖率
2. **静态分析**：使用 `flutter analyze` 检查代码
3. **性能监控**：关注应用性能指标
4. **用户反馈**：建立用户反馈收集机制

---

## 相关链接

- [Flutter 官方文档](https://flutter.dev/docs)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [项目 CHANGELOG](./CHANGELOG.md)