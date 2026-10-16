# Deadlock Survivors - выгрузка героев из ВАШЕЙ копии Deadlock (только на этом ПК).
# Модели+анимации+материалы -> .glb, звуки -> .wav/.mp3, данные героев/способностей -> текст.
# Ничего из Deadlock не отправляется в интернет и не кладётся в репозиторий (папка в .gitignore).
param(
    [string]$Heroes = '',          # через запятую, напр. "haze,inferno". Пусто = все найденные
    [switch]$ListOnly              # только найти героев и написать отчёт, без выгрузки
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$ToolsDir = Join-Path $Root '.tools'
$OutDir = Join-Path $Root 'deadlock_extracted'
$CliVersion = '20.1'
$CliUrl = "https://github.com/ValveResourceFormat/ValveResourceFormat/releases/download/$CliVersion/cli-windows-x64.zip"
$CliSha256 = '67aaf8a67a85ca60fd09ff343e62103a4cdf3a2d177fc656231d7d734c5b3aa3'

function Step($t) { Write-Host ''; Write-Host "== $t" -ForegroundColor Cyan }
function Fail($t) { Write-Host ''; Write-Host "ОШИБКА: $t" -ForegroundColor Red; exit 1 }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 1. Source2Viewer-CLI (ValveResourceFormat, MIT) в .tools
Step "Проверяю Source2Viewer-CLI $CliVersion"
$CliDir = Join-Path $ToolsDir "s2v-$CliVersion"
$Cli = Join-Path $CliDir 'Source2Viewer-CLI.exe'
if (-not (Test-Path $Cli)) {
    # старые версии утилиты удаляем
    Get-ChildItem $ToolsDir -Directory -Filter 's2v-*' -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
    New-Item -ItemType Directory -Force -Path $CliDir | Out-Null
    $zip = Join-Path $ToolsDir 's2v.zip'
    Write-Host 'Скачиваю с GitHub (~50 МБ, один раз)...'
    Invoke-WebRequest $CliUrl -OutFile $zip -UseBasicParsing
    $hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
    if ($hash -ne $CliSha256) { Remove-Item $zip -Force; Fail "контрольная сумма не совпала ($hash). Файл удалён." }
    Expand-Archive $zip -DestinationPath $CliDir -Force
    Remove-Item $zip -Force
}
Write-Host "CLI: $Cli"

# 2. Папка Deadlock
Step 'Ищу Deadlock'
$Deadlock = $null
$libs = New-Object System.Collections.Generic.List[string]
foreach ($k in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam') {
    $p = Get-ItemProperty $k -ErrorAction SilentlyContinue
    $s = if ($p.SteamPath) { $p.SteamPath } elseif ($p.InstallPath) { $p.InstallPath } else { $null }
    if ($s) {
        $libs.Add(($s -replace '/', '\'))
        $vdf = Join-Path $s 'steamapps\libraryfolders.vdf'
        if (Test-Path $vdf) {
            foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $libs.Add(($m.Groups[1].Value -replace '\\\\', '\'))
            }
        }
        break
    }
}
foreach ($l in ($libs | Select-Object -Unique)) {
    $c = Join-Path $l 'steamapps\common\Deadlock'
    if (Test-Path (Join-Path $c 'game\citadel\pak01_dir.vpk')) { $Deadlock = $c; break }
}
if (-not $Deadlock) {
    $Deadlock = Read-Host 'Deadlock не найден. Вставьте путь к папке игры (где лежит папка "game")'
}
$Vpk = Join-Path $Deadlock 'game\citadel\pak01_dir.vpk'
if (-not (Test-Path $Vpk)) { Fail "не найден $Vpk" }
Write-Host "VPK: $Vpk"

# 3. Список файлов VPK и поиск героев
Step 'Читаю список файлов Deadlock (может занять минуту)'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$ListFile = Join-Path $OutDir 'vpk_list.txt'
$ErrorActionPreference = 'Continue'
& $Cli -i $Vpk --vpk_list 2>$null | Set-Content -Path $ListFile -Encoding UTF8
$code = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($code -ne 0) { Fail 'CLI не смог прочитать VPK.' }
$all = Get-Content $ListFile | ForEach-Object { ($_ -split ' CRC:')[0] } | Where-Object { $_ }
Write-Host "Файлов в VPK: $($all.Count)"

# Папки героев: models/heroes*/<имя>/... (точная структура зависит от патча - поэтому ищем, а не зашиваем)
$heroRx = '^models/(heroes[^/]*)/([^/]+)/'
$skip = @('shared', 'common', 'materials', 'textures', 'animation', 'animations', 'test', 'dev')
$found = @{}
$heroFiles = @{}
$sounds = @($all | Where-Object { $_.EndsWith('.vsnd_c') })
foreach ($f in $all) {
    $m = [regex]::Match($f, $heroRx)
    if ($m.Success) {
        $name = $m.Groups[2].Value
        if ($skip -contains $name) { continue }
        if (-not $found.ContainsKey($name)) {
            $found[$name] = New-Object System.Collections.Generic.HashSet[string]
            $heroFiles[$name] = New-Object System.Collections.Generic.List[string]
        }
        [void]$found[$name].Add("models/$($m.Groups[1].Value)/$name/")
        $heroFiles[$name].Add($f)
    }
}
function Hero-Sounds($n) { $rx = "(^|/|_)$([regex]::Escape($n))(/|_|\.)"; $sounds | Where-Object { $_ -match $rx } }
$names = $found.Keys | Sort-Object
Write-Host "Найдено папок героев: $($names.Count)"
Write-Host ('  ' + ($names -join ', '))

if ($Heroes) {
    $want = $Heroes.Split(',') | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ }
    $names = $names | Where-Object { $want -contains $_.ToLower() }
}

# Отчёт (только пути и количества - его можно прислать разработчику)
$Report = Join-Path $OutDir 'report.txt'
$r = New-Object System.Collections.Generic.List[string]
$r.Add("Deadlock Survivors extract report | $(Get-Date -Format 'yyyy-MM-dd HH:mm') | CLI $CliVersion")
$r.Add("VPK files: $($all.Count)")
foreach ($n in ($found.Keys | Sort-Object)) {
    $pref = @($found[$n])
    $files = $heroFiles[$n]
    $mdl = @($files | Where-Object { $_.EndsWith('.vmdl_c') })
    $snd = @(Hero-Sounds $n)
    $r.Add("")
    $r.Add("[$n] folders: $($pref -join ' ; ') | files: $($files.Count) | models: $($mdl.Count) | sounds(match): $($snd.Count)")
    foreach ($x in ($mdl | Select-Object -First 15)) { $r.Add("  mdl $x") }
    foreach ($x in ($snd | Select-Object -First 5)) { $r.Add("  snd $x") }
}
$r.Add("")
$r.Add("Hero/ability data files:")
foreach ($x in ($all | Where-Object { $_ -match '^scripts/.*(hero|abilit).*\.vdata_c$' })) { $r.Add("  $x") }
$r | Set-Content -Path $Report -Encoding UTF8
Write-Host "Отчёт: $Report"

if ($ListOnly) { Step 'Готово (только отчёт)'; exit 0 }

# 4. Выгрузка. Старая выгрузка героя удаляется перед новой.
$errors = 0
function Run-Cli([string[]]$cliArgs, [string]$logName) {
    $log = Join-Path $OutDir "logs\$logName.log"
    New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
    Push-Location (Split-Path $log)
    # в Windows PowerShell 5.1 stderr внешней программы при 'Stop' роняет скрипт - поэтому Continue
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try { & $Cli @cliArgs *> $log } finally { $ErrorActionPreference = $old; Pop-Location }
    if ($LASTEXITCODE -ne 0) { $script:errors++; Write-Host "  ! ошибка, см. $log" -ForegroundColor Yellow }
}

Step 'Выгружаю данные героев и способностей (scripts/*.vdata)'
Run-Cli @('-i', $Vpk, '-o', (Join-Path $OutDir 'data'), '-d', '-e', 'vdata_c', '-f', 'scripts/') 'data'

$i = 0
foreach ($n in $names) {
    $i++
    Step "[$i/$($names.Count)] Герой: $n"
    $heroOut = Join-Path $OutDir "heroes\$n"
    if (Test-Path $heroOut) { Remove-Item $heroOut -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $heroOut | Out-Null
    $filter = (@($found[$n]) -join ',')

    Write-Host '  модели + анимации + материалы -> .glb'
    Run-Cli @('-i', $Vpk, '-o', (Join-Path $heroOut 'models'), '-d', '-e', 'vmdl_c', '-f', $filter,
        '--gltf_export_format', 'glb', '--gltf_export_animations', '--gltf_export_materials', '--gltf_textures_adapt') "$n.models"

    # звуки: папки, где лежат vsnd_c с именем героя в пути
    $sndDirs = Hero-Sounds $n |
        ForEach-Object { $_.Substring(0, $_.LastIndexOf('/') + 1) } | Sort-Object -Unique
    if ($sndDirs) {
        Write-Host "  звуки ($(@($sndDirs).Count) папок) -> .wav/.mp3"
        # фильтр по префиксу папки; режем на части, чтобы не упереться в длину командной строки
        $chunk = New-Object System.Collections.Generic.List[string]; $k = 0
        foreach ($d in $sndDirs) {
            $chunk.Add($d)
            if (($chunk -join ',').Length -gt 6000) { $k++; Run-Cli @('-i', $Vpk, '-o', (Join-Path $heroOut 'sounds'), '-d', '-e', 'vsnd_c', '-f', ($chunk -join ',')) "$n.sounds$k"; $chunk.Clear() }
        }
        if ($chunk.Count) { $k++; Run-Cli @('-i', $Vpk, '-o', (Join-Path $heroOut 'sounds'), '-d', '-e', 'vsnd_c', '-f', ($chunk -join ',')) "$n.sounds$k" }
    } else { Write-Host '  звуки по имени не найдены (имя в звуках может отличаться)' -ForegroundColor Yellow }

    $glb = @(Get-ChildItem $heroOut -Recurse -Filter *.glb -ErrorAction SilentlyContinue).Count
    $wav = @(Get-ChildItem $heroOut -Recurse -Include *.wav, *.mp3 -ErrorAction SilentlyContinue).Count
    $mb = [math]::Round(((Get-ChildItem $heroOut -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum) / 1MB, 1)
    Write-Host "  итог: glb=$glb, звуков=$wav, $mb МБ"
    Add-Content -Path $Report -Encoding UTF8 -Value "RESULT [$n] glb=$glb sounds=$wav size_mb=$mb"
}

Step 'Готово'
Write-Host "Всё лежит в: $OutDir"
Write-Host "Пришлите разработчику ТОЛЬКО файл report.txt (там пути и количества, без контента Valve)."
Write-Host 'Сами модели/звуки никуда не выкладывайте - это файлы Valve.' -ForegroundColor Yellow
if ($errors) { Write-Host "Были ошибки: $errors. Логи: $OutDir\logs" -ForegroundColor Yellow }
