# SwitchJava

一个 PowerShell 模块，用于在 Windows 上管理和切换多个 Java 版本，类似于 Linux 上的 `archlinux-java`。

## 功能特性

- 🔄 **轻松切换** Java 版本
- 📋 **列出所有** 已安装的 Java 版本
- ✅ **查看状态** 当前激活的 Java 版本
- 🛠️ **自动配置** JAVA_HOME 和 PATH 环境变量
- 🔗 **符号链接管理** 自动创建和管理 Java 版本链接
- 🌍 **支持多个供应商** 在同一 repository 中管理不同供应商的 Java

## 系统要求

- Windows 7 及更高版本
- PowerShell 5.1 或更高版本
- 管理员权限（用于创建符号链接和配置环境变量）

## 安装

### 方法 1：复制到 PowerShell 模块目录

```powershell
$modulePath = "$PROFILE\..\Modules\SwitchJava"
mkdir $modulePath -Force
Copy-Item -Path "SwitchJava.psd1", "SwitchJava.psm1" -Destination $modulePath
```

### 方法 2：直接复制到特定位置

将 `SwitchJava.psd1` 和 `SwitchJava.psm1` 复制到以下任一位置：

- `$PROFILE\..\Modules\SwitchJava\`
- `$env:ProgramFiles\PowerShell\Modules\SwitchJava\`
- 你的自定义 PSModulePath 目录

## 初始设置

### 1. 创建 Java Repository 目录结构

```text
JAVA_REPOSITORY/
├── Oracle/
│   ├── 11
│   ├── 17
│   └── 21
├── OpenJDK/
│   ├── 11
│   └── 17
└── default/  (符号链接，由模块创建)
```

### 2. 设置环境变量

设置 `JAVA_REPOSITORY` 环境变量，指向你的 Java 安装目录：

```powershell
# 方式一：通过 PowerShell（用户级别）
[Environment]::SetEnvironmentVariable("JAVA_REPOSITORY", "D:\Java", "User")

# 方式二：通过 PowerShell（系统级别，需要管理员权限）
[Environment]::SetEnvironmentVariable("JAVA_REPOSITORY", "D:\Java", "Machine")

# 方式三：通过环境变量对话框（图形界面）
# 编辑系统环境变量 → 新建 JAVA_REPOSITORY
```

### 3. 初始化模块

```powershell
Import-Module SwitchJava
Switch-Java init
```

这将帮助你自动配置 JAVA_HOME 和 PATH 环境变量。

## 使用方法

### 导入模块

```powershell
Import-Module SwitchJava
```

### 显示帮助

```powershell
Switch-Java help
```

### 列出所有可用的 Java 版本

```powershell
Switch-Java list
```

输出示例：

```text
Available Java versions:
==================================================
  OpenJDK/11 (default)
  OpenJDK/17
  OpenJDK/21
```

### 查看当前状态

```powershell
Switch-Java status
```

输出示例：

```text
Current Java version: OpenJDK/11

Version details:
  openjdk version "11.0.17" 2022-10-18
  OpenJDK Runtime Environment (build 11.0.17+8-post-Ubuntu-0ubuntu120.04)
  OpenJDK 64-Bit Server VM (build 11.0.17+8-post-Ubuntu-0ubuntu120.04, mixed mode, sharing)
```

### 切换 Java 版本

```powershell
# 切换到 OpenJDK 17
Switch-Java set OpenJDK/17

# 切换到 OpenJDK 21
Switch-Java set OpenJDK/21
```

### 取消设置默认版本

```powershell
Switch-Java unset
```

这将移除 `default` 符号链接，但不会删除任何 Java 安装。

## 命令参考

| 命令                         | 描述                     |
| --------------------------- | ----------------------- |
| `Switch-Java init`          | 初始化 Java 环境变量配置 |
| `Switch-Java status`        | 显示当前激活的 Java 版本 |
| `Switch-Java list`          | 列出所有可用的 Java 版本 |
| `Switch-Java set <VERSION>` | 设置指定版本为默认版本    |
| `Switch-Java unset`         | 取消设置默认版本         |
| `Switch-Java help`          | 显示帮助信息            |

## 目录结构要求

每个 Java 安装目录必须包含 `bin\java.exe`：

```text
JAVA_REPOSITORY/
└── <VENDOR>/
    └── <VERSION>/
        ├── bin/
        │   ├── java.exe
        │   ├── javac.exe
        │   └── ...
        ├── lib/
        ├── conf/
        └── ...
```

## 环境变量配置

模块会自动配置以下环境变量：

- **JAVA_HOME**: 指向当前选择的 Java 版本（通过 default 符号链接）
- **PATH**: 添加 `%JAVA_REPOSITORY%\default\bin`

## 常见问题

### Q: 需要管理员权限吗？

A: 是的。创建符号链接和配置系统级环境变量都需要管理员权限。请以管理员身份运行 PowerShell。

### Q: 可以同时安装多个 Java 版本吗？

A: 可以。模块支持同时管理多个 Java 版本，并通过符号链接在它们之间快速切换。

### Q: 如何验证切换是否成功？

A: 运行以下命令验证：

```powershell
java -version
javac -version
$env:JAVA_HOME
```

### Q: JAVA_REPOSITORY 未找到怎么办？

A: 确保你已经设置了 `JAVA_REPOSITORY` 环境变量，并重新启动 PowerShell 使其生效。

### Q: 如何导出为 Profile 自动加载？

A: 编辑你的 PowerShell profile：

```powershell
notepad $PROFILE
```

添加以下行：

```powershell
Import-Module SwitchJava
```

保存并重启 PowerShell。

## 版本历史

- **v1.0.0** - 初始版本
  - 基础的 Java 版本切换功能
  - 支持多供应商管理
  - 自动环境变量配置

## 许可证

本项目采用 GPLv3 许可证。详见 [LICENSE](https://github.com/FuyukiVila/SwitchJava/blob/main/LICENSE)。

## 作者

- **Fuyuki_Vila**

## 相关链接

- [GitHub 仓库](https://github.com/FuyukiVila/SwitchJava)
- [PowerShell 官方文档](https://docs.microsoft.com/en-us/powershell/)

## 贡献

欢迎提交 Issue 和 Pull Request！

## 致谢

灵感来自 Linux 上的 `archlinux-java` 工具。

---

**最后更新**: 2025 年 10 月 24 日
