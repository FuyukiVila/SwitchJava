# ============================================
# 文件: SwitchJava.psd1
# PowerShell 模块清单文件
# ============================================

@{
    # 模块版本号
    ModuleVersion     = '1.0.0'

    # 支持的 PowerShell 版本
    PowerShellVersion = '5.1'

    # 模块的唯一标识符 (GUID)
    GUID              = 'A5B73EF9-6023-6BD8-D0CD-02F90B53F41D'

    # 作者
    Author            = 'Fuyuki_Vila'

    # 版权声明
    Copyright         = '(c) 2025 Fuyuki_Vila. All rights reserved.'

    # 模块描述
    Description       = 'Java version switcher for Windows, similar to archlinux-java. Manages multiple Java installations and switches between them easily.'

    # 根模块文件
    RootModule        = 'SwitchJava.psm1'

    # 要导出的函数
    FunctionsToExport = @('Switch-Java')

    # 要导出的 Cmdlet
    CmdletsToExport   = @()

    # 要导出的变量
    VariablesToExport = @()

    # 要导出的别名
    AliasesToExport   = @()

    # 私有数据
    PrivateData       = @{
        PSData = @{
            # 标签，用于模块发现
            Tags         = @('Java', 'JDK', 'Version', 'Switcher', 'Environment', 'Development')

            # 许可证 URI
            LicenseUri = 'https://github.com/FuyukiVila/SwitchJava/blob/main/LICENSE'

            # 项目 URI
            ProjectUri = 'https://github.com/FuyukiVila/SwitchJava'

            # 图标 URI
            # IconUri = ''

            # 发行说明
            ReleaseNotes = @'
1.0.0
- Initial release
- Support for multiple Java vendors (Oracle, Adoptium, Corretto, etc.)
- Switch between Java versions using symbolic links
- Auto-configure JAVA_HOME and PATH
- List and status commands
'@
        }
    }
}