# ============================================
# 文件: SwitchJava.psm1
# 这是模块的主文件
# ============================================

# Java Version Switcher for Windows
# Similar to archlinux-java

function Switch-Java {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Action,

        [Parameter(Position = 1)]
        [string]$Version
    )

    # 获取 JAVA_REPOSITORY 环境变量
    $javaRepo = [Environment]::GetEnvironmentVariable("JAVA_REPOSITORY", "User")
    if (-not $javaRepo) {
        $javaRepo = [Environment]::GetEnvironmentVariable("JAVA_REPOSITORY", "Machine")
    }

    if (-not $javaRepo) {
        Write-Error "JAVA_REPOSITORY environment variable is not set."
        Write-Host "Please set JAVA_REPOSITORY to your Java installations directory."
        return
    }

    if (-not (Test-Path $javaRepo)) {
        Write-Error "JAVA_REPOSITORY path does not exist: $javaRepo"
        return
    }

    $defaultLink = Join-Path $javaRepo "default"

    # 显示帮助信息
    function Show-Help {
        Write-Host @"
Usage: Switch-Java [COMMAND] [VERSION]

Commands:
    init                自动配置 JAVA_HOME 和 PATH 环境变量
    status              显示当前激活的 Java 版本
    list                列出所有可用的 Java 版本
    set <VERSION>       设置默认 Java 版本
    unset               取消设置默认版本
    help                显示此帮助信息

Java Repository: $javaRepo
"@
    }

    # 获取所有可用的 Java 版本
    function Get-JavaVersions {
        $versions = @()
        $vendors = Get-ChildItem -Path $javaRepo -Directory | Where-Object { $_.Name -ne "default" }

        foreach ($vendor in $vendors) {
            $versionDirs = Get-ChildItem -Path $vendor.FullName -Directory
            foreach ($ver in $versionDirs) {
                $binPath = Join-Path $ver.FullName "bin"
                $javaExe = Join-Path $binPath "java.exe"

                if (Test-Path $javaExe) {
                    $relativePath = "$($vendor.Name)/$($ver.Name)"
                    $versions += [PSCustomObject]@{
                        Path = $relativePath
                        FullPath = $ver.FullName
                        Vendor = $vendor.Name
                        Version = $ver.Name
                    }
                }
            }
        }
        return $versions
    }

    # 获取当前默认版本
    function Get-CurrentVersion {
        if (Test-Path $defaultLink) {
            $target = (Get-Item $defaultLink).Target
            if ($target) {
                # 提取相对路径并统一使用正斜杠
                $relativePath = $target -replace [regex]::Escape($javaRepo), "" -replace "^[\\/]+", ""
                $relativePath = $relativePath -replace "\\", "/"
                return $relativePath
            }
        }
        return $null
    }

    # 显示当前状态
    function Show-Status {
        $current = Get-CurrentVersion
        if ($current) {
            Write-Host "Current Java version: " -NoNewline
            Write-Host $current -ForegroundColor Green

            $defaultPath = Join-Path $defaultLink "bin\java.exe"
            if (Test-Path $defaultPath) {
                $javaVersion = & $defaultPath -version 2>&1
                Write-Host "`nVersion details:"
                $javaVersion | Select-Object -First 3 | ForEach-Object { Write-Host "  $_" }
            }
        } else {
            Write-Host "No default Java version set." -ForegroundColor Yellow
        }
    }

    # 列出所有版本
    function Show-List {
        $versions = Get-JavaVersions
        $current = Get-CurrentVersion

        if ($versions.Count -eq 0) {
            Write-Host "No Java installations found in $javaRepo" -ForegroundColor Yellow
            return
        }

        Write-Host "Available Java versions:" -ForegroundColor Cyan
        Write-Host ("=" * 50)

        foreach ($v in $versions) {
            # 标准化比较：统一使用正斜杠
            $vPathNormalized = $v.Path -replace "\\", "/"
            $currentNormalized = $current -replace "\\", "/"

            $marker = if ($vPathNormalized -eq $currentNormalized) { " (default)" } else { "" }
            $color = if ($vPathNormalized -eq $currentNormalized) { "Green" } else { "White" }
            Write-Host "  $($v.Path)$marker" -ForegroundColor $color
        }
    }

    # 设置默认版本
    function Set-JavaVersion {
        param([string]$TargetVersion)

        $versions = Get-JavaVersions
        $target = $versions | Where-Object { $_.Path -eq $TargetVersion }

        if (-not $target) {
            Write-Error "Java version '$TargetVersion' not found."
            Write-Host "`nAvailable versions:"
            $versions | ForEach-Object { Write-Host "  $($_.Path)" }
            return
        }

        # 检查 bin 目录和 java.exe
        $binPath = Join-Path $target.FullPath "bin"
        $javaExe = Join-Path $binPath "java.exe"

        if (-not (Test-Path $javaExe)) {
            Write-Error "Invalid Java installation: $javaExe not found"
            return
        }

        # 删除旧的符号链接
        if (Test-Path $defaultLink) {
            Remove-Item $defaultLink -Force -Recurse -ErrorAction SilentlyContinue
        }

        # 创建新的符号链接（需要管理员权限）
        try {
            New-Item -ItemType SymbolicLink -Path $defaultLink -Target $target.FullPath -Force | Out-Null
            Write-Host "Successfully set default Java to: " -NoNewline
            Write-Host $TargetVersion -ForegroundColor Green

            # 提示更新 PATH
            Write-Host "`nMake sure your PATH includes: " -ForegroundColor Yellow
            Write-Host "  %JAVA_REPOSITORY%\default\bin" -ForegroundColor Cyan
            Write-Host "or" -ForegroundColor Yellow
            Write-Host "  $defaultLink\bin" -ForegroundColor Cyan
        }
        catch {
            Write-Error "Failed to create symbolic link. Please run PowerShell as Administrator."
            Write-Error $_.Exception.Message
        }
    }

    # 取消设置
    function Remove-JavaVersion {
        if (Test-Path $defaultLink) {
            Remove-Item $defaultLink -Force -Recurse
            Write-Host "Default Java version unset." -ForegroundColor Green
        } else {
            Write-Host "No default Java version is currently set." -ForegroundColor Yellow
        }
    }

    # 初始化环境变量配置
    function Initialize-JavaEnvironment {
        Write-Host "`n=== Initializing Java Environment ===" -ForegroundColor Cyan

        # 检查是否有管理员权限
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        if (-not $isAdmin) {
            Write-Warning "Administrator privileges are recommended for system-wide configuration."
            Write-Host "Current session will configure user-level environment variables only."
            Write-Host ""
        }

        # 选择配置级别
        $scope = "User"
        if ($isAdmin) {
            Write-Host "Select configuration scope:"
            Write-Host "  [1] User (current user only)"
            Write-Host "  [2] Machine (all users - recommended)"
            $choice = Read-Host "Enter choice (1/2)"

            if ($choice -eq "2") {
                $scope = "Machine"
            }
        }

        Write-Host "`nConfiguration scope: $scope" -ForegroundColor Yellow
        Write-Host ""

        # 配置 JAVA_HOME
        $javaHome = Join-Path $javaRepo "default"
        $currentJavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", $scope)

        Write-Host "Configuring JAVA_HOME..." -ForegroundColor Cyan
        if ($currentJavaHome) {
            Write-Host "  Current: $currentJavaHome" -ForegroundColor Gray
        }
        Write-Host "  New:     $javaHome" -ForegroundColor Green

        try {
            [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, $scope)
            Write-Host "  ✓ JAVA_HOME configured successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "  ✗ Failed to set JAVA_HOME: $($_.Exception.Message)"
            return
        }

        # 配置 PATH
        Write-Host "`nConfiguring PATH..." -ForegroundColor Cyan
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", $scope)

        # 检查是否已存在
        $pathEntries = $currentPath -split ";" | Where-Object { $_ }
        $needsUpdate = $true

        # 检查是否已经包含 default\bin 或 %JAVA_HOME%\bin
        foreach ($entry in $pathEntries) {
            if ($entry -like "*default\bin*" -or $entry -like "*%JAVA_HOME%\bin*") {
                Write-Host "  PATH already contains Java bin directory: $entry" -ForegroundColor Yellow
                $needsUpdate = $false
                break
            }
        }

        if ($needsUpdate) {
            # 添加 %JAVA_HOME%\bin 到 PATH 开头
            $newPath = "%JAVA_HOME%\bin;$currentPath"

            try {
                [Environment]::SetEnvironmentVariable("PATH", $newPath, $scope)
                Write-Host "  ✓ Added %JAVA_HOME%\bin to PATH" -ForegroundColor Green
            }
            catch {
                Write-Error "  ✗ Failed to update PATH: $($_.Exception.Message)"
                return
            }
        } else {
            Write-Host "  ✓ PATH already configured" -ForegroundColor Green
        }

        # 清理旧的 Java 路径（可选）
        Write-Host "`nCleaning up old Java paths..." -ForegroundColor Cyan
        $oldJavaPaths = $pathEntries | Where-Object {
            $_ -match "java|jdk|jre" -and
            $_ -notlike "*%JAVA_HOME%*" -and
            $_ -notlike "*default\bin*"
        }

        if ($oldJavaPaths) {
            Write-Host "  Found old Java paths in PATH:" -ForegroundColor Yellow
            $oldJavaPaths | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }

            $cleanup = Read-Host "`n  Remove these paths? (y/n)"
            if ($cleanup -eq "y") {
                $cleanedPath = ($pathEntries | Where-Object {
                    $_ -notmatch "java|jdk|jre" -or
                    $_ -like "*%JAVA_HOME%*" -or
                    $_ -like "*default\bin*"
                }) -join ";"

                try {
                    [Environment]::SetEnvironmentVariable("PATH", $cleanedPath, $scope)
                    Write-Host "  ✓ Old Java paths removed" -ForegroundColor Green
                }
                catch {
                    Write-Warning "  ✗ Failed to clean up PATH: $($_.Exception.Message)"
                }
            }
        } else {
            Write-Host "  ✓ No old Java paths found" -ForegroundColor Green
        }

        # 显示摘要
        Write-Host "`n=== Configuration Summary ===" -ForegroundColor Cyan
        Write-Host "Scope:        $scope"
        Write-Host "JAVA_HOME:    $javaHome"
        Write-Host "PATH Entry:   %JAVA_HOME%\bin"

        # 检查当前是否有默认版本
        $current = Get-CurrentVersion
        if ($current) {
            Write-Host "Current Java: " -NoNewline
            Write-Host $current -ForegroundColor Green
        } else {
            Write-Host "`nNote: " -NoNewline -ForegroundColor Yellow
            Write-Host "No default Java version set. Use 'Switch-Java set <VERSION>' to set one."
        }

        Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
        Write-Host "1. Restart your terminal or run: " -NoNewline
        Write-Host "refreshenv" -ForegroundColor Yellow
        Write-Host "2. Set a default Java version: " -NoNewline
        Write-Host "Switch-Java set <VERSION>" -ForegroundColor Yellow
        Write-Host "3. Verify installation: " -NoNewline
        Write-Host "java -version" -ForegroundColor Yellow
        Write-Host ""
    }

    # 主逻辑
    switch ($Action.ToLower()) {
        "init" { Initialize-JavaEnvironment }
        "status" { Show-Status }
        "list" { Show-List }
        "set" {
            if (-not $Version) {
                Write-Error "Please specify a Java version."
                Write-Host "Usage: Switch-Java set <VERSION>"
                Write-Host "Example: Switch-Java set Corretto/11"
            } else {
                Set-JavaVersion -TargetVersion $Version
            }
        }
        "unset" { Remove-JavaVersion }
        "help" { Show-Help }
        "" { Show-Help }
        default {
            Write-Error "Unknown command: $Action"
            Show-Help
        }
    }
}

Export-ModuleMember -Function Switch-Java