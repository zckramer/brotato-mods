# -------- config you might change --------
$ModName     = "Calico-ReloadUI"
$PresetName  = "Windows Desktop"
$InstallMode = "unpacked"   # "unpacked" or "pck"
$GodotExe    = "D:\Games Library\Godot_v3.6.2-stable_mono_win64\Godot_v3.6.2-stable_mono_win64.exe"
# ----------------------------------------

$ErrorActionPreference = "Stop"
function Ensure-Dir($p){if(-not(Test-Path $p)){New-Item -ItemType Directory -Path $p|Out-Null}}
function Norm([string]$p){[IO.Path]::GetFullPath($p.TrimEnd('\','/'))}

# Detect Steam folder from script location (if run from game dir)
$ScriptDir = Split-Path -LiteralPath $MyInvocation.MyCommand.Path
if(Test-Path (Join-Path $ScriptDir "Brotato.exe")){$SteamBrotato=$ScriptDir}else{$SteamBrotato="D:\Games Library\steamapps\common\Brotato"}

# Prefer dev copy inside Steam\mods-unpacked\<ModName>
$ProjectDirCandidates = @(
  (Join-Path $SteamBrotato ("mods-unpacked\"+$ModName)),
  (Join-Path $SteamBrotato ("mods\"+$ModName)),
  (Join-Path $ScriptDir   ("mods-unpacked\"+$ModName)),
  (Join-Path $ScriptDir   ("mods\"+$ModName))
)
$ProjectDir = $ProjectDirCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if(-not $ProjectDir){ $ProjectDir = "D:\BrotatoMods\Calico-ReloadUI" }  # fallback

Write-Host "==> Calico one-click started" -ForegroundColor Cyan
Write-Host "Steam folder: $SteamBrotato"
Write-Host "Project dir: $ProjectDir"

if(-not(Test-Path $SteamBrotato)){throw "Brotato Steam folder not found: $SteamBrotato"}
if(-not(Test-Path $ProjectDir)){throw "Project dir not found: $ProjectDir"}

$ModsDir      = Join-Path $SteamBrotato "mods"
$ModsUnpacked = Join-Path $SteamBrotato "mods-unpacked"
$TargetPck    = Join-Path $ModsDir      $ModName
$TargetUnp    = Join-Path $ModsUnpacked $ModName

$ProjectDirN = Norm $ProjectDir
$TargetUnpN  = Norm $TargetUnp

# Build dir/PCK output
$BuildDir = Join-Path $ProjectDir "build"
$PckOut   = Join-Path $BuildDir   ($ModName + ".pck")

if($InstallMode -eq "pck"){
  if(-not(Test-Path $GodotExe)){throw "Godot exe not found: $GodotExe"}
  Ensure-Dir $BuildDir
  Write-Host "==> Exporting PCK via Godot..." -ForegroundColor Yellow
  & $GodotExe --path "$ProjectDir" --export-pack "$PresetName" "$PckOut"
  if($LASTEXITCODE -ne 0 -or -not(Test-Path $PckOut)){throw "PCK export failed (check preset name and export filters)."}
}

switch($InstallMode){
  "unpacked"{
    Ensure-Dir $TargetUnp
    # write/refresh manifest
    $manifest = @{
      name        = $ModName
      id          = "calico_reload_ui"
      version     = "1.0.0"
      author      = "zckra"
      description = "Weapon reload/cooldown overlay."
      script      = "mod_main.gd"
    } | ConvertTo-Json -Depth 4
    Set-Content (Join-Path $TargetUnp "manifest.json") $manifest -Encoding UTF8

    if($ProjectDirN -ne $TargetUnpN){
      # only copy when source != target
      if(Test-Path (Join-Path $ProjectDir "mod_main.gd")){
        Copy-Item (Join-Path $ProjectDir "mod_main.gd") (Join-Path $TargetUnp "mod_main.gd") -Force
      }
      if(Test-Path (Join-Path $ProjectDir "ui")){
        Ensure-Dir (Join-Path $TargetUnp "ui")
        Copy-Item (Join-Path $ProjectDir "ui\*") (Join-Path $TargetUnp "ui") -Recurse -Force
      }
    } else {
      Write-Host "Source and target are the same folder; skipping file copy (this is fine)." -ForegroundColor DarkYellow
    }
    Write-Host "==> Installed UNPACKED mod to: $TargetUnp" -ForegroundColor Green
  }
  "pck"{
    Ensure-Dir $TargetPck
    $manifest = @{
      name        = $ModName
      id          = "calico_reload_ui"
      version     = "1.0.0"
      author      = "zckra"
      description = "Weapon reload/cooldown overlay."
      script      = "mod_main.gd"
      mod_packs   = @("$ModName.pck")
    } | ConvertTo-Json -Depth 4
    Set-Content (Join-Path $TargetPck "manifest.json") $manifest -Encoding UTF8
    Copy-Item $PckOut (Join-Path $TargetPck ($ModName + ".pck")) -Force
    if(Test-Path (Join-Path $ProjectDir "mod_main.gd")){
      Copy-Item (Join-Path $ProjectDir "mod_main.gd") (Join-Path $TargetPck "mod_main.gd") -Force
    }
    Write-Host "==> Installed PCK mod to: $TargetPck" -ForegroundColor Green
  }
  default{ throw "Unknown InstallMode '$InstallMode' (use 'unpacked' or 'pck')" }
}

Write-Host "==> Done. Launch Brotato → Mods." -ForegroundColor Cyan
