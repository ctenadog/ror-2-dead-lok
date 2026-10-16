# Deadlock Survivors - сборка и установка в Risk of Rain 2 (без Melty).
# Файлы Deadlock не копируются: плагину только сообщается, где лежит игра.
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$ToolsDir = Join-Path $Root '.tools'
$BepInExUrl = 'https://github.com/BepInEx/BepInEx/releases/download/v5.4.21/BepInEx_x64_5.4.21.0.zip'
$PluginGuid = 'ctenadog.deadlocksurvivors'

function Step($t) { Write-Host ''; Write-Host "== $t" -ForegroundColor Cyan }
function Fail($t) { Write-Host ''; Write-Host "ОШИБКА: $t" -ForegroundColor Red; exit 1 }

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 1. .NET SDK 8: системный или локальный в .tools (без прав администратора)
Step 'Проверяю .NET SDK 8'
$dotnet = $null
$sys = Get-Command dotnet -ErrorAction SilentlyContinue
if ($sys) {
    $sdks = & $sys.Source --list-sdks 2>$null
    if ($sdks -match '^(8|9|10)\.') { $dotnet = $sys.Source }
}
if (-not $dotnet) {
    $local = Join-Path $ToolsDir 'dotnet\dotnet.exe'
    if (-not (Test-Path $local)) {
        Write-Host 'Скачиваю .NET SDK 8 с dot.net в папку .tools (один раз)...'
        New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null
        $script = Join-Path $ToolsDir 'dotnet-install.ps1'
        Invoke-WebRequest 'https://dot.net/v1/dotnet-install.ps1' -OutFile $script -UseBasicParsing
        & $script -Channel 8.0 -InstallDir (Join-Path $ToolsDir 'dotnet') -NoPath
    }
    $dotnet = $local
}
Write-Host "dotnet: $dotnet"

# 2. Сборка
Step 'Собираю плагин'
# Старая сборка удаляется, чтобы не скопировать устаревшую DLL
foreach ($d in 'bin', 'obj') {
    $p = Join-Path $Root "src\DeadlockSurvivors\$d"
    if (Test-Path $p) { Remove-Item $p -Recurse -Force }
}
& $dotnet build (Join-Path $Root 'src\DeadlockSurvivors') -c Release --nologo
if ($LASTEXITCODE -ne 0) { Fail 'сборка не удалась, смотрите сообщения выше.' }
$Dll = Join-Path $Root 'src\DeadlockSurvivors\bin\Release\netstandard2.1\DeadlockSurvivors.dll'
if (-not (Test-Path $Dll)) { Fail "не найден $Dll" }

# 3. Поиск игр в библиотеках Steam
Step 'Ищу игры в библиотеках Steam'
$libs = New-Object System.Collections.Generic.List[string]
$steam = $null
foreach ($k in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam') {
    $p = Get-ItemProperty $k -ErrorAction SilentlyContinue
    if ($p.SteamPath) { $steam = $p.SteamPath; break }
    if ($p.InstallPath) { $steam = $p.InstallPath; break }
}
if ($steam) {
    $libs.Add(($steam -replace '/', '\'))
    $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
    if (Test-Path $vdf) {
        foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) {
            $libs.Add(($m.Groups[1].Value -replace '\\\\', '\'))
        }
    }
}
function Find-Game($folder) {
    foreach ($l in ($libs | Select-Object -Unique)) {
        $c = Join-Path $l "steamapps\common\$folder"
        if (Test-Path $c) { return $c }
    }
    return $null
}
$Ror2 = Find-Game 'Risk of Rain 2'
if (-not $Ror2 -or -not (Test-Path (Join-Path $Ror2 'Risk of Rain 2.exe'))) {
    $Ror2 = Read-Host 'Risk of Rain 2 не найдена. Вставьте путь к папке игры (где лежит "Risk of Rain 2.exe")'
    if (-not (Test-Path (Join-Path $Ror2 'Risk of Rain 2.exe'))) { Fail 'в этой папке нет "Risk of Rain 2.exe".' }
}
Write-Host "Risk of Rain 2: $Ror2"
$Deadlock = Find-Game 'Deadlock'
if (-not $Deadlock -or -not (Test-Path (Join-Path $Deadlock 'game\citadel'))) {
    $Deadlock = Read-Host 'Deadlock не найден. Вставьте путь к папке игры (где лежит папка "game"), или Enter чтобы пропустить'
    if ($Deadlock -and -not (Test-Path (Join-Path $Deadlock 'game\citadel'))) {
        Write-Host 'В этой папке нет game\citadel - путь к Deadlock не будет записан.' -ForegroundColor Yellow
        $Deadlock = ''
    }
}
if ($Deadlock) { Write-Host "Deadlock: $Deadlock" }

# 4. Игра не должна быть запущена (закрывать её скрипт не будет)
if (Get-Process -Name 'Risk of Rain 2' -ErrorAction SilentlyContinue) {
    Fail 'Risk of Rain 2 сейчас запущена. Закройте её сами и запустите install.bat снова.'
}

# 5. BepInEx 5
Step 'Проверяю BepInEx 5'
if (Test-Path (Join-Path $Ror2 'BepInEx\core\BepInEx.dll')) {
    Write-Host 'BepInEx уже установлен.'
} else {
    Write-Host "Скачиваю BepInEx 5.4.21 (x64) с GitHub..."
    $zip = Join-Path $env:TEMP 'BepInEx_x64_5.4.21.0.zip'
    Invoke-WebRequest $BepInExUrl -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $Ror2 -Force
    Remove-Item $zip -Force
    Write-Host 'BepInEx установлен.'
}

# 6. Плагин: сначала удаляем все старые версии, потом копируем новую
Step 'Удаляю старые версии мода'
$PluginsRoot = Join-Path $Ror2 'BepInEx\plugins'
$PluginDir = Join-Path $PluginsRoot 'DeadlockSurvivors'
$removed = 0
if (Test-Path $PluginsRoot) {
    # Любые копии DeadlockSurvivors*.dll/.pdb в plugins (в т.ч. положенные вручную или переименованные)
    $old = Get-ChildItem $PluginsRoot -Recurse -File -Include 'DeadlockSurvivors*.dll', 'DeadlockSurvivors*.pdb', 'DeadlockSurvivors*.old' -ErrorAction SilentlyContinue
    foreach ($f in $old) {
        $ver = try { [Diagnostics.FileVersionInfo]::GetVersionInfo($f.FullName).FileVersion } catch { '?' }
        Write-Host "  удаляю: $($f.FullName) (версия $ver)"
        Remove-Item $f.FullName -Force
        $removed++
    }
}
if (Test-Path $PluginDir) { Remove-Item $PluginDir -Recurse -Force }
if ($removed -eq 0) { Write-Host '  старых версий не найдено.' } else { Write-Host "  удалено файлов: $removed" }

Step 'Копирую плагин'
New-Item -ItemType Directory -Force -Path $PluginDir | Out-Null
Copy-Item $Dll $PluginDir -Force
$NewVer = [Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $PluginDir 'DeadlockSurvivors.dll')).FileVersion
Write-Host "Плагин: $PluginDir\DeadlockSurvivors.dll (версия $NewVer)"

# 7. Путь к Deadlock в конфиг BepInEx
if ($Deadlock) {
    Step 'Записываю путь к Deadlock в настройки'
    $CfgDir = Join-Path $Ror2 'BepInEx\config'
    New-Item -ItemType Directory -Force -Path $CfgDir | Out-Null
    $Cfg = Join-Path $CfgDir "$PluginGuid.cfg"
    $line = "DeadlockFolder = $Deadlock"
    if ((Test-Path $Cfg) -and ((Get-Content $Cfg -Raw) -match '(?m)^DeadlockFolder\s*=')) {
        $text = [regex]::Replace((Get-Content $Cfg -Raw), '(?m)^DeadlockFolder\s*=[^\r\n]*', { param($m) $line })
    } else {
        $text = "[General]`r`n`r`n## Папка установки Deadlock`r`n# Setting type: String`r`n# Default value: `r`n$line`r`n"
    }
    [IO.File]::WriteAllText($Cfg, $text, (New-Object Text.UTF8Encoding($false)))
    Write-Host "Настройки: $Cfg"
}

Step 'Готово'
Write-Host 'Запустите Risk of Rain 2 через Steam.'
Write-Host 'Проверка: в BepInEx\LogOutput.log ищите строки с меткой "[DS " (Ctrl+F),'
Write-Host "  или откройте отдельный лог мода: $PluginDir\DeadlockSurvivors.log"
Write-Host 'Героев Deadlock этот плагин пока НЕ добавляет - он только находит файлы игры.' -ForegroundColor Yellow
