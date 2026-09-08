<#
=====================================================================================
  build-iso.ps1  -  Monta a SUA ISO do Windows 11 para jogos a partir da ISO OFICIAL
=====================================================================================
  O que este script faz (tudo OFFLINE, sem instalar nada no seu PC atual):
    1. Extrai a ISO oficial da Microsoft para uma pasta de trabalho
    2. Exporta somente a edicao escolhida (ex.: "Windows 11 Pro") do install.wim/esd
    3. Monta o install.wim e REMOVE os apps pre-instalados (bloatware) da lista abaixo
    4. Aplica politicas de registro OFFLINE (telemetria, apps promovidos, Chat/Teams,
       Copilot/Recall, OneDrive) para que nada disso rode nem no primeiro boot
    5. (Opcional) integra drivers (.inf) na imagem  ->  -DriversPath
    6. Copia autounattend.xml + scripts pos-instalacao (freedom-tweaks.ps1, apps.ps1,
       verify.ps1) para dentro da midia
    7. Gera a ISO final com oscdimg.exe (Windows ADK)

  Requisitos:
    - Windows 10/11 x64, PowerShell 5.1 (o padrao), rodando COMO ADMINISTRADOR
    - ISO oficial baixada de https://www.microsoft.com/software-download/windows11
    - ~25 GB livres em $WorkDir
    - oscdimg.exe: instale o "Windows ADK" (somente o componente "Deployment Tools")
      https://learn.microsoft.com/windows-hardware/get-started/adk-install
      ou copie o oscdimg.exe para a mesma pasta deste script.

  Uso:
    .\build-iso.ps1 -IsoPath "D:\ISOs\Win11_24H2_BrazilianPortuguese_x64.iso"
    .\build-iso.ps1 -IsoPath "..." -Edition "Windows 11 Home" -DriversPath "D:\drivers"
    .\build-iso.ps1 -IsoPath "..." -RemoveXbox        # remove tambem Xbox app / Game Bar

  Teste a ISO numa VM (Hyper-V ou VirtualBox com TPM 2.0) ANTES de usar no PC real.
=====================================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$IsoPath,

    # Nome exato da edicao dentro do install.wim (o script lista as disponiveis se errar)
    [string]$Edition = "Windows 11 Pro",

    # Pasta de trabalho (evite espacos no caminho por causa do oscdimg)
    [string]$WorkDir = "C:\WinGamingBuild",

    # Caminho da ISO final (padrao: $WorkDir\CleanWindows.iso)
    [string]$OutputIso = "",

    # Pasta com drivers .inf para integrar (ex.: chipset, LAN, NVMe). Opcional.
    [string]$DriversPath = "",

    # Remove tambem Xbox app, Game Bar, Xbox Identity Provider.
    # NAO use se voce usa Game Pass PC ou controle Xbox sem fio (precisa do Gaming Services).
    [switch]$RemoveXbox
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "    $msg" -ForegroundColor Green }

# ---------------------------------------------------------------------------------
# LISTA DE APPS PRE-INSTALADOS QUE SERAO REMOVIDOS DA IMAGEM
# Edite a vontade. Nomes que nao existirem na sua ISO sao simplesmente ignorados.
# O que fica de proposito: Loja (Store), App Installer (winget), Calculadora, Bloco de
# Notas, Terminal, Paint, Fotos, Ferramenta de Captura, Seguranca do Windows,
# extensoes de codec (HEIF/AV1/VP9/WebP), Camera, e as bibliotecas VCLibs/UI.Xaml.
# ---------------------------------------------------------------------------------
$RemoveApps = @(
    'Clipchamp.Clipchamp'                       # editor de video
    'Microsoft.549981C3F5F10'                   # Cortana (ISOs antigas)
    'Microsoft.BingNews'
    'Microsoft.BingSearch'
    'Microsoft.BingWeather'
    'Microsoft.Copilot'
    'Microsoft.Windows.Ai.Copilot.Provider'
    'Microsoft.Edge.GameAssist'                 # navegador Edge dentro da Game Bar
    'Microsoft.GetHelp'
    'Microsoft.Getstarted'                      # Dicas
    'Microsoft.MicrosoftOfficeHub'              # anuncio do Office
    'Microsoft.MicrosoftSolitaireCollection'
    'Microsoft.MicrosoftStickyNotes'
    'Microsoft.OutlookForWindows'
    'Microsoft.People'
    'Microsoft.PowerAutomateDesktop'
    'Microsoft.Todos'
    'Microsoft.Windows.DevHome'
    'Microsoft.WindowsAlarms'
    'Microsoft.WindowsFeedbackHub'
    'Microsoft.WindowsMaps'
    'Microsoft.WindowsSoundRecorder'
    'Microsoft.YourPhone'                       # Vincular ao Celular
    'Microsoft.ZuneMusic'                       # Media Player
    'Microsoft.ZuneVideo'                       # Filmes e TV
    'MicrosoftCorporationII.QuickAssist'
    'MicrosoftCorporationII.MicrosoftFamily'
    'microsoft.windowscommunicationsapps'       # Mail e Calendario (antigo)
    'MicrosoftWindows.Client.WebExperience'     # Widgets
    'MicrosoftWindows.CrossDevice'
    'MSTeams'
    'Microsoft.MixedReality.Portal'
    'Microsoft.Microsoft3DViewer'
    'Microsoft.Print3D'
    'Microsoft.Wallet'
    'Microsoft.Messaging'
    'Microsoft.OneConnect'
    'Microsoft.SkypeApp'
    'Microsoft.Office.OneNote'
    'Microsoft.LinkedIn'
)
$XboxApps = @(
    'Microsoft.GamingApp'                       # Xbox app (Game Pass)
    'Microsoft.Xbox.TCUI'
    'Microsoft.XboxGameOverlay'
    'Microsoft.XboxGamingOverlay'               # Game Bar (Win+G)
    'Microsoft.XboxIdentityProvider'            # login Xbox (Game Pass, Minecraft, Forza...)
    'Microsoft.XboxSpeechToTextOverlay'
)
if ($RemoveXbox) { $RemoveApps += $XboxApps }

# ---------------------------------------------------------------------------------
# 0. Pre-checagens
# ---------------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw "Execute o PowerShell como Administrador." }
if (-not (Test-Path $IsoPath)) { throw "ISO nao encontrada: $IsoPath" }
if ($WorkDir -match '\s') { Write-Warning "WorkDir contem espacos; o oscdimg pode falhar. Prefira algo como C:\WinGamingBuild" }

foreach ($f in 'autounattend.xml', 'freedom-tweaks.ps1', 'freedom-watch.ps1', 'freedom-restore.ps1', 'apps.ps1', 'verify.ps1') {
    if (-not (Test-Path (Join-Path $ScriptDir $f))) { throw "Arquivo do kit nao encontrado ao lado do script: $f" }
}

$oscdimg = Join-Path $ScriptDir 'oscdimg.exe'
if (-not (Test-Path $oscdimg)) {
    $adk = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
    if (Test-Path $adk) { $oscdimg = $adk } else { $oscdimg = $null }
}
if (-not $oscdimg) {
    Write-Warning "oscdimg.exe nao encontrado. A pasta da midia sera gerada, mas a ISO nao."
    Write-Warning "Instale o Windows ADK (Deployment Tools) ou copie oscdimg.exe para $ScriptDir e rode de novo,"
    Write-Warning "ou grave a pasta $WorkDir\iso num pendrive com o Rufus (veja README, secao 'Sem oscdimg')."
}

# ---------------------------------------------------------------------------------
# 1. Pastas de trabalho
# ---------------------------------------------------------------------------------
Step "Preparando pasta de trabalho em $WorkDir"
$Src   = Join-Path $WorkDir 'iso'     # conteudo da midia
$Mount = Join-Path $WorkDir 'mount'   # ponto de montagem do install.wim
$Tmp   = Join-Path $WorkDir 'tmp'

if (Test-Path $Mount) {
    # Se sobrou uma montagem de execucao anterior, descarta
    try { Dismount-WindowsImage -Path $Mount -Discard -ErrorAction Stop | Out-Null } catch {}
    try { Clear-WindowsCorruptMountPoint | Out-Null } catch {}
}
foreach ($d in $Src, $Tmp) { if (Test-Path $d) { Remove-Item $d -Recurse -Force } }
foreach ($d in $Src, $Mount, $Tmp) { New-Item -ItemType Directory -Force -Path $d | Out-Null }

# ---------------------------------------------------------------------------------
# 2. Extrair a ISO original
# ---------------------------------------------------------------------------------
Step "Montando e copiando a ISO original"
Mount-DiskImage -ImagePath $IsoPath | Out-Null
$drive = $null
for ($i = 0; $i -lt 10 -and -not $drive; $i++) {
    Start-Sleep -Seconds 1
    $drive = (Get-DiskImage -ImagePath $IsoPath | Get-Volume).DriveLetter
}
if (-not $drive) { throw "Nao consegui obter a letra da ISO montada." }
robocopy "${drive}:\" $Src /E /R:2 /W:2 /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy falhou ao copiar a ISO (codigo $LASTEXITCODE)" }
Dismount-DiskImage -ImagePath $IsoPath | Out-Null
& attrib.exe -R "$Src\*" /S /D | Out-Null
Ok "ISO extraida para $Src"

# ---------------------------------------------------------------------------------
# 3. Exportar apenas a edicao escolhida (install.esd -> install.wim)
# ---------------------------------------------------------------------------------
Step "Exportando a edicao '$Edition'"
$sources  = Join-Path $Src 'sources'
$origWim  = Join-Path $sources 'install.wim'
$origEsd  = Join-Path $sources 'install.esd'
$srcImage = if (Test-Path $origWim) { $origWim } elseif (Test-Path $origEsd) { $origEsd } else { throw "sources\install.wim ou install.esd nao encontrado" }

$images = Get-WindowsImage -ImagePath $srcImage
$sel = $images | Where-Object { $_.ImageName -eq $Edition } | Select-Object -First 1
if (-not $sel) {
    Write-Host "Edicoes disponiveis nesta ISO:" -ForegroundColor Yellow
    $images | ForEach-Object { Write-Host ("   [{0}] {1}" -f $_.ImageIndex, $_.ImageName) }
    throw "Edicao '$Edition' nao encontrada. Use -Edition com um dos nomes acima."
}
$workWim = Join-Path $Tmp 'install.wim'
Export-WindowsImage -SourceImagePath $srcImage -SourceIndex $sel.ImageIndex `
    -DestinationImagePath $workWim -CompressionType Max -CheckIntegrity | Out-Null
Ok "Edicao exportada (indice $($sel.ImageIndex)) para $workWim"

# ---------------------------------------------------------------------------------
# 4. Montar a imagem
# ---------------------------------------------------------------------------------
Step "Montando install.wim em $Mount (leva alguns minutos)"
Mount-WindowsImage -ImagePath $workWim -Index 1 -Path $Mount | Out-Null
Ok "Imagem montada"

try {
    # -----------------------------------------------------------------------------
    # 5. Remover apps pre-instalados (provisionados)
    # -----------------------------------------------------------------------------
    Step "Removendo apps pre-instalados da imagem"
    $prov = Get-AppxProvisionedPackage -Path $Mount
    $removed = 0
    foreach ($p in $prov) {
        if ($RemoveApps -contains $p.DisplayName) {
            try {
                Remove-AppxProvisionedPackage -Path $Mount -PackageName $p.PackageName | Out-Null
                Ok "removido: $($p.DisplayName)"; $removed++
            } catch { Write-Warning "nao removido: $($p.DisplayName) - $($_.Exception.Message)" }
        }
    }
    Ok "$removed apps removidos. Apps que permaneceram:"
    Get-AppxProvisionedPackage -Path $Mount | ForEach-Object { Write-Host "      - $($_.DisplayName)" -ForegroundColor DarkGray }

    # -----------------------------------------------------------------------------
    # 6. Politicas de registro OFFLINE (valem desde o primeiro boot)
    #    Sao as mesmas que o freedom-tweaks.ps1 aplica online; aqui garantimos que
    #    o OOBE nao baixe apps promovidos (Candy Crush & cia), Teams, Copilot etc.
    # -----------------------------------------------------------------------------
    Step "Aplicando politicas de registro offline"
    & reg.exe load HKLM\OFF_SOFTWARE "$Mount\Windows\System32\config\SOFTWARE" | Out-Null
    & reg.exe load HKLM\OFF_DEFAULT  "$Mount\Users\Default\NTUSER.DAT"          | Out-Null

    function OffReg([string]$key, [string]$name, [string]$type, [string]$value) {
        & reg.exe add "HKLM\OFF_SOFTWARE\$key" /v $name /t $type /d $value /f | Out-Null
    }
    $P = 'Policies\Microsoft\Windows'

    # Telemetria / diagnostico
    OffReg "$P\DataCollection" AllowTelemetry                          REG_DWORD 0
    OffReg "$P\DataCollection" DisableOneSettingsDownloads             REG_DWORD 1
    OffReg "$P\DataCollection" DoNotShowFeedbackNotifications          REG_DWORD 1
    OffReg "$P\DataCollection" LimitDiagnosticLogCollection            REG_DWORD 1
    OffReg "$P\DataCollection" LimitDumpCollection                     REG_DWORD 1
    OffReg "$P\DataCollection" AllowDeviceNameInTelemetry              REG_DWORD 0
    OffReg "Microsoft\Windows\CurrentVersion\Policies\DataCollection" AllowTelemetry REG_DWORD 0
    OffReg "$P\AppCompat"      AITEnable                               REG_DWORD 0
    OffReg "$P\AppCompat"      DisableInventory                        REG_DWORD 1
    OffReg "Policies\Microsoft\SQMClient\Windows" CEIPEnable           REG_DWORD 0
    OffReg "$P\Windows Error Reporting" Disabled                       REG_DWORD 1
    OffReg "$P\PreviewBuilds"  AllowBuildPreview                       REG_DWORD 0

    # Conteudo promovido / apps sugeridos / Spotlight
    OffReg "$P\CloudContent"   DisableWindowsConsumerFeatures          REG_DWORD 1
    OffReg "$P\CloudContent"   DisableSoftLanding                      REG_DWORD 1
    OffReg "$P\CloudContent"   DisableCloudOptimizedContent            REG_DWORD 1
    OffReg "$P\CloudContent"   DisableConsumerAccountStateContent      REG_DWORD 1
    OffReg "$P\AdvertisingInfo" DisabledByGroupPolicy                  REG_DWORD 1
    OffReg "$P\OOBE"           DisablePrivacyExperience                REG_DWORD 1

    # Chat/Teams, Widgets, Copilot, Recall
    OffReg "$P\Windows Chat"   ChatIcon                                REG_DWORD 3
    OffReg "Policies\Microsoft\Dsh" AllowNewsAndInterests              REG_DWORD 0
    OffReg "$P\WindowsCopilot" TurnOffWindowsCopilot                   REG_DWORD 1
    OffReg "$P\WindowsAI"      DisableAIDataAnalysis                   REG_DWORD 1
    OffReg "$P\WindowsAI"      TurnOffSavingSnapshots                  REG_DWORD 1
    OffReg "$P\WindowsAI"      DisableClickToDo                        REG_DWORD 1

    # Pesquisa: sem Bing/Cortana/web
    OffReg "$P\Windows Search" AllowCortana                            REG_DWORD 0
    OffReg "$P\Windows Search" DisableWebSearch                        REG_DWORD 1
    OffReg "$P\Windows Search" ConnectedSearchUseWeb                   REG_DWORD 0

    # Historico de atividades, localizacao, coleta de digitacao
    OffReg "$P\System"         EnableActivityFeed                      REG_DWORD 0
    OffReg "$P\System"         PublishUserActivities                   REG_DWORD 0
    OffReg "$P\System"         UploadUserActivities                    REG_DWORD 0
    OffReg "$P\LocationAndSensors" DisableLocation                     REG_DWORD 1
    OffReg "$P\TextInput"      AllowLinguisticDataCollection           REG_DWORD 0

    # OneDrive fora, Otimizacao de Entrega so HTTP (sem P2P)
    OffReg "$P\OneDrive"       DisableFileSyncNGSC                     REG_DWORD 1
    OffReg "$P\DeliveryOptimization" DODownloadMode                    REG_DWORD 0

    # Edge: sem "inicializacao rapida" em segundo plano, sem barra lateral/Copilot
    OffReg "Policies\Microsoft\Edge" StartupBoostEnabled               REG_DWORD 0
    OffReg "Policies\Microsoft\Edge" BackgroundModeEnabled             REG_DWORD 0
    OffReg "Policies\Microsoft\Edge" HubsSidebarEnabled                REG_DWORD 0

    # Perfil padrao (todo usuario novo): nao instalar OneDrive no primeiro logon
    & reg.exe delete "HKLM\OFF_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDriveSetup /f 2>$null | Out-Null

    [gc]::Collect(); Start-Sleep -Seconds 1
    & reg.exe unload HKLM\OFF_DEFAULT  | Out-Null
    & reg.exe unload HKLM\OFF_SOFTWARE | Out-Null
    Ok "Politicas aplicadas"

    # Remove o instalador do OneDrive da imagem (tambem e reaplicado online pelo freedom-tweaks)
    foreach ($od in "$Mount\Windows\System32\OneDriveSetup.exe", "$Mount\Windows\SysWOW64\OneDriveSetup.exe") {
        if (Test-Path $od) {
            & takeown.exe /F $od /A | Out-Null
            & icacls.exe $od /grant "*S-1-5-32-544:F" /Q | Out-Null   # Administrators
            Remove-Item $od -Force -ErrorAction SilentlyContinue
        }
    }

    # -----------------------------------------------------------------------------
    # 7. Drivers (opcional)
    # -----------------------------------------------------------------------------
    if ($DriversPath) {
        Step "Integrando drivers de $DriversPath"
        Add-WindowsDriver -Path $Mount -Driver $DriversPath -Recurse | Out-Null
        Ok "Drivers integrados"
    }
}
catch {
    Write-Host "`nERRO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Descartando alteracoes e desmontando..." -ForegroundColor Yellow
    & reg.exe unload HKLM\OFF_DEFAULT  2>$null | Out-Null
    & reg.exe unload HKLM\OFF_SOFTWARE 2>$null | Out-Null
    Dismount-WindowsImage -Path $Mount -Discard | Out-Null
    throw
}

# ---------------------------------------------------------------------------------
# 8. Salvar e desmontar
# ---------------------------------------------------------------------------------
Step "Salvando install.wim (leva alguns minutos)"
Dismount-WindowsImage -Path $Mount -Save -CheckIntegrity | Out-Null
Remove-Item $origWim, $origEsd -Force -ErrorAction SilentlyContinue
Move-Item $workWim (Join-Path $sources 'install.wim') -Force
Ok "install.wim final: $([math]::Round((Get-Item (Join-Path $sources 'install.wim')).Length / 1GB, 2)) GB"

# ---------------------------------------------------------------------------------
# 9. Injetar autounattend.xml e scripts pos-instalacao
#    sources\$OEM$\$$\Setup\Scripts  ==>  C:\Windows\Setup\Scripts no PC instalado
# ---------------------------------------------------------------------------------
Step "Copiando autounattend.xml e scripts para a midia"
Copy-Item (Join-Path $ScriptDir 'autounattend.xml') (Join-Path $Src 'autounattend.xml') -Force
$oem = Join-Path $sources '$OEM$\$$\Setup\Scripts'
New-Item -ItemType Directory -Force -Path $oem | Out-Null
foreach ($f in 'freedom-tweaks.ps1', 'freedom-watch.ps1', 'freedom-restore.ps1', 'apps.ps1', 'verify.ps1') {
    Copy-Item (Join-Path $ScriptDir $f) $oem -Force
}
Ok "Arquivos copiados"

# ---------------------------------------------------------------------------------
# 10. Gerar a ISO
# ---------------------------------------------------------------------------------
if ($oscdimg) {
    if (-not $OutputIso) { $OutputIso = Join-Path $WorkDir 'CleanWindows.iso' }
    Step "Gerando ISO em $OutputIso"
    $bootData = "2#p0,e,b$Src\boot\etfsboot.com#pEF,e,b$Src\efi\microsoft\boot\efisys.bin"
    & $oscdimg '-m' '-o' '-u2' '-udfver102' "-bootdata:$bootData" "$Src" "$OutputIso"
    if ($LASTEXITCODE -ne 0) { throw "oscdimg falhou (codigo $LASTEXITCODE)" }
    Ok "ISO pronta: $OutputIso ($([math]::Round((Get-Item $OutputIso).Length / 1GB, 2)) GB)"
} else {
    Step "Midia pronta (sem ISO) em $Src"
}

Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $Mount -Recurse -Force -ErrorAction SilentlyContinue

Write-Host @"

=====================================================================================
 PRONTO.
  - Grave a ISO no pendrive com o Rufus (https://rufus.ie), esquema GPT / UEFI.
  - Teste primeiro numa VM com TPM 2.0 e Secure Boot (Hyper-V Gen2 ou VirtualBox 7).
  - Usuario/senha padrao definidos no autounattend.xml: Freedom / (sem senha).
  - No primeiro logon o freedom-tweaks.ps1 roda sozinho e reinicia o PC uma vez.
    Log: C:\Windows\Setup\Scripts\freedom-tweaks.log
  - Depois, rode C:\Windows\Setup\Scripts\verify.ps1 para conferir o resultado
    e apps.ps1 para instalar Steam/Discord/VC++ etc. via winget.
=====================================================================================
"@ -ForegroundColor Green
