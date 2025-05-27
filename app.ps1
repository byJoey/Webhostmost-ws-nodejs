# Author: Joey
# Blog: joeyblog.net
# Feedback TG (����TG): https://t.me/+ft-zI76oovgwNmRh
# Core Functionality By (���Ĺ���ʵ��):
#   - https://github.com/eooce
#   - https://github.com/qwer-search
# Version: PS-2.4.8 (Added panel URL opening with https default)

Write-Host ""
Write-Host "��ӭʹ�� Webhostmost-ws-nodejs ���ýű� (PowerShell �汾)!" -ForegroundColor Magenta
Write-Host "�˽ű��� Joey (joeyblog.net) �ṩ�����ڼ��������̡�" -ForegroundColor Magenta
Write-Host "���Ĺ��ܻ��� eooce �� qwer-search �Ĺ�����" -ForegroundColor Magenta
Write-Host "������Դ˽ű����κη�������ͨ�� Telegram ��ϵ: https://t.me/+ft-zI76oovgwNmRh" -ForegroundColor Magenta
Write-Host "--------------------------------------------------------------------------" -ForegroundColor Magenta

Write-Host "==================== Webhostmost-ws-nodejs �������ɽű� ====================" -ForegroundColor Green

# --- ȫ�ֱ��� ---
$currentPath = Get-Location
$appJsFileName = "app.js"
$packageJsonFileName = "package.json"
$appJsPath = Join-Path -Path $currentPath.Path -ChildPath $appJsFileName # Ensure .Path is used for currentPath if it's a PathInfo object
$packageJsonPath = Join-Path -Path $currentPath.Path -ChildPath $packageJsonFileName

$appJsUrl = "https://raw.githubusercontent.com/byJoey/Webhostmost-ws-nodejs/refs/heads/main/app.js"
$packageJsonUrl = "https://raw.githubusercontent.com/qwer-search/Webhostmost-ws-nodejs/main/package.json"

$Global:serverPanelUrlConfigured = "" # ����ȫ�ֱ���

# --- �������� ---

function Invoke-ServerPanelUrlPrompt {
    Write-Host "`n--- ׼���򿪷����� Node.js ������� ---" -ForegroundColor Yellow
    $panelUrlInput = ""
    while ([string]::IsNullOrEmpty($panelUrlInput)) {
        $panelUrlInput = Read-Host "���������ķ���������URL (����: server7.webhostmost.com)"
        if ([string]::IsNullOrEmpty($panelUrlInput)) {
            Write-Host "���������URL����Ϊ�գ����������롣" -ForegroundColor Yellow
        }
    }

    # ���Ƴ�ĩβ��б��
    $panelUrlInput = $panelUrlInput.TrimEnd('/')

    # ��鲢���Э��ͷ
    if (-not ($panelUrlInput -match "://")) {
        Write-Host "��⵽�����URLȱ��Э��ͷ (���� http:// �� https://)����Ĭ��ʹ�� https://" -ForegroundColor Yellow
        $panelUrlInput = "https://$panelUrlInput"
    }

    $Global:serverPanelUrlConfigured = $panelUrlInput
    Write-Host "������������URL�Ѽ�¼: $Global:serverPanelUrlConfigured" -ForegroundColor Cyan
}

function Download-File($url, $outputPath, $fileName) {
    Write-Host "�������� $fileName (���� $url)..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $outputPath -ErrorAction Stop
        Write-Host "$fileName ���سɹ���" -ForegroundColor Green
    }
    catch {
        Write-Error "���� $fileName ʧ��: $($_.Exception.Message)"
        Write-Error "�����������ӻ� URL �Ƿ���ȷ: $url"
        throw # Re-throw the exception to be caught by the main try-catch block if necessary
    }
}

function Update-AppJsConfig($filePath, $configName, $configValue, $regexPattern, $replacementFormat) {
    try {
        if (-not (Test-Path $filePath -PathType Leaf)) {
            Write-Error "����: app.js �ļ�δ�ҵ���·�� '$filePath'���޷��޸� '$configName'��"
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
            Write-Warning "����: ������ '$configName' �� app.js ��δ�ҵ�ƥ���ģʽ��ֵδ�ı� (������ʽ: $regexPattern)������ app.js �ļ����ݺͽű��е�������ʽ��"
        } else {
            # Ensure to write back using UTF8, -NoNewline might be desired if original was without.
            # Get-Content -Raw preserves original newlines, so -NoNewline prevents an *extra* one from Set-Content.
            Set-Content -Path $filePath -Value $newContent -Encoding UTF8 -NoNewline
            Write-Host "app.js �е� '$configName' �Ѹ���Ϊ '$configValue'��" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "�޸� app.js �е� '$configName' ʧ��: $($_.Exception.Message)"
        throw
    }
}

function Invoke-BasicConfiguration {
    Write-Host "`n--- �������û���������� (UUID, Domain, Port, Subscription Path) ---" -ForegroundColor Yellow

    $domain = ""
    while ([string]::IsNullOrEmpty($domain)) {
        $domain = Read-Host "�������������������磺yourdomain.freewebhostmost.com��"
        if ([string]::IsNullOrEmpty($domain)) {
            Write-Host "��������Ϊ�գ����������롣" -ForegroundColor Yellow
        }
    }

    $uuid = Read-Host "������ UUID���������Զ����ɣ�"
    if ([string]::IsNullOrEmpty($uuid)) {
        $uuid = [guid]::NewGuid().ToString()
        Write-Host "���Զ����� UUID: $uuid" -ForegroundColor Cyan
    }

    $vl_port_str = Read-Host "������ app.js �� HTTP �����������˿ڣ�������������� 10000-65535��"
    $vl_port = 0
    if ([string]::IsNullOrEmpty($vl_port_str)) {
        $vl_port = Get-Random -Minimum 10000 -Maximum 65535
        Write-Host "���Զ����ɶ˿ں�: $vl_port" -ForegroundColor Cyan
    } elseif ($vl_port_str -notmatch "^\d+$" -or [int]$vl_port_str -lt 1 -or [int]$vl_port_str -gt 65535) {
        Write-Host "����Ķ˿ں���Ч�����Զ�����һ���˿ںš�" -ForegroundColor Yellow
        $vl_port = Get-Random -Minimum 10000 -Maximum 65535
        Write-Host "���Զ����ɶ˿ں�: $vl_port" -ForegroundColor Cyan
    } else {
        $vl_port = [int]$vl_port_str
    }

    $subscriptionPathInput = Read-Host "�������Զ��嶩��·�� (���� sub, mypath���������Զ����ɣ���Ҫ�� / ��ͷ)"
    $subscriptionPath = ""
    if ([string]::IsNullOrEmpty($subscriptionPathInput)) {
        $randomPathName = -join ((Get-Random -Count 8 -InputObject (48..57 + 97..122) | ForEach-Object {[char]$_})) # Generates a-z0-9
        $subscriptionPath = "/" + $randomPathName
        Write-Host "���Զ����ɶ���·��: $subscriptionPath" -ForegroundColor Cyan
    } else {
        $cleanedPath = $subscriptionPathInput.TrimStart('/').TrimEnd('/')
        if ([string]::IsNullOrEmpty($cleanedPath)) {
            $randomPathName = -join ((Get-Random -Count 8 -InputObject (48..57 + 97..122) | ForEach-Object {[char]$_}))
            $subscriptionPath = "/" + $randomPathName
            Write-Host "�����·����Ч�����Զ����ɶ���·��: $subscriptionPath" -ForegroundColor Cyan
        } else {
            $subscriptionPath = "/" + $cleanedPath
        }
    }
    Write-Host "���ն���·������: $subscriptionPath" -ForegroundColor Cyan
    
    Write-Host "�����޸� app.js �еĻ�������..."
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
    Write-Host "`n--- �������� Nezha ��ز��� ---" -ForegroundColor Yellow

    $nezhaServer = ""
    while ([string]::IsNullOrEmpty($nezhaServer)) {
        $nezhaServer = Read-Host "������ NEZHA_SERVER (���磺nezha.yourdomain.com)"
         if ([string]::IsNullOrEmpty($nezhaServer)) {
            Write-Host "NEZHA_SERVER ����Ϊ�գ����������롣" -ForegroundColor Yellow
        }
    }

    $nezhaPort = ""
    while ([string]::IsNullOrEmpty($nezhaPort) -or $nezhaPort -notmatch "^\d+$") {
        $nezhaPort = Read-Host "������ NEZHA_PORT (���磺443 �� 5555)"
        if ([string]::IsNullOrEmpty($nezhaPort) -or $nezhaPort -notmatch "^\d+$") {
            Write-Host "NEZHA_PORT ����Ϊ���ұ���Ϊ���֣����������롣" -ForegroundColor Yellow
        }
    }

    $nezhaKey = Read-Host "������ NEZHA_KEY (��߸�����Կ��������)"
    if ([string]::IsNullOrEmpty($nezhaKey)) {
        Write-Host "��ʾ: NEZHA_KEY Ϊ�ա�" -ForegroundColor Magenta
    }
    
    Write-Host "�����޸� app.js �е� Nezha ����..."
    Update-AppJsConfig -filePath $appJsPath -configName "NEZHA_SERVER" -configValue $nezhaServer -regexPattern "(const\s+NEZHA_SERVER\s*=\s*process\.env\.NEZHA_SERVER\s*\|\|\s*')([^']*)(';)" -replacementFormat '${1}{0}${3}'
    Update-AppJsConfig -filePath $appJsPath -configName "NEZHA_PORT" -configValue $nezhaPort -regexPattern "(const\s+NEZHA_PORT\s*=\s*process\.env\.NEZHA_PORT\s*\|\|\s*')([^']*)(';)" -replacementFormat '${1}{0}${3}'
    Update-AppJsConfig -filePath $appJsPath -configName "NEZHA_KEY" -configValue $nezhaKey -regexPattern "(const\s+NEZHA_KEY\s*=\s*process\.env\.NEZHA_KEY\s*\|\|\s*')([^']*)(';)" -replacementFormat '${1}{0}${3}'

    return @{NezhaServer = $nezhaServer; NezhaPort = $nezhaPort; NezhaKey = $nezhaKey}
}

# --- �������߼� ---
$basicConfigPerformed = $false
$nezhaConfigPerformed = $false
$basicConfigDetails = $null
$nezhaConfigDetails = $null
$errorOccurredDuringSetup = $false

Invoke-ServerPanelUrlPrompt # �����º���

try {
    Write-Host "`n׼�������ļ�..." -ForegroundColor Yellow
    Download-File -url $appJsUrl -outputPath $appJsPath -fileName $appJsFileName
    Download-File -url $packageJsonUrl -outputPath $packageJsonPath -fileName $packageJsonFileName

    $basicConfigDetails = Invoke-BasicConfiguration
    if ($null -ne $basicConfigDetails) {
        $basicConfigPerformed = $true
        Write-Host "`n==================== ����������� ====================" -ForegroundColor Green
        Write-Host "���� (Domain)�� $($basicConfigDetails.Domain)" -ForegroundColor Cyan
        Write-Host "UUID�� $($basicConfigDetails.UUID)" -ForegroundColor Cyan
        Write-Host "app.js �����˿� (Port)�� $($basicConfigDetails.Port)" -ForegroundColor Cyan
        Write-Host "����·�� (Subscription Path): $($basicConfigDetails.SubscriptionPath)" -ForegroundColor Cyan
        $subLink = "https://$($basicConfigDetails.Domain)$($basicConfigDetails.SubscriptionPath)"
        Write-Host "�ڵ�������� (VLESS Subscription Link)��$subLink" -ForegroundColor Cyan
        Write-Host "--------------------------------------------------------" -ForegroundColor Green
    } else {
      $errorOccurredDuringSetup = $true # Basic config failed
    }

    if ($basicConfigPerformed) {
        $configureNezhaChoice = Read-Host "�Ƿ�Ҫ�������� Nezha ��ز���? (Y/N)"
        if ($configureNezhaChoice -match '^[Yy]$') {
            $nezhaConfigDetails = Invoke-NezhaConfiguration
            if ($null -ne $nezhaConfigDetails) {
                $nezhaConfigPerformed = $true
                Write-Host "`n==================== Nezha ������� ====================" -ForegroundColor Green
                Write-Host "NEZHA_SERVER�� $($nezhaConfigDetails.NezhaServer)" -ForegroundColor Cyan
                Write-Host "NEZHA_PORT�� $($nezhaConfigDetails.NezhaPort)" -ForegroundColor Cyan
                Write-Host "NEZHA_KEY�� $($nezhaConfigDetails.NezhaKey)" -ForegroundColor Cyan
                Write-Host "Nezha ���������õ� app.js��" -ForegroundColor Green
                Write-Host "--------------------------------------------------------" -ForegroundColor Green
            } else {
                 # Nezha config failed, but basic might be okay. Not setting $errorOccurredDuringSetup = $true here
                 Write-Error "Nezha ����δ�ɹ���ɡ�"
            }
        } else {
            Write-Host "���� Nezha ��ز������á�" -ForegroundColor Yellow
        }
    }
}
catch {
    # This catches errors from Download-File or if functions explicitly throw.
    Write-Error "�����ù����з������ش���: $($_.Exception.Message)"
    Write-Host "��������ֹ��" -ForegroundColor Red
    $errorOccurredDuringSetup = $true
}

# --- �ܽ�����ʾ ---
if ($basicConfigPerformed -or $nezhaConfigPerformed) {
    Write-Host "`n==================== �������ò������ ====================" -ForegroundColor Green
    Write-Host "�����ļ��ѱ�������ǰĿ¼��$($currentPath.Path)" -ForegroundColor Cyan
    
    if ($basicConfigPerformed -and $null -ne $basicConfigDetails.Domain) {
        Write-Host "����Ҫ�ֶ��������ļ��ϴ������� Webhostmost ������������ϴ�·��Ϊ��" -ForegroundColor Yellow
        Write-Host "  domains/$($basicConfigDetails.Domain)/public_html" -ForegroundColor Cyan
        Write-Host "�뽫�����ļ��ϴ�������·����" -ForegroundColor Yellow
    } else {
        Write-Host "����Ҫ�ֶ��������ļ��ϴ������� Webhostmost ��������վ��Ŀ¼ (���� public_html)��" -ForegroundColor Yellow
    }
    Write-Host "  - $appJsFileName"
    Write-Host "  - $packageJsonFileName"
    Write-Host "--------------------------------------------------------" -ForegroundColor Green
    if ($basicConfigPerformed) {
        Write-Host "�����û���������" -ForegroundColor Green
        if ($null -ne $basicConfigDetails.SubscriptionPath) {
            Write-Host "�Զ���/�Զ����ɵĶ���·��Ϊ: $($basicConfigDetails.SubscriptionPath)" -ForegroundColor Green
        }
    }
    if ($nezhaConfigPerformed) {
        Write-Host "������ Nezha ��ز�����" -ForegroundColor Green
    }
    Write-Host "--------------------------------------------------------" -ForegroundColor Green
    Write-Host "��Ҫ��ʾ: ����޸ĺ�� $appJsFileName �ļ����ı��༭���г������룬" -ForegroundColor Yellow
    Write-Host "��ȷ�������ı��༭��ʹ�� UTF-8 �������򿪺Ͳ鿴���ļ���" -ForegroundColor Yellow

} elseif ($errorOccurredDuringSetup) { # Check our custom flag
    Write-Host "`n���ڷ�����������δȫ����ɡ�" -ForegroundColor Red
} else {
    # This case might be hit if no configurations were attempted or if a non-terminating error occurred that wasn't caught by main try-catch
    Write-Host "`nδ�����κ���Ч���ã�������δ�ɹ���" -ForegroundColor Yellow
}

Write-Host "`n==================== �ű��������� ====================" -ForegroundColor Green

# --- ���Դ������ ---
if (-not [string]::IsNullOrEmpty($Global:serverPanelUrlConfigured)) {
    $finalPanelUrl = "$($Global:serverPanelUrlConfigured):2222/evo/user/plugins/nodejs_selector#/"
    Write-Host "`n׼���򿪷����� Node.js ����ҳ��..." -ForegroundColor Yellow
    Write-Host "URL: $finalPanelUrl" -ForegroundColor Cyan
    
    try {
        Start-Process $finalPanelUrl -ErrorAction Stop
        Write-Host "�ѳ�����������д򿪡����ҳ��δ�Զ��򿪣����ֶ�������������ӷ��ʡ�" -ForegroundColor Green
    }
    catch {
        Write-Error "�Զ��������ʧ��: $($_.Exception.Message)"
        Write-Host "���ֶ������������ӵ����������:" -ForegroundColor Yellow
        Write-Host $finalPanelUrl -ForegroundColor Cyan
    }
}
else {
    Write-Host "`nδ������������URL�������Զ�����������" -ForegroundColor Yellow
}

Write-Host "--------------------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "�ű�ִ����ϡ���лʹ�ã�" -ForegroundColor Magenta