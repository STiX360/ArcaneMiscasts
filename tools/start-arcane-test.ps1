param(
    [string]$Engine = 'C:\Modlists\POTI\.OpenMW\openmw.exe',
    [string]$GameData = 'D:\Steam\steamapps\common\Morrowind\Data Files',
    [switch]$PrepareOnly,
    [switch]$SmokeTest
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$name = if ($SmokeTest) { 'arcane-misfires-smoke' } else { 'arcane-misfires-manual' }
$profile = Join-Path $root ".runtime\$name-profile"
$userData = Join-Path $root ".runtime\$name-user-data"
$mod = Join-Path $root 'Arcane Misfires'
$fixture = Join-Path $root 'tests\arcane_manual'
$resources = Join-Path (Split-Path -Parent $Engine) 'resources'
if (-not (Test-Path -LiteralPath $Engine -PathType Leaf)) { throw "Missing engine: $Engine" }
$version = (Get-Content -LiteralPath (Join-Path $resources 'version') -TotalCount 1).Trim()
if ($version -notmatch '^0\.52\.') { throw "Use the tested OpenMW 0.52 build, not $version. Override -Engine if needed." }
foreach ($file in @('Morrowind.esm','Tribunal.esm','Bloodmoon.esm','Morrowind.bsa','Tribunal.bsa','Bloodmoon.bsa')) {
    if (-not (Test-Path -LiteralPath (Join-Path $GameData $file) -PathType Leaf)) { throw "Missing game file: $file" }
}
foreach ($path in @((Join-Path $mod 'ArcaneMisfires.esp'), (Join-Path $mod 'ArcaneMisfires.omwscripts'),
    (Join-Path $fixture 'ArcaneMisfiresTest.esp'), (Join-Path $fixture 'ArcaneMisfiresTest.omwscripts'))) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing test content: $path" }
}
$localData = Join-Path $userData 'data'
New-Item -ItemType Directory -Force -Path $profile,$userData,$localData | Out-Null
$smokeContent = if ($SmokeTest) { 'content=ArcaneMisfiresTestSmoke.omwscripts' } else { '' }
$config = @"
replace=config
replace=data
replace=content
replace=groundcover
replace=fallback-archive
data="$($resources.Replace('\','/'))/vfs-mw"
data="$($GameData.Replace('\','/'))"
data="$($mod.Replace('\','/'))"
data="$($fixture.Replace('\','/'))"
data-local="$($localData.Replace('\','/'))"
resources="$($resources.Replace('\','/'))"
content=Morrowind.esm
content=Tribunal.esm
content=Bloodmoon.esm
content=ArcaneMisfires.esp
content=ArcaneMisfiresTest.esp
content=ArcaneMisfires.omwscripts
content=ArcaneMisfiresTest.omwscripts
$smokeContent
fallback-archive=Morrowind.bsa
fallback-archive=Tribunal.bsa
fallback-archive=Bloodmoon.bsa
"@
[IO.File]::WriteAllText((Join-Path $profile 'openmw.cfg'), $config)
$settingsPath = Join-Path $profile 'settings.cfg'
if ($SmokeTest -or -not (Test-Path -LiteralPath $settingsPath)) {
    $volume = if ($SmokeTest) { 'master volume = 0' } else { 'master volume = 1' }
    [IO.File]::WriteAllText($settingsPath, @"
[Video]
resolution x = 1280
resolution y = 720
fullscreen = false
vsync = false

[Sound]
music volume = 0
$volume
"@)
}
$arguments = @('--replace','config','--config',('"'+$profile+'"'),
    '--user-data',('"'+$userData+'"'),'--skip-menu','--new-game=0','--start','"Seyda Neen"','--no-grab')
Write-Host "OpenMW $version; isolated profile: $profile"
Write-Host "Test saves: $userData"
if ($PrepareOnly) { return }
if ($SmokeTest) {
    $process = Start-Process -FilePath $Engine -ArgumentList $arguments -WorkingDirectory (Split-Path -Parent $Engine) -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(60000)) {
        $process.Kill()
        $process.WaitForExit()
        throw "Test timed out. See $profile\openmw.log"
    }
    $log = Get-Content -LiteralPath (Join-Path $profile 'openmw.log') -Raw
    if ($process.ExitCode -ne 0 -or $log -notmatch 'AMF_MANUAL_PASS' -or $log -match 'AMF_MANUAL_FAIL| E\]') {
        throw "Manual fixture smoke test failed. See $profile\openmw.log"
    }
    Write-Host 'AMF_MANUAL_PASS: test spells, settings, resources and casting stance verified.'
} else {
    Start-Process -FilePath $Engine -ArgumentList $arguments -WorkingDirectory (Split-Path -Parent $Engine) -WindowStyle Normal
}
