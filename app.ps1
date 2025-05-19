Write-Host ""
Write-Host "��ӭʹ�� Webhostmost-ws-nodejs ���ýű�!" -ForegroundColor Magenta
Write-Host "�˽ű��� Joey (joeyblog.net) �ṩ�����ڼ��������̡�" -ForegroundColor Magenta
Write-Host "���Ĺ��ܻ��� eooce �� qwer-search �Ĺ�����" -ForegroundColor Magenta
Write-Host "������Դ˽ű����κη�������ͨ�� Telegram ��ϵ: https://t.me/+ft-zI76oovgwNmRh" -ForegroundColor Magenta
Write-Host "--------------------------------------------------------------------------" -ForegroundColor Magenta

Write-Host "==================== Webhostmost-ws-nodejs �������ɽű� ====================" -ForegroundColor Green

$currentPath = Get-Location
$appJsFileName = "app.js"
$packageJsonFileName = "package.json"
$appJsPath = Join-Path -Path $currentPath -ChildPath $appJsFileName
$packageJsonPath = Join-Path -Path $currentPath -ChildPath $packageJsonFileName

$appJsUrl = "https://raw.githubusercontent.com/byJoey/Webhostmost-ws-nodejs/refs/heads/main/app.js"
$packageJsonUrl = "https://raw.githubusercontent.com/qwer-search/Webhostmost-ws-nodejs/main/package.json"

function Download-File($url, $outputPath, $fileName) {
    Write-Host "�������� $fileName (���� $url)..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $outputPath -ErrorAction Stop
        Write-Host "$fileName ���سɹ���" -ForegroundColor Green
    }
    catch {
        Write-Error "���� $fileName ʧ��: $($_.Exception.Message)"
        Write-Error "�����������ӻ� URL �Ƿ���ȷ: $url"
        throw
    }
}

function Update-AppJsConfig($filePath, $configName, $configValue, $regexPattern, $replacementFormat) {
    try {
        if (-not (Test-Path $filePath -PathType Leaf)) {
            Write-Error "����: app.js �ļ�δ�ҵ���·�� '$filePath'���޷��޸� '$configName'��"
            throw "app.js not found at $filePath"
        }
        $content = Get-Content $filePath -Raw -Encoding UTF8
        $escapedConfigValue = [regex]::Escape($configValue)
        $newContent = $content -replace $regexPattern, ($replacementFormat -replace '\{0\}', $escapedConfigValue)
        
        if ($content -eq $newContent) {
            Write-Warning "����: ������ '$configName' �� app.js ��δ�ҵ�ƥ���ģʽ��ֵδ�ı� (������ʽ: $regexPattern)������ app.js �ļ����ݺͽű��е�������ʽ��"
        } else {
            $newContent | Set-Content $filePath -Encoding UTF8 -NoNewline
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

    $domain = Read-Host "�������������������磺yourdomain.freewebhostmost.com��"
    while ([string]::IsNullOrEmpty($domain)) {
        Write-Host "��������Ϊ�գ����������롣" -ForegroundColor Yellow
        $domain = Read-Host "�������������������磺yourdomain.freewebhostmost.com��"
    }

    $uuid = Read-Host "������ UUID���������Զ����ɣ�"
    if ([string]::IsNullOrEmpty($uuid)) {
        $uuid = [guid]::NewGuid().ToString()
        Write-Host "���Զ����� UUID: $uuid" -ForegroundColor Cyan
    }

    $vl_port = Read-Host "������ app.js �� HTTP �����������˿ڣ�������������� 10000-65535��"
    if ([string]::IsNullOrEmpty($vl_port)) {
        $vl_port = Get-Random -Minimum 10000 -Maximum 65535
        Write-Host "���Զ����ɶ˿ں�: $vl_port" -ForegroundColor Cyan
    } elseif ($vl_port -notmatch "^\d+$" -or [int]$vl_port -lt 1 -or [int]$vl_port -gt 65535) {
        Write-Host "����Ķ˿ں���Ч�����Զ�����һ���˿ںš�" -ForegroundColor Yellow
        $vl_port = Get-Random -Minimum 10000 -Maximum 65535
        Write-Host "���Զ����ɶ˿ں�: $vl_port" -ForegroundColor Cyan
    }

    $subscriptionPathInput = Read-Host "�������Զ��嶩��·�� (���� sub, mypath���������Զ����ɣ���Ҫ�� / ��ͷ)"
    $subscriptionPath = ""
    if ([string]::IsNullOrEmpty($subscriptionPathInput)) {
        $randomPathName = -join ((Get-Random -Count 8 -InputObject (48..57 + 97..122) | ForEach-Object {[char]$_}))
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
    Update-AppJsConfig -filePath $appJsPath -configName "UUID" -configValue $uuid -regexPattern "(const\s+UUID\s*=\s*process\.env\.UUID\s*\|\|\s*')([^']*)(';)" -replacementFormat ('${1}{0}${3}')
    Update-AppJsConfig -filePath $appJsPath -configName "DOMAIN" -configValue $domain -regexPattern "(const\s+DOMAIN\s*=\s*process\.env\.DOMAIN\s*\|\|\s*')([^']*)(';)" -replacementFormat ('${1}{0}${3}')
    Update-AppJsConfig -filePath $appJsPath -configName "PORT" -configValue $vl_port -regexPattern "(const\s+port\s*=\s*process\.env\.PORT\s*\|\|\s*)(\d*)(\s*;)" -replacementFormat ('${1}{0}${3}')
    
    Update-AppJsConfig -filePath $appJsPath -configName "Subscription URL Path" -configValue $subscriptionPath `
        -regexPattern "(else\s+if\s*\(\s*req\.url\s*===\s*')(\/[^']+?)(')" `
        -replacementFormat ('${1}{0}${3}')
    
    return @{Domain = $domain; UUID = $uuid; Port = $vl_port; SubscriptionPath = $subscriptionPath}
}

function Invoke-NezhaConfiguration {
    Write-Host "`n--- �������� Nezha ��ز��� ---" -ForegroundColor Yellow

    $nezhaServer = Read-Host "������ NEZHA_SERVER (���磺nezha.yourdomain.com)"
    while ([string]::IsNullOrEmpty($nezhaServer)) {
        Write-Host "NEZHA_SERVER ����Ϊ�գ����������롣" -ForegroundColor Yellow
        $nezhaServer = Read-Host "������ NEZHA_SERVER"
    }

    $nezhaPort = Read-Host "������ NEZHA_PORT (���磺443 �� 5555)"
    while ([string]::IsNullOrEmpty($nezhaPort) -or $nezhaPort -notmatch "^\d+$") {
        Write-Host "NEZHA_PORT ����Ϊ���ұ���Ϊ���֣����������롣" -ForegroundColor Yellow
        $nezhaPort = Read-Host "������ NEZHA_PORT"
    }

    $nezhaKey = Read-Host "������ NEZHA_KEY (��߸�����Կ��������)"
    if ([string]::IsNullOrEmpty($nezhaKey)) {
        Write-Host "��ʾ: NEZHA_KEY Ϊ�ա�" -ForegroundColor Magenta
    }
    
    Write-Host "�����޸� app.js �е� Nezha ����..."
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
    Write-Host "`n׼�������ļ�..." -ForegroundColor Yellow
    Download-File -url $appJsUrl -outputPath $appJsPath -fileName $appJsFileName
    Download-File -url $packageJsonUrl -outputPath $packageJsonPath -fileName $packageJsonFileName

    $basicConfigDetails = Invoke-BasicConfiguration
    if ($null -ne $basicConfigDetails) {
        $basicConfigPerformed = $true
        Write-Host "`n==================== ����������� ====================" -ForegroundColor Green
        Write-Host "���� (Domain)�� $($basicConfigDetails.Domain)"
        Write-Host "UUID�� $($basicConfigDetails.UUID)"
        Write-Host "app.js �����˿� (Port)�� $($basicConfigDetails.Port)"
        Write-Host "����·�� (Subscription Path): $($basicConfigDetails.SubscriptionPath)" -ForegroundColor Cyan
        $subLink = "https://$($basicConfigDetails.Domain)$($basicConfigDetails.SubscriptionPath)"
        Write-Host "�ڵ�������� (VLESS Subscription Link)��$subLink" -ForegroundColor Cyan
        Write-Host "--------------------------------------------------------"
    }

    if ($basicConfigPerformed) {
        $configureNezhaChoice = Read-Host "�Ƿ�Ҫ�������� Nezha ��ز���? (Y/N)"
        if ($configureNezhaChoice -match '^[Yy]$') {
            $nezhaConfigDetails = Invoke-NezhaConfiguration
            if ($null -ne $nezhaConfigDetails) {
                $nezhaConfigPerformed = $true
                Write-Host "`n==================== Nezha ������� ====================" -ForegroundColor Green
                Write-Host "NEZHA_SERVER�� $($nezhaConfigDetails.NezhaServer)"
                Write-Host "NEZHA_PORT�� $($nezhaConfigDetails.NezhaPort)"
                Write-Host "NEZHA_KEY�� $($nezhaConfigDetails.NezhaKey)"
                Write-Host "Nezha ���������õ� app.js��" -ForegroundColor Green
                Write-Host "--------------------------------------------------------"
            }
        } else {
            Write-Host "���� Nezha ��ز������á�" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Error "�����ù����з������ش���: $($_.Exception.Message)"
    Write-Host "��������ֹ��" -ForegroundColor Red
}

if ($basicConfigPerformed -or $nezhaConfigPerformed) {
    Write-Host "`n==================== �������ò������ ====================" -ForegroundColor Green
    Write-Host "�����ļ��ѱ�������ǰĿ¼��$currentPath"
    
    if ($basicConfigPerformed -and $null -ne $basicConfigDetails.Domain) {
        Write-Host "����Ҫ�ֶ��������ļ��ϴ������� Webhostmost ������������ϴ�·��Ϊ��" -ForegroundColor Yellow
        Write-Host "  domains/$($basicConfigDetails.Domain)/public_html" -ForegroundColor Cyan
        Write-Host "�뽫�����ļ��ϴ�������·����" -ForegroundColor Yellow
    } else {
        Write-Host "����Ҫ�ֶ��������ļ��ϴ������� Webhostmost ��������վ��Ŀ¼ (���� public_html)��" -ForegroundColor Yellow
    }
    Write-Host "  - $appJsFileName"
    Write-Host "  - $packageJsonFileName"
    Write-Host "--------------------------------------------------------"
    if ($basicConfigPerformed) {
        Write-Host "�����û���������" -ForegroundColor Green
        if ($null -ne $basicConfigDetails.SubscriptionPath) {
             Write-Host "�Զ���/�Զ����ɵĶ���·��Ϊ: $($basicConfigDetails.SubscriptionPath)" -ForegroundColor Green
        }
    }
    if ($nezhaConfigPerformed) {
        Write-Host "������ Nezha ��ز�����" -ForegroundColor Green
    }
    Write-Host "--------------------------------------------------------"
    Write-Host "��Ҫ��ʾ: ����޸ĺ�� $appJsFileName �ļ����ı��༭���г������룬" -ForegroundColor Yellow
    Write-Host "��ȷ�������ı��༭��ʹ�� UTF-8 �������򿪺Ͳ鿴���ļ���" -ForegroundColor Yellow
} elseif ($_.Exception) {
    Write-Host "���ڷ�����������δȫ����ɡ�" -ForegroundColor Red
} else {
    Write-Host "δ�����κ���Ч���ã�������δ�ɹ���" -ForegroundColor Yellow
}

Write-Host "==================== �ű��������� ====================" -ForegroundColor Green
