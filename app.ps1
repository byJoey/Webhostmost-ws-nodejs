Write-Host ""
Write-Host "欢迎使用 Webhostmost-ws-nodejs 配置脚本!" -ForegroundColor Magenta
Write-Host "此脚本由 Joey (joeyblog.net) 提供，用于简化配置流程。" -ForegroundColor Magenta
Write-Host "核心功能基于 eooce 和 qwer-search 的工作。" -ForegroundColor Magenta
Write-Host "如果您对此脚本有任何反馈，请通过 Telegram 联系: https://t.me/+ft-zI76oovgwNmRh" -ForegroundColor Magenta
Write-Host "--------------------------------------------------------------------------" -ForegroundColor Magenta

Write-Host "==================== Webhostmost-ws-nodejs 配置生成脚本 ====================" -ForegroundColor Green

$currentPath = Get-Location
$appJsFileName = "app.js"
$packageJsonFileName = "package.json"
$appJsPath = Join-Path -Path $currentPath -ChildPath $appJsFileName
$packageJsonPath = Join-Path -Path $currentPath -ChildPath $packageJsonFileName

$appJsUrl = "https://raw.githubusercontent.com/byJoey/Webhostmost-ws-nodejs/refs/heads/main/app.js"
$packageJsonUrl = "https://raw.githubusercontent.com/qwer-search/Webhostmost-ws-nodejs/main/package.json"

function Download-File($url, $outputPath, $fileName) {
    Write-Host "正在下载 $fileName (来自 $url)..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $outputPath -ErrorAction Stop
        Write-Host "$fileName 下载成功。" -ForegroundColor Green
    }
    catch {
        Write-Error "下载 $fileName 失败: $($_.Exception.Message)"
        Write-Error "请检查网络连接或 URL 是否正确: $url"
        throw
    }
}

function Update-AppJsConfig($filePath, $configName, $configValue, $regexPattern, $replacementFormat) {
    try {
        if (-not (Test-Path $filePath -PathType Leaf)) {
            Write-Error "错误: app.js 文件未找到于路径 '$filePath'。无法修改 '$configName'。"
            throw "app.js not found at $filePath"
        }
        $content = Get-Content $filePath -Raw -Encoding UTF8
        $escapedConfigValue = [regex]::Escape($configValue)
        $newContent = $content -replace $regexPattern, ($replacementFormat -replace '\{0\}', $escapedConfigValue)
        
        if ($content -eq $newContent) {
            Write-Warning "警告: 配置项 '$configName' 在 app.js 中未找到匹配的模式或值未改变 (正则表达式: $regexPattern)。请检查 app.js 文件内容和脚本中的正则表达式。"
        } else {
            $newContent | Set-Content $filePath -Encoding UTF8 -NoNewline
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

    $domain = Read-Host "请输入您的域名（例如：yourdomain.freewebhostmost.com）"
    while ([string]::IsNullOrEmpty($domain)) {
        Write-Host "域名不能为空，请重新输入。" -ForegroundColor Yellow
        $domain = Read-Host "请输入您的域名（例如：yourdomain.freewebhostmost.com）"
    }

    $uuid = Read-Host "请输入 UUID（留空则自动生成）"
    if ([string]::IsNullOrEmpty($uuid)) {
        $uuid = [guid]::NewGuid().ToString()
        Write-Host "已自动生成 UUID: $uuid" -ForegroundColor Cyan
    }

    $vl_port = Read-Host "请输入 app.js 的 HTTP 服务器监听端口（留空则随机生成 10000-65535）"
    if ([string]::IsNullOrEmpty($vl_port)) {
        $vl_port = Get-Random -Minimum 10000 -Maximum 65535
        Write-Host "已自动生成端口号: $vl_port" -ForegroundColor Cyan
    } elseif ($vl_port -notmatch "^\d+$" -or [int]$vl_port -lt 1 -or [int]$vl_port -gt 65535) {
        Write-Host "输入的端口号无效，将自动生成一个端口号。" -ForegroundColor Yellow
        $vl_port = Get-Random -Minimum 10000 -Maximum 65535
        Write-Host "已自动生成端口号: $vl_port" -ForegroundColor Cyan
    }

    $subscriptionPathInput = Read-Host "请输入自定义订阅路径 (例如 sub, mypath。留空则自动生成，不要以 / 开头)"
    $subscriptionPath = ""
    if ([string]::IsNullOrEmpty($subscriptionPathInput)) {
        $randomPathName = -join ((Get-Random -Count 8 -InputObject (48..57 + 97..122) | ForEach-Object {[char]$_}))
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
    Update-AppJsConfig -filePath $appJsPath -configName "UUID" -configValue $uuid -regexPattern "(const\s+UUID\s*=\s*process\.env\.UUID\s*\|\|\s*')([^']*)(';)" -replacementFormat ('${1}{0}${3}')
    Update-AppJsConfig -filePath $appJsPath -configName "DOMAIN" -configValue $domain -regexPattern "(const\s+DOMAIN\s*=\s*process\.env\.DOMAIN\s*\|\|\s*')([^']*)(';)" -replacementFormat ('${1}{0}${3}')
    Update-AppJsConfig -filePath $appJsPath -configName "PORT" -configValue $vl_port -regexPattern "(const\s+port\s*=\s*process\.env\.PORT\s*\|\|\s*)(\d*)(\s*;)" -replacementFormat ('${1}{0}${3}')
    
    Update-AppJsConfig -filePath $appJsPath -configName "Subscription URL Path" -configValue $subscriptionPath `
        -regexPattern "(else\s+if\s*\(\s*req\.url\s*===\s*')(\/[^']+?)(')" `
        -replacementFormat ('${1}{0}${3}')
    
    return @{Domain = $domain; UUID = $uuid; Port = $vl_port; SubscriptionPath = $subscriptionPath}
}

function Invoke-NezhaConfiguration {
    Write-Host "`n--- 正在配置 Nezha 监控参数 ---" -ForegroundColor Yellow

    $nezhaServer = Read-Host "请输入 NEZHA_SERVER (例如：nezha.yourdomain.com)"
    while ([string]::IsNullOrEmpty($nezhaServer)) {
        Write-Host "NEZHA_SERVER 不能为空，请重新输入。" -ForegroundColor Yellow
        $nezhaServer = Read-Host "请输入 NEZHA_SERVER"
    }

    $nezhaPort = Read-Host "请输入 NEZHA_PORT (例如：443 或 5555)"
    while ([string]::IsNullOrEmpty($nezhaPort) -or $nezhaPort -notmatch "^\d+$") {
        Write-Host "NEZHA_PORT 不能为空且必须为数字，请重新输入。" -ForegroundColor Yellow
        $nezhaPort = Read-Host "请输入 NEZHA_PORT"
    }

    $nezhaKey = Read-Host "请输入 NEZHA_KEY (哪吒面板密钥，可留空)"
    if ([string]::IsNullOrEmpty($nezhaKey)) {
        Write-Host "提示: NEZHA_KEY 为空。" -ForegroundColor Magenta
    }
    
    Write-Host "正在修改 app.js 中的 Nezha 参数..."
    Update-AppJsConfig -filePath $appJsPath -configName "NEZHA_SERVER" -configValue $nezhaServer -regexPattern "(const\s+NEZHA_SERVER\s*=\s*process\.env\.NEZHA_SERVER\s*\|\|\s*')([^']*)(';)" -replacementFormat ('${1}{0}${3}')
    Update-AppJsConfig -filePath $appJsPath -configName "NEZHA_PORT" -configValue $nezhaPort -regexPattern "(const\s+NEZHA_PORT\s*=\s*process\.env\.NEZHA_PORT\s*\|\|\s*')([^']*)(';)" -replacementFormat ('${1}{0}${3}')
    Update-AppJsConfig -filePath $appJsPath -configName "NEZHA_KEY" -configValue $nezhaKey -regexPattern "(const\s+NEZHA_KEY\s*=\s*process\.env\.NEZHA_KEY\s*\|\|\s*')([^']*)(';)" -replacementFormat ('${1}{0}${3}')

    return @{NezhaServer = $nezhaServer; NezhaPort = $nezhaPort; NezhaKey = $nezhaKey}
}

$basicConfigPerformed = $false
$nezhaConfigPerformed = $false
$basicConfigDetails = $null
$nezhaConfigDetails = $null

try {
    Write-Host "`n准备配置文件..." -ForegroundColor Yellow
    Download-File -url $appJsUrl -outputPath $appJsPath -fileName $appJsFileName
    Download-File -url $packageJsonUrl -outputPath $packageJsonPath -fileName $packageJsonFileName

    $basicConfigDetails = Invoke-BasicConfiguration
    if ($null -ne $basicConfigDetails) {
        $basicConfigPerformed = $true
        Write-Host "`n==================== 基本配置完成 ====================" -ForegroundColor Green
        Write-Host "域名 (Domain)： $($basicConfigDetails.Domain)"
        Write-Host "UUID： $($basicConfigDetails.UUID)"
        Write-Host "app.js 监听端口 (Port)： $($basicConfigDetails.Port)"
        Write-Host "订阅路径 (Subscription Path): $($basicConfigDetails.SubscriptionPath)" -ForegroundColor Cyan
        $subLink = "https://$($basicConfigDetails.Domain)$($basicConfigDetails.SubscriptionPath)"
        Write-Host "节点分享链接 (VLESS Subscription Link)：$subLink" -ForegroundColor Cyan
        Write-Host "--------------------------------------------------------"
    }

    if ($basicConfigPerformed) {
        $configureNezhaChoice = Read-Host "是否要继续配置 Nezha 监控参数? (Y/N)"
        if ($configureNezhaChoice -match '^[Yy]$') {
            $nezhaConfigDetails = Invoke-NezhaConfiguration
            if ($null -ne $nezhaConfigDetails) {
                $nezhaConfigPerformed = $true
                Write-Host "`n==================== Nezha 配置完成 ====================" -ForegroundColor Green
                Write-Host "NEZHA_SERVER： $($nezhaConfigDetails.NezhaServer)"
                Write-Host "NEZHA_PORT： $($nezhaConfigDetails.NezhaPort)"
                Write-Host "NEZHA_KEY： $($nezhaConfigDetails.NezhaKey)"
                Write-Host "Nezha 参数已配置到 app.js。" -ForegroundColor Green
                Write-Host "--------------------------------------------------------"
            }
        } else {
            Write-Host "跳过 Nezha 监控参数配置。" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Error "在配置过程中发生严重错误: $($_.Exception.Message)"
    Write-Host "操作已中止。" -ForegroundColor Red
}

if ($basicConfigPerformed -or $nezhaConfigPerformed) {
    Write-Host "`n==================== 所有配置操作完成 ====================" -ForegroundColor Green
    Write-Host "配置文件已保存至当前目录：$currentPath"
    
    if ($basicConfigPerformed -and $null -ne $basicConfigDetails.Domain) {
        Write-Host "您需要手动将以下文件上传到您的 Webhostmost 主机，建议的上传路径为：" -ForegroundColor Yellow
        Write-Host "  domains/$($basicConfigDetails.Domain)/public_html" -ForegroundColor Cyan
        Write-Host "请将以下文件上传到上述路径：" -ForegroundColor Yellow
    } else {
        Write-Host "您需要手动将以下文件上传到您的 Webhostmost 主机的网站根目录 (例如 public_html)：" -ForegroundColor Yellow
    }
    Write-Host "  - $appJsFileName"
    Write-Host "  - $packageJsonFileName"
    Write-Host "--------------------------------------------------------"
    if ($basicConfigPerformed) {
        Write-Host "已配置基本参数。" -ForegroundColor Green
        if ($null -ne $basicConfigDetails.SubscriptionPath) {
             Write-Host "自定义/自动生成的订阅路径为: $($basicConfigDetails.SubscriptionPath)" -ForegroundColor Green
        }
    }
    if ($nezhaConfigPerformed) {
        Write-Host "已配置 Nezha 监控参数。" -ForegroundColor Green
    }
    Write-Host "--------------------------------------------------------"
    Write-Host "重要提示: 如果修改后的 $appJsFileName 文件在文本编辑器中出现乱码，" -ForegroundColor Yellow
    Write-Host "请确保您的文本编辑器使用 UTF-8 编码来打开和查看该文件。" -ForegroundColor Yellow
} elseif ($_.Exception) {
    Write-Host "由于发生错误，配置未全部完成。" -ForegroundColor Red
} else {
    Write-Host "未进行任何有效配置，或配置未成功。" -ForegroundColor Yellow
}

Write-Host "==================== 脚本操作结束 ====================" -ForegroundColor Green
