<#
=====================================================================================
  apps.ps1  -  Instala os programas basicos de um PC de jogos via winget
=====================================================================================
  Rode DEPOIS de conectar a internet (o winget baixa da fonte oficial de cada app):
      powershell -ExecutionPolicy Bypass -File C:\Windows\Setup\Scripts\apps.ps1

  Edite a lista $Apps. Para descobrir o ID de um programa:  winget search "nome"
=====================================================================================
#>
$Apps = @(
    # --- essenciais ---
    'abbodi1406.vcredist'            # todos os Visual C++ Redistributable (2005-2022) de uma vez
    'Microsoft.DirectX'              # DirectX End-User Runtime (DX9 p/ jogos antigos)
    '7zip.7zip'
    # --- lojas / launchers ---
    'Valve.Steam'
    # 'EpicGames.EpicGamesLauncher'
    # 'ElectronicArts.EADesktop'
    # 'Ubisoft.Connect'
    # 'GOG.Galaxy'
    # 'Blizzard.BattleNet'
    # --- comunicacao / navegador ---
    'Discord.Discord'
    # 'Mozilla.Firefox'
    # 'Brave.Brave'
    # 'Google.Chrome'
    # --- monitoramento / overclock ---
    # 'Guru3D.Afterburner'           # MSI Afterburner
    # 'Guru3D.RTSS'                  # RivaTuner (overlay de FPS)
    # 'TechPowerUp.GPU-Z'
    # 'CPUID.HWMonitor'
    # 'Rem0o.FanControl'
    # --- utilidades ---
    # 'Microsoft.PowerToys'
    # 'VideoLAN.VLC'
    # 'OBSProject.OBSStudio'
)

# Gaming Services (obrigatorio para jogos do Game Pass / Xbox app). Instala da Microsoft Store.
$InstallGamingServices = $true

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Start-Process powershell.exe -Verb RunAs -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`""); exit }

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget nao encontrado. Abra a Microsoft Store, atualize o 'Instalador de Aplicativo' (App Installer) e rode de novo." -ForegroundColor Yellow
    Write-Host "Ou: https://aka.ms/getwinget" -ForegroundColor Yellow
    exit 1
}

# aceita os termos das fontes uma vez
& winget source update | Out-Null

foreach ($id in $Apps) {
    Write-Host "`n==> $id" -ForegroundColor Cyan
    & winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements
}

if ($InstallGamingServices) {
    Write-Host "`n==> Gaming Services (Microsoft Store)" -ForegroundColor Cyan
    & winget install --id 9MWPM2CQNLHN --source msstore --accept-package-agreements --accept-source-agreements
}

Write-Host @"

Pronto. Falta instalar o driver da GPU direto do fabricante:
  NVIDIA: https://www.nvidia.com/drivers      (app NVIDIA ou instalacao "personalizada" sem GeForce Experience)
  AMD:    https://www.amd.com/support         (Adrenalin)
  Intel:  https://www.intel.com/content/www/us/en/download-center/home.html
E o chipset da placa-mae (site do fabricante: ASUS, MSI, Gigabyte, ASRock...).
"@ -ForegroundColor Green
