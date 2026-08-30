param(
    [Parameter(Position = 0)] [string]$World,
    [switch]$Fast,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Find-World([string]$Path) {
    if (-not $Path) {
        $Path = (Read-Host 'Drop a .vrcw file or folder here (blank = search current directory)').Trim()
        if (-not $Path) { $Path = (Get-Location).Path }
    }

    $Path = $Path.Trim('"')
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        if ([IO.Path]::GetExtension($Path) -ne '.vrcw') { throw 'Please drop a .vrcw file.' }
        return (Resolve-Path -LiteralPath $Path).Path
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { throw "Path not found: $Path" }

    $file = Get-ChildItem -LiteralPath $Path -Filter '*.vrcw' -File -Recurse |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $file) { throw "No .vrcw file found under: $Path" }
    return $file.FullName
}

function Find-VRChat {
    $libraries = @()
    if ($env:VRCHAT_PATH) { $libraries += $env:VRCHAT_PATH }

    try { $libraries += (Get-ItemProperty 'HKCU:\Software\Valve\Steam').SteamPath } catch {}
    $libraries += "${env:ProgramFiles(x86)}\Steam"

    foreach ($root in @($libraries)) {
        if (-not $root) { continue }
        if (Test-Path -LiteralPath $root -PathType Leaf) { return (Resolve-Path $root).Path }
        if (Test-Path -LiteralPath (Join-Path $root 'VRChat.exe')) {
            return (Resolve-Path (Join-Path $root 'VRChat.exe')).Path
        }

        $allLibraries = @($root)
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            $allLibraries += Get-Content -LiteralPath $vdf | ForEach-Object {
                if ($_ -match '^\s*"path"\s+"(.+)"') { $Matches[1] -replace '\\\\', '\' }
            }
        }
        foreach ($library in $allLibraries) {
            $exe = Join-Path $library 'steamapps\common\VRChat\VRChat.exe'
            if (Test-Path -LiteralPath $exe) { return (Resolve-Path $exe).Path }
        }
    }

    $manual = (Read-Host 'VRChat was not found. Drop VRChat.exe here and press Enter').Trim().Trim('"')
    if (Test-Path -LiteralPath $manual -PathType Container) { $manual = Join-Path $manual 'VRChat.exe' }
    if (-not (Test-Path -LiteralPath $manual -PathType Leaf)) { throw 'VRChat.exe not found.' }
    return (Resolve-Path $manual).Path
}

Write-Host 'VRChat Any Local Test'
$worldPath = Find-World $World
$gameExe = Find-VRChat
$roomId = (Get-Random -Minimum 1 -Maximum 10).ToString() +
    (-join (1..9 | ForEach-Object { Get-Random -Minimum 0 -Maximum 10 }))

if ($Fast) {
    $clients = 1
    $useVR = $false
} else {
    $answer = (Read-Host 'Client count (default 1)').Trim()
    if (-not $answer) { $answer = '1' }
    if ($answer -notmatch '^\d+$' -or [int]$answer -lt 1) { throw 'Client count must be a positive number.' }
    $clients = [int]$answer

    $answer = (Read-Host 'Launch in VR mode? (y/N)').Trim()
    if ($answer -notmatch '^(|y|yes|n|no)$') { throw 'Please answer y or n.' }
    $useVR = $answer -match '^(y|yes)$'
}

$worldUri = ([Uri]::new($worldPath)).AbsoluteUri
$arguments = @(
    "--url=create?roomId=$roomId&hidden=true&name=BuildAndRun&url=$worldUri",
    '--enable-debug-gui', '--enable-sdk-log-levels', '--enable-udon-debug-logging', '--watch-worlds'
)
if (-not $useVR) { $arguments += '--no-vr' }

Write-Host "World  : $worldPath"
Write-Host "VRChat : $gameExe"
Write-Host "Room   : $roomId (random)"
Write-Host "Clients: $clients"
Write-Host ('Mode   : ' + $(if ($useVR) { 'VR' } else { 'Desktop' }))

1..$clients | ForEach-Object {
    if ($DryRun) {
        Write-Host ('DRY RUN: "{0}" {1}' -f $gameExe, ($arguments -join ' '))
    } else {
        Start-Process -FilePath $gameExe -WorkingDirectory (Split-Path $gameExe) -ArgumentList $arguments
    }
}
