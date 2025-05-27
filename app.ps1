# Author: Joey
# Blog: joeyblog.net
# Feedback TG (反馈TG): https://t.me/+ft-zI76oovgwNmRh
# Core Functionality By (核心功能实现):
#   - https://github.com/eooce
#   - https://github.com/qwer-search
# Version: PS-2.4.8 (Added panel URL opening with https default)

Write-Host ""
Write-Host "欢迎使用 Webhostmost-ws-nodejs 配置脚本 (PowerShell 版本)!" -ForegroundColor Magenta
Write-Host "此脚本由 Joey (joeyblog.net) 提供，用于简化配置流程。" -ForegroundColor Magenta
Write-Host "核心功能基于 eooce 和 qwer-search 的工作。" -ForegroundColor Magenta
Write-Host "如果您对此脚本有任何反馈，请通过 Telegram 联系: https://t.me/+ft-zI76oovgwNmRh" -ForegroundColor Magenta
Write-Host "--------------------------------------------------------------------------" -ForegroundColor Magenta

Write-Host "==================== Webhostmost-ws-nodejs 配置生成脚本 ====================" -ForegroundColor Green

# --- 全局变量 ---
$currentPath = Get-Location
$appJsFileName = "app.js"
$packageJsonFileName = "package.json"
$appJsPath = Join-Path -Path $currentPath.Path -ChildPath $appJsFileName # Ensure .Path is used for currentPath if it's a PathInfo object
$packageJsonPath = Join-Path -Path $currentPath.Path -ChildPath $packageJsonFileName

$appJsUrl = "https://raw.githubusercontent.com/byJoey/Webhostmost-ws-nodejs/refs/heads/main/app.js"
$packageJsonUrl = "https://raw.githubusercontent.com/qwer-search/Webhostmost-ws-nodejs/main/package.json"

$Global:serverPanelUrlConfigured = "" # 新增全局变量

# --- 函数定义 ---

function Invoke-ServerPanelUrlPrompt {
    Write-Host "`n--- 准备打开服务器 Node.js 管理面板 ---" -ForegroundColor Yellow
    $panelUrlInput = ""
    while ([string]::IsNullOrEmpty($panelUrlInput)) {
        $panelUrlInput = Read-Host "请输入您的服务器面板的URL (例如: server7.webhostmost.com)"
        if ([string]::IsNullOrEmpty($panelUrlInput)) {
            Write-Host "服务器面板URL不能为空，请重新输入。" -ForegroundColor Yellow
        }
    }

    # 简单移除末尾的斜杠
    $panelUrlInput = $panelUrlInput.TrimEnd('/')

    # 检查并添加协议头
    if (-not ($panelUrlInput -match "://")) {
        Write-Host "检测到输入的URL缺少协议头 (例如 http:// 或 https://)，将默认使用 https://" -ForegroundColor Yellow
        $panelUrlInput = "https://$panelUrlInput"
    }

    $Global:serverPanelUrlConfigured = $panelUrlInput
    Write-Host "服务器面板基础URL已记录: $Global:serverPanelUrlConfigured" -ForegroundColor Cyan
}

function Download-File($url, $outputPath, $fileName) {
    Write-Host "正在下载 $fileName (来自 $url)..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $outputPath -ErrorAction Stop
        Write-Host "$fileName 下载成功。" -ForegroundColor Green
    }
    catch {
        Write-Error "下载 $fileName 失败: $($_.Exception.Message)"
        Write-Error "请检查网络连接或 URL 是否正确: $url"
        throw # Re-throw the exception to be caught by the main try-catch block if necessary
    }
}

function Update-AppJsConfig($filePath, $configName, $configValue, $regexPattern, $replacementFormat) {
    try {
        if (-not (Test-Path $filePath -PathType Leaf)) {
            Write-Error "错误: app.js 文件未找到于路径 '$filePath'。无法修改 '$configName'。"
            throw "app.js not found at $filePath"
        }
        # Read with UTF8, write back with UTF8
        $content = Get-Content $filePath -Raw -Encoding UTF8
        
        # For PowerShell's -replace, the replacement string uses $1, $2 for backreferences.
        # The $replacementFormat should be like '${1}{0}${3}' where {0} is for the new value.
        # Regex::Escape is good for the $configValue if it's used directly in a regex,
        # but here it's part of the replacement string, so standard string escaping rules apply.
        # However, if $configValue could contain '$' characters, they might be misinterpreted in replacement.
        # A safer way for replacement string is to escape $ or use -f format operator.
        # For simplicity, if $configValue is simple, direct injection into format string is often fine.
        # Let's assume $configValue doesn't contain problematic chars for replacement string context or that they are handled by caller.
        # Using single quotes for $replacementFormat ensures $1 etc. are literals until -replace.
        $newReplacementString = $replacementFormat -replace '\{0\}', $configValue 

        $newContent = $content -replace $regexPattern, $newReplacementString
        
        if ($content -eq $newContent) {
            Write-Warning "警告: 配置项 '$configName' 在 app.js 中未找到匹配的模式或值未改变 (正则表达式: $regexPattern)。请检查 app.js 文件内容和脚本中的正则表达式。"
        } else {
            # Ensure to write back using UTF8, -NoNewline might be desired if original was without.
            # Get-Content -Raw preserves original newlines, so -NoNewline prevents an *extra* one from Set-Content.
            Set-Content -Path $filePath -Value $newContent -Encoding UTF8 -NoNewline
            Write-Host "app.js 中的 '$configName' 已更新为 '$configValue'。" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "修改 app.js 中的 '$configName' 失败: $($_.Exception.Message)"
        throw
    }
}

function Invoke-BasicConfiguration {
    Write-Host "`n--- 正在配置基本部署参数 (UUID, Domain, Port, Subscription Path) ---" -ForegroundColor Yellow

    $domain = ""
    while ([string]::IsNullOrEmpty($domain)) {
        $domain = Read-Host "请输入您的域名（例如：yourdomain.freewebhostmost.com）"
        if ([string]::IsNullOrEmpty($domain)) {
            Write-Host "域名不能为空，请重新输入。" -ForegroundColor Yellow
        }
    }

    $uuid = Read-Host "请输入 UUID（留空则自动生成）"
    if ([string]::IsNullOrEmpty($uuid)) {
        $uuid = [guid]::NewGuid().ToString()
        Write-Host "已自动生成 UUID: $uuid" -ForegroundColor Cyan
    }

    $vl_port_str = Read-Host "请输入 app.js 的 HTTP 服务器监听端口（留空则随机生成 10000-65535）"
    $vl_port = 0
    if ([string]::IsNullOrEmpty($vl_port_str)) {
        $vl_port = Get-Random -Minimum 10000 -Maximum 65535
        Write-Host "已自动生成端口号: $vl_port" -ForegroundColor Cyan
    } elseif ($vl_port_str -notmatch "^\d+$" -or [int]$vl_port_str -lt 1 -or [int]$vl_port_str -gt 65535) {
        Write-Host "输入的端口号无效，将自动生成一个端口号。" -ForegroundColor Yellow
        $vl_port = Get-Random -Minimum 10000 -Maximum 65535
        Write-Host "已自动生成端口号: $vl_port" -ForegroundColor Cyan
    } else {
        $vl_port = [int]$vl_port_str
    }

    $subscriptionPathInput = Read-Host "请输入自定义订阅路径 (例如 sub, mypath。留空则自动生成，不要以 / 开头)"
    $subscriptionPath = ""
    if ([string]::IsNullOrEmpty($subscriptionPathInput)) {
        $randomPathName = -join ((Get-Random -Count 8 -InputObject (48..57 + 97..122) | ForEach-Object {[char]$_})) # Generates a-z0-9
        $subscriptionPath = "/" + $randomPathName
        Write-Host "已自动生成订阅路径: $subscriptionPath" -ForegroundColor Cyan
    } else {
        $cleanedPath = $subscriptionPathInput.TrimStart('/').TrimEnd('/')
        if ([string]::IsNullOrEmpty($cleanedPath)) {
            $randomPathName = -join ((Get-Random -Count 8 -InputObject (48..57 + 97..122) | ForEach-Object {[char]$_}))
            $subscriptionPath = "/" + $randomPathName
            Write-Host "输入的路径无效，已自动生成订阅路径: $subscriptionPath" -ForegroundColor Cyan
        } else {
            $subscriptionPath = "/" + $cleanedPath
        }
    }
    Write-Host "最终订阅路径将是: $subscriptionPath" -ForegroundColor Cyan
    
    Write-Host "正在修改 app.js 中的基本参数..."
    Update-AppJsConfig -filePath $appJsPath -configName "UUID" -configValue $uuid -regexPattern "(const\s+UUID\s*=\s*process\.env\.UUID\s*\|\|\s*')([^']*)(';)" -replacementFormat '${1}{0}${3}'
    Update-AppJsConfig -filePath $appJsPath -configName "DOMAIN" -configValue $domain -regexPattern "(const\s+DOMAIN\s*=\s*process\.env\.DOMAIN\s*\|\|\s*')([^']*)(';)" -replacementFormat '${1}{0}${3}'
    Update-AppJsConfig -filePath $appJsPath -configName "PORT" -configValue $vl_port.ToString() -regexPattern "(const\s+port\s*=\s*process\.env\.PORT\s*\|\|\s*)(\d*)(\s*;)" -replacementFormat '${1}{0}${3}'
    
    # Note: For Subscription URL Path, the path value itself might contain characters that are special in regex replacement if not careful.
    # However, {0} in PowerShell format string is a direct substitution.
    # The original regex `(\/[^']+?)` is non-greedy. In PowerShell, make sure it behaves as expected or adjust.
    # PowerShell's default regex is greedy. For non-greedy, use `*?` or `+?`. The `+?` is fine here.
    Update-AppJsConfig -filePath $appJsPath -configName "Subscription URL Path" -configValue $subscriptionPath `
        -regexPattern "(else\s+if\s*\(\s*req\.url\s*===\s*')(\/[^']+?)(')" `
        -replacementFormat '${1}{0}${3}' # $1 = prefix, {0} = new path, $3 = suffix
    
    return @{Domain = $domain; UUID = $uuid; Port = $vl_port; SubscriptionPath = $subscriptionPath}
}

function Invoke-NezhaConfiguration {
    Write-Host "`n--- 正在配置 Nezha 监控参数 ---" -ForegroundColor Yellow

    $nezhaServer = ""
    while ([string]::IsNullOrEmpty($nezhaServer)) {
        $nezhaServer = Read-Host "请输入 NEZHA_SERVER (例如：nezha.yourdomain.com)"
         if ([string]::IsNullOrEmpty($nezhaServer)) {
            Write-Host "NEZHA_SERVER 不能为空，请重新输入。" -ForegroundColor Yellow
        }
    }

    $nezhaPort = ""
    while ([string]::IsNullOrEmpty($nezhaPort) -or $nezhaPort -notmatch "^\d+$") {
        $nezhaPort = Read-Host "请输入 NEZHA_PORT (例如：443 或 5555)"
        if ([string]::IsNullOrEmpty($nezhaPort) -or $nezhaPort -notmatch "^\d+$") {
            Write-Host "NEZHA_PORT 不能为空且必须为数字，请重新输入。" -ForegroundColor Yellow
        }
    }

    $nezhaKey = Read-Host "请输入 NEZHA_KEY (哪吒面板密钥，可留空)"
    if ([string]::IsNullOrEmpty($nezhaKey)) {
        Write-Host "提示: NEZHA_KEY 为空。" -ForegroundColor Magenta
    }
    
    Write-Host "正在修改 app.js 中的 Nezha 参数..."
    Update-AppJsConfig -filePath $appJsPath -configName "NEZHA_SERVER" -configValue $nezhaServer -regexPattern "(const\s+NEZHA_SERVER\s*=\s*process\.env\.NEZHA_SERVER\s*\|\|\s*')([^']*)(';)" -replacementFormat '${1}{0}${3}'
    Update-AppJsConfig -filePath $appJsPath -configName "NEZHA_PORT" -configValue $nezhaPort -regexPattern "(const\s+NEZHA_PORT\s*=\s*process\.env\.NEZHA_PORT\s*\|\|\s*')([^']*)(';)" -replacementFormat '${1}{0}${3}'
    Update-AppJsConfig -filePath $appJsPath -configName "NEZHA_KEY" -configValue $nezhaKey -regexPattern "(const\s+NEZHA_KEY\s*=\s*process\.env\.NEZHA_KEY\s*\|\|\s*')([^']*)(';)" -replacementFormat '${1}{0}${3}'

    return @{NezhaServer = $nezhaServer; NezhaPort = $nezhaPort; NezhaKey = $nezhaKey}
}

# --- 主程序逻辑 ---
$basicConfigPerformed = $false
$nezhaConfigPerformed = $false
$basicConfigDetails = $null
$nezhaConfigDetails = $null
$errorOccurredDuringSetup = $false

Invoke-ServerPanelUrlPrompt # 调用新函数

try {
    Write-Host "`n准备配置文件..." -ForegroundColor Yellow
    Download-File -url $appJsUrl -outputPath $appJsPath -fileName $appJsFileName
    Download-File -url $packageJsonUrl -outputPath $packageJsonPath -fileName $packageJsonFileName

    $basicConfigDetails = Invoke-BasicConfiguration
    if ($null -ne $basicConfigDetails) {
        $basicConfigPerformed = $true
        Write-Host "`n==================== 基本配置完成 ====================" -ForegroundColor Green
        Write-Host "域名 (Domain)： $($basicConfigDetails.Domain)" -ForegroundColor Cyan
        Write-Host "UUID： $($basicConfigDetails.UUID)" -ForegroundColor Cyan
        Write-Host "app.js 监听端口 (Port)： $($basicConfigDetails.Port)" -ForegroundColor Cyan
        Write-Host "订阅路径 (Subscription Path): $($basicConfigDetails.SubscriptionPath)" -ForegroundColor Cyan
        $subLink = "https://$($basicConfigDetails.Domain)$($basicConfigDetails.SubscriptionPath)"
        Write-Host "节点分享链接 (VLESS Subscription Link)：$subLink" -ForegroundColor Cyan
        Write-Host "--------------------------------------------------------" -ForegroundColor Green
    } else {
      $errorOccurredDuringSetup = $true # Basic config failed
    }

    if ($basicConfigPerformed) {
        $configureNezhaChoice = Read-Host "是否要继续配置 Nezha 监控参数? (Y/N)"
        if ($configureNezhaChoice -match '^[Yy]$') {
            $nezhaConfigDetails = Invoke-NezhaConfiguration
            if ($null -ne $nezhaConfigDetails) {
                $nezhaConfigPerformed = $true
                Write-Host "`n==================== Nezha 配置完成 ====================" -ForegroundColor Green
                Write-Host "NEZHA_SERVER： $($nezhaConfigDetails.NezhaServer)" -ForegroundColor Cyan
                Write-Host "NEZHA_PORT： $($nezhaConfigDetails.NezhaPort)" -ForegroundColor Cyan
                Write-Host "NEZHA_KEY： $($nezhaConfigDetails.NezhaKey)" -ForegroundColor Cyan
                Write-Host "Nezha 参数已配置到 app.js。" -ForegroundColor Green
                Write-Host "--------------------------------------------------------" -ForegroundColor Green
            } else {
                 # Nezha config failed, but basic might be okay. Not setting $errorOccurredDuringSetup = $true here
                 Write-Error "Nezha 配置未成功完成。"
            }
        } else {
            Write-Host "跳过 Nezha 监控参数配置。" -ForegroundColor Yellow
        }
    }
}
catch {
    # This catches errors from Download-File or if functions explicitly throw.
    Write-Error "在配置过程中发生严重错误: $($_.Exception.Message)"
    Write-Host "操作已中止。" -ForegroundColor Red
    $errorOccurredDuringSetup = $true
}

# --- 总结与提示 ---
if ($basicConfigPerformed -or $nezhaConfigPerformed) {
    Write-Host "`n==================== 所有配置操作完成 ====================" -ForegroundColor Green
    Write-Host "配置文件已保存至当前目录：$($currentPath.Path)" -ForegroundColor Cyan
    
    if ($basicConfigPerformed -and $null -ne $basicConfigDetails.Domain) {
        Write-Host "您需要手动将以下文件上传到您的 Webhostmost 主机，建议的上传路径为：" -ForegroundColor Yellow
        Write-Host "  domains/$($basicConfigDetails.Domain)/public_html" -ForegroundColor Cyan
        Write-Host "请将以下文件上传到上述路径：" -ForegroundColor Yellow
    } else {
        Write-Host "您需要手动将以下文件上传到您的 Webhostmost 主机的网站根目录 (例如 public_html)：" -ForegroundColor Yellow
    }
    Write-Host "  - $appJsFileName"
    Write-Host "  - $packageJsonFileName"
    Write-Host "--------------------------------------------------------" -ForegroundColor Green
    if ($basicConfigPerformed) {
        Write-Host "已配置基本参数。" -ForegroundColor Green
        if ($null -ne $basicConfigDetails.SubscriptionPath) {
            Write-Host "自定义/自动生成的订阅路径为: $($basicConfigDetails.SubscriptionPath)" -ForegroundColor Green
        }
    }
    if ($nezhaConfigPerformed) {
        Write-Host "已配置 Nezha 监控参数。" -ForegroundColor Green
    }
    Write-Host "--------------------------------------------------------" -ForegroundColor Green
    Write-Host "重要提示: 如果修改后的 $appJsFileName 文件在文本编辑器中出现乱码，" -ForegroundColor Yellow
    Write-Host "请确保您的文本编辑器使用 UTF-8 编码来打开和查看该文件。" -ForegroundColor Yellow

} elseif ($errorOccurredDuringSetup) { # Check our custom flag
    Write-Host "`n由于发生错误，配置未全部完成。" -ForegroundColor Red
} else {
    # This case might be hit if no configurations were attempted or if a non-terminating error occurred that wasn't caught by main try-catch
    Write-Host "`n未进行任何有效配置，或配置未成功。" -ForegroundColor Yellow
}

Write-Host "`n==================== 脚本操作结束 ====================" -ForegroundColor Green

# --- 尝试打开浏览器 ---
if (-not [string]::IsNullOrEmpty($Global:serverPanelUrlConfigured)) {
    $finalPanelUrl = "$($Global:serverPanelUrlConfigured):2222/evo/user/plugins/nodejs_selector#/"
    Write-Host "`n准备打开服务器 Node.js 管理页面..." -ForegroundColor Yellow
    Write-Host "URL: $finalPanelUrl" -ForegroundColor Cyan
    
    try {
        Start-Process $finalPanelUrl -ErrorAction Stop
        Write-Host "已尝试在浏览器中打开。如果页面未自动打开，请手动复制上面的链接访问。" -ForegroundColor Green
    }
    catch {
        Write-Error "自动打开浏览器失败: $($_.Exception.Message)"
        Write-Host "请手动复制以下链接到浏览器访问:" -ForegroundColor Yellow
        Write-Host $finalPanelUrl -ForegroundColor Cyan
    }
}
else {
    Write-Host "`n未输入服务器面板URL，跳过自动打开面板操作。" -ForegroundColor Yellow
}

Write-Host "--------------------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "脚本执行完毕。感谢使用！" -ForegroundColor Magenta