<#
=====================================================================================
  freedom-tweaks.ps1  -  Tweaks de privacidade + desempenho para jogos (Windows 11/10)
=====================================================================================
  * E executado automaticamente no primeiro logon quando voce instala pela ISO do kit.
  * Tambem pode ser rodado a qualquer momento num Windows ja instalado:
        powershell -ExecutionPolicy Bypass -File .\freedom-tweaks.ps1
  * E idempotente: rodar de novo nao causa problema.
  * Tudo o que ele faz esta neste arquivo, em texto claro, com o motivo ao lado.
    Ligue/desligue cada bloco na secao CONFIGURACAO logo abaixo.
  * Log: C:\Windows\Setup\Scripts\freedom-tweaks.log

  Parametros:
    -Reboot              reinicia o PC ao terminar (o autounattend usa este)
    -SkipDefaultProfile  nao aplica os ajustes de usuario ao perfil padrao
                         (por padrao aplica, para que novos usuarios ja nascam ajustados)
    -RestorePoint        cria um ponto de restauracao do sistema antes de mexer em algo.
                         Recomendado ao rodar num Windows JA instalado.
=====================================================================================
#>
[CmdletBinding()]
param(
    [switch]$Reboot,
    [switch]$SkipDefaultProfile,
    [switch]$RestorePoint
)

# ===================================================================================
#  CONFIGURACAO  -  $true liga, $false desliga
# ===================================================================================
$Cfg = @{
    RemoveBloatApps        = $true   # remove apps pre-instalados (lista $BloatApps abaixo)
    KeepXboxApps           = $true   # mantem Xbox app / Game Bar / Xbox Identity. Necessario p/
                                     # Game Pass PC, Minecraft, Forza, e controle Xbox sem fio.
    DisableTelemetry       = $true   # servicos, tarefas agendadas e politicas de telemetria
    Privacy                = $true   # ID de publicidade, sugestoes, Spotlight, historico, localizacao...
    DisableCopilotRecall   = $true   # Copilot, Recall, Click to Do, botao na barra
    DisableWidgetsChat     = $true   # Widgets, Chat/Teams, noticias
    RemoveOneDrive         = $true   # desinstala OneDrive e tira da barra lateral
    GamingTweaks           = $true   # Game Mode, DVR off, HAGS, MMCSS, mouse sem aceleracao,
                                     # atalhos de Teclas de Aderencia off
    PowerPlanUltimate      = $true   # plano "Desempenho Maximo". Em NOTEBOOK deixe $false.
    DisableVBS             = $true   # desliga Isolamento de Nucleo / Integridade da memoria.
                                     # Ganho real de FPS (5-15% em alguns jogos); reduz a
                                     # protecao contra malware de kernel. Reversivel em
                                     # Seguranca do Windows > Seguranca do dispositivo.
    DisableHibernation     = $true   # desliga hibernacao e Inicializacao Rapida (evita bugs
                                     # de driver/rede apos "desligar"; libera hiberfil.sys)
    DisableSysMain         = $false  # SysMain/Superfetch. So ligue se tiver stutter comprovado.
    DisableNagle           = $false  # TcpAckFrequency/TCPNoDelay. Ajuda em poucos jogos online.
    BlockDriverUpdates     = $false  # impede o Windows Update de trocar drivers (GPU). Ligue
                                     # DEPOIS de instalar seus drivers, se ele te atrapalhar.
    ExplorerQoL            = $true   # extensoes visiveis, "Este Computador" ao abrir, menu de
                                     # contexto classico, sem Task View, busca so icone
    DisableServices        = $true   # servicos inuteis num PC de jogos (lista $Services)
    DisableScheduledTasks  = $true   # tarefas de coleta/CEIP (lista $Tasks)
    EdgeTweaks             = $true   # Edge sem rodar em segundo plano / sem barra lateral
    DefenderExclusions     = @()     # ex.: @('C:\Games', 'D:\SteamLibrary'). Defender segue LIGADO.
    DualBootUtcClock       = $false  # DUAL BOOT com Linux: Windows passa a usar o relogio em UTC,
                                     # igual ao Linux; evita a hora trocar a cada boot.
    PreventDeviceEncryption = $true  # impede o Win11 24H2/25H2 de ligar BitLocker/Device Encryption
                                     # sozinho. NAO decifra um disco ja cifrado; so evita novos.
    AutoReapplyAfterUpdate = $true   # cria uma tarefa agendada que, no logon, verifica se o Windows
                                     # se atualizou; se sim, avisa na tela, cria um ponto de
                                     # restauracao e roda este script de novo. Atualizacoes de
                                     # versao reinstalam Copilot/Widgets/OneDrive e religam a
                                     # telemetria. Desligue com $false (e o script remove a tarefa).
    DesempenhoVisual       = $true   # deixa o Windows mais leve: sem transparencia da barra, sem
                                     # sombras e sem animacoes (janelas, menus, dicas). Mantem o
                                     # ClearType (nitidez das fontes). Vale para o usuario atual e
                                     # para novos usuarios.
    SilenciarUAC           = $true   # tira o popup "Deseja permitir..." para contas de ADMIN: elas
                                     # elevam sem perguntar. O UAC continua LIGADO (nao desativa a
                                     # protecao/sandbox nem a Loja). $false mantem o popup.
    MedirDesempenho        = $true   # mede leveza (processos, RAM, apps, servicos...) ANTES da
                                     # limpeza e guarda, p/ o programa mostrar a comparacao depois.
}

# Apps removidos (online). Nomes inexistentes sao ignorados.
$BloatApps = @(
    'Clipchamp.Clipchamp', 'Microsoft.549981C3F5F10', 'Microsoft.BingNews', 'Microsoft.BingSearch',
    'Microsoft.BingWeather', 'Microsoft.Copilot', 'Microsoft.Windows.Ai.Copilot.Provider',
    'Microsoft.Edge.GameAssist', 'Microsoft.GetHelp', 'Microsoft.Getstarted', 'Microsoft.MicrosoftOfficeHub',
    'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftStickyNotes', 'Microsoft.OutlookForWindows',
    'Microsoft.People', 'Microsoft.PowerAutomateDesktop', 'Microsoft.Todos', 'Microsoft.Windows.DevHome',
    'Microsoft.WindowsAlarms', 'Microsoft.WindowsFeedbackHub', 'Microsoft.WindowsMaps',
    'Microsoft.WindowsSoundRecorder', 'Microsoft.YourPhone', 'Microsoft.ZuneMusic', 'Microsoft.ZuneVideo',
    'MicrosoftCorporationII.QuickAssist', 'MicrosoftCorporationII.MicrosoftFamily',
    'microsoft.windowscommunicationsapps', 'MicrosoftWindows.Client.WebExperience', 'MicrosoftWindows.CrossDevice',
    'MSTeams', 'Microsoft.MixedReality.Portal', 'Microsoft.Microsoft3DViewer', 'Microsoft.Print3D',
    'Microsoft.Wallet', 'Microsoft.Messaging', 'Microsoft.OneConnect', 'Microsoft.SkypeApp',
    'Microsoft.Office.OneNote', 'Microsoft.LinkedIn'
)
$XboxApps = @(
    'Microsoft.GamingApp', 'Microsoft.Xbox.TCUI', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxGamingOverlay',
    'Microsoft.XboxIdentityProvider', 'Microsoft.XboxSpeechToTextOverlay'
)

# Servicos que serao DESABILITADOS
$Services = @(
    'DiagTrack'                                   # Experiencias do Usuario Conectado e Telemetria
    'dmwappushservice'                            # roteamento de mensagens WAP (telemetria)
    'diagnosticshub.standardcollector.service'    # coletor de diagnostico
    'WerSvc'                                      # Relatorio de Erros do Windows
    'wercplsupport'                               # suporte ao painel de relatorio de erros
    'RetailDemo'                                  # modo demonstracao de loja
    'MapsBroker'                                  # mapas offline
    'RemoteRegistry'                              # registro remoto
    'Fax'
    'WMPNetworkSvc'                               # compartilhamento do Windows Media Player
    'lfsvc'                                       # geolocalizacao
    'wisvc'                                       # Windows Insider
    'MessagingService'                            # SMS
    'SEMgrSvc'                                    # pagamentos/NFC
    'WpcMonSvc'                                   # controle dos pais
    'TrkWks'                                      # rastreamento de links distribuidos
    'PhoneSvc'                                    # servico de telefonia (Vincular ao Celular)
)

# Tarefas agendadas que serao DESABILITADAS (caminho completo)
$Tasks = @(
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser'
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp'
    '\Microsoft\Windows\Application Experience\ProgramDataUpdater'
    '\Microsoft\Windows\Application Experience\PcaPatchDbTask'
    '\Microsoft\Windows\Application Experience\MareBackup'
    '\Microsoft\Windows\Application Experience\StartupAppTask'
    '\Microsoft\Windows\Autochk\Proxy'
    '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator'
    '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip'
    '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector'
    '\Microsoft\Windows\Feedback\Siuf\DmClient'
    '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload'
    '\Microsoft\Windows\Windows Error Reporting\QueueReporting'
    '\Microsoft\Windows\Maps\MapsUpdateTask'
    '\Microsoft\Windows\Maps\MapsToastTask'
    '\Microsoft\Windows\Device Information\Device'
    '\Microsoft\Windows\Device Information\Device User'
    '\Microsoft\Windows\NetTrace\GatherNetworkInfo'
    '\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem'
    '\Microsoft\Windows\PI\Sqm-Tasks'
    '\Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures'
    '\Microsoft\Windows\Flighting\OneSettings\RefreshCache'
)

# ===================================================================================
#  Infraestrutura (auto-elevacao, log, helpers)
# ===================================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($Reboot) { $argList += '-Reboot' }
    if ($SkipDefaultProfile) { $argList += '-SkipDefaultProfile' }
    if ($RestorePoint) { $argList += '-RestorePoint' }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argList
    exit
}

$ErrorActionPreference = 'Continue'
$LogDir = "$env:SystemRoot\Setup\Scripts"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }

# Se estiver rodando de outro lugar (DVD do kit, pendrive, Downloads...), copia os scripts do
# kit para C:\Windows\Setup\Scripts para que apps.ps1 e verify.ps1 fiquem sempre no mesmo lugar.
if ($PSScriptRoot -and ($PSScriptRoot.TrimEnd('\') -ne $LogDir)) {
    Get-ChildItem -Path $PSScriptRoot -Filter '*.ps1' -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item $_.FullName $LogDir -Force -ErrorAction SilentlyContinue
    }
    Get-ChildItem -Path $LogDir -Filter '*.ps1' -ErrorAction SilentlyContinue | ForEach-Object { $_.IsReadOnly = $false }
}
$Log = Join-Path $LogDir 'freedom-tweaks.log'

function Log([string]$m, [string]$color = 'Gray') {
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Write-Host $line -ForegroundColor $color
    Add-Content -Path $Log -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}
function Section([string]$m) { Log "==== $m ====" 'Cyan' }

# Grava um valor de registro, criando a chave se preciso. Tipos: DWord, String, ExpandString, QWord
function Set-Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    try {
        if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force -ErrorAction Stop | Out-Null }
        if ($Name -eq '(Default)') {
            Set-ItemProperty -LiteralPath $Path -Name '(Default)' -Value $Value -ErrorAction Stop
        } else {
            New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
        }
    } catch { Log "  ! falhou: $Path [$Name] - $($_.Exception.Message)" 'Yellow' }
}
function Remove-RegValue([string]$Path, [string]$Name) {
    try { Remove-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop } catch {}
}
function Disable-Svc([string]$name) {
    $s = Get-Service -Name $name -ErrorAction SilentlyContinue
    if (-not $s) { return }
    try {
        Stop-Service -Name $name -Force -ErrorAction SilentlyContinue
        Set-Service -Name $name -StartupType Disabled -ErrorAction Stop
        Log "  servico desabilitado: $name"
    } catch { Log "  ! nao consegui desabilitar $name - $($_.Exception.Message)" 'Yellow' }
}
function Disable-Task([string]$fullPath) {
    $idx  = $fullPath.LastIndexOf('\')
    $path = $fullPath.Substring(0, $idx + 1)
    $name = $fullPath.Substring($idx + 1)
    $t = Get-ScheduledTask -TaskPath $path -TaskName $name -ErrorAction SilentlyContinue
    if ($t) {
        try { $t | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Log "  tarefa desabilitada: $fullPath" }
        catch { Log "  ! tarefa $fullPath - $($_.Exception.Message)" 'Yellow' }
    }
}

# Mede indicadores de "leveza" do sistema (usado para o antes/depois).
function Get-Metricas {
    $ram = 0
    try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
          $ram = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1024) } catch {}
    $ini = 0
    foreach ($rk in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
                    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run') {
        try { $ini += @((Get-Item $rk -ErrorAction Stop).Property).Count } catch {}
    }
    [pscustomobject]@{
        Processos = @(Get-Process -ErrorAction SilentlyContinue).Count
        RamUsoMB  = [int]$ram
        Servicos  = @(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' }).Count
        Appx      = @(Get-AppxPackage -ErrorAction SilentlyContinue).Count
        Tarefas   = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Ready' }).Count
        Inicio    = $ini
    }
}

Log "freedom-tweaks.ps1 iniciado por $env:USERNAME em $env:COMPUTERNAME" 'Green'
$P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows'

# ---- Medicao ANTES (para o programa mostrar a comparacao de leveza depois) ----
if ($Cfg.MedirDesempenho) {
    Section "Medindo o desempenho antes da limpeza"
    try {
        $mAntes = Get-Metricas
        $CW = 'HKLM:\SOFTWARE\CleanWindows'
        Set-Reg $CW Antes_Processos $mAntes.Processos
        Set-Reg $CW Antes_RamMB     $mAntes.RamUsoMB
        Set-Reg $CW Antes_Servicos  $mAntes.Servicos
        Set-Reg $CW Antes_Appx      $mAntes.Appx
        Set-Reg $CW Antes_Tarefas   $mAntes.Tarefas
        Set-Reg $CW Antes_Inicio    $mAntes.Inicio
        Set-Reg $CW Antes_Quando    (Get-Date -Format 's') 'String'
        Set-Reg $CW MostrarComparacao 1
        Log "  antes: $($mAntes.Processos) processos, $($mAntes.RamUsoMB) MB de RAM em uso, $($mAntes.Appx) apps"
    } catch { Log "  ! nao consegui medir: $($_.Exception.Message)" 'Yellow' }
}

if ($RestorePoint) {
    Section "Ponto de restauracao"
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction Stop
        # Windows so cria 1 ponto a cada 24h por padrao; libera para criar agora
        Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' SystemRestorePointCreationFrequency 0
        Checkpoint-Computer -Description 'Antes do freedom-tweaks' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Log "  ponto de restauracao criado"
    } catch { Log "  ! nao consegui criar o ponto de restauracao: $($_.Exception.Message)" 'Yellow' }
}

# ===================================================================================
#  Ajustes por USUARIO (aplicados ao usuario atual e ao perfil padrao)
#  $U = 'HKCU:' ou 'Registry::HKEY_USERS\DefUser'
# ===================================================================================
function Apply-UserTweaks([string]$U) {
    $Adv = "$U\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $CDM = "$U\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

    if ($Cfg.Privacy) {
        # ID de publicidade e "experiencias personalizadas"
        Set-Reg "$U\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" Enabled 0
        Set-Reg "$U\Software\Microsoft\Windows\CurrentVersion\Privacy" TailoredExperiencesWithDiagnosticDataEnabled 0
        Set-Reg "$U\Software\Policies\Microsoft\Windows\CloudContent" DisableTailoredExperiencesWithDiagnosticData 1
        # Sugestoes, apps promovidos, Spotlight, dicas
        foreach ($v in 'ContentDeliveryAllowed', 'OemPreInstalledAppsEnabled', 'PreInstalledAppsEnabled',
                       'PreInstalledAppsEverEnabled', 'SilentInstalledAppsEnabled', 'SystemPaneSuggestionsEnabled',
                       'SoftLandingEnabled', 'RotatingLockScreenEnabled', 'RotatingLockScreenOverlayEnabled',
                       'SubscribedContent-310093Enabled', 'SubscribedContent-338387Enabled',
                       'SubscribedContent-338388Enabled', 'SubscribedContent-338389Enabled',
                       'SubscribedContent-338393Enabled', 'SubscribedContent-353694Enabled',
                       'SubscribedContent-353696Enabled', 'SubscribedContent-353698Enabled') {
            Set-Reg $CDM $v 0
        }
        # Pesquisa sem Bing / sem "destaques"
        Set-Reg "$U\Software\Microsoft\Windows\CurrentVersion\Search" BingSearchEnabled 0
        Set-Reg "$U\Software\Microsoft\Windows\CurrentVersion\Search" CortanaConsent 0
        Set-Reg "$U\Software\Microsoft\Windows\CurrentVersion\SearchSettings" IsDynamicSearchBoxEnabled 0
        Set-Reg "$U\Software\Policies\Microsoft\Windows\Explorer" DisableSearchBoxSuggestions 1
        # Pedidos de feedback
        Set-Reg "$U\Software\Microsoft\Siuf\Rules" NumberOfSIUFInPeriod 0
        Set-Reg "$U\Software\Microsoft\Siuf\Rules" PeriodInNanoSeconds 0
        # Coleta de digitacao / tinta / fala
        Set-Reg "$U\Software\Microsoft\InputPersonalization" RestrictImplicitInkCollection 1
        Set-Reg "$U\Software\Microsoft\InputPersonalization" RestrictImplicitTextCollection 1
        Set-Reg "$U\Software\Microsoft\InputPersonalization\TrainedDataStore" HarvestContacts 0
        Set-Reg "$U\Software\Microsoft\Personalization\Settings" AcceptedPrivacyPolicy 0
        Set-Reg "$U\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" HasAccepted 0
        # "Vamos terminar de configurar seu dispositivo" e notificacoes de conta no Iniciar
        Set-Reg "$U\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" ScoobeSystemSettingEnabled 0
        Set-Reg $Adv Start_AccountNotifications 0
        Set-Reg $Adv Start_IrisRecommendations 0      # "Recomendados" com sugestoes de app/site
        Set-Reg $Adv Start_Layout 1                   # mais fixados, menos recomendados
        Set-Reg $Adv ShowSyncProviderNotifications 0  # anuncios do OneDrive no Explorador
    }

    if ($Cfg.DisableCopilotRecall) {
        Set-Reg "$U\Software\Policies\Microsoft\Windows\WindowsCopilot" TurnOffWindowsCopilot 1
        Set-Reg "$U\Software\Policies\Microsoft\Windows\WindowsAI" DisableAIDataAnalysis 1
        Set-Reg "$U\Software\Policies\Microsoft\Windows\WindowsAI" TurnOffSavingSnapshots 1
        Set-Reg $Adv ShowCopilotButton 0
    }

    if ($Cfg.DisableWidgetsChat) {
        # Widgets: o valor TaskbarDa e protegido pelo Windows 11 23H2+ (acesso negado mesmo como
        # admin). O botao some pela politica Dsh\AllowNewsAndInterests=0, aplicada na secao 4.
        Set-Reg $Adv TaskbarMn 0   # Chat
    }

    if ($Cfg.GamingTweaks) {
        # Game Mode ligado; Xbox Game Bar nao abre com o botao do controle nem mostra dicas
        Set-Reg "$U\Software\Microsoft\GameBar" AutoGameModeEnabled 1
        Set-Reg "$U\Software\Microsoft\GameBar" AllowAutoGameMode 1
        Set-Reg "$U\Software\Microsoft\GameBar" UseNexusForGameBarEnabled 0
        Set-Reg "$U\Software\Microsoft\GameBar" ShowStartupPanel 0
        # Game DVR (gravacao em segundo plano) desligado - custa FPS
        Set-Reg "$U\System\GameConfigStore" GameDVR_Enabled 0
        Set-Reg "$U\Software\Microsoft\Windows\CurrentVersion\GameDVR" AppCaptureEnabled 0
        # "Otimizacoes para jogos em janela" (flip model p/ jogos DX10/11 em janela)
        Set-Reg "$U\Software\Microsoft\DirectX\UserGpuPreferences" DirectXUserGlobalSettings 'SwapEffectUpgradeEnable=1;' String
        # Mouse sem aceleracao ("Aumentar precisao do ponteiro" OFF)
        Set-Reg "$U\Control Panel\Mouse" MouseSpeed '0' String
        Set-Reg "$U\Control Panel\Mouse" MouseThreshold1 '0' String
        Set-Reg "$U\Control Panel\Mouse" MouseThreshold2 '0' String
        # Atalhos de acessibilidade (Shift 5x = Teclas de Aderencia etc.) desligados
        Set-Reg "$U\Control Panel\Accessibility\StickyKeys" Flags '506' String
        Set-Reg "$U\Control Panel\Accessibility\ToggleKeys" Flags '58' String
        Set-Reg "$U\Control Panel\Accessibility\Keyboard Response" Flags '122' String
    }

    if ($Cfg.ExplorerQoL) {
        Set-Reg $Adv HideFileExt 0            # mostra extensoes de arquivo
        Set-Reg $Adv LaunchTo 1               # Explorador abre em "Este Computador"
        Set-Reg $Adv ShowTaskViewButton 0     # sem botao Visao de Tarefas
        Set-Reg "$U\Software\Microsoft\Windows\CurrentVersion\Search" SearchboxTaskbarMode 1   # busca so icone
        # Menu de contexto classico (botao direito completo, sem "Mostrar mais opcoes")
        Set-Reg "$U\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" '(Default)' '' String
    }

    if ($Cfg.DesempenhoVisual) {
        # Sem transparencia (barra/menus): mais leve para a GPU
        Set-Reg "$U\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" EnableTransparency 0
        # Sem animacoes de janelas, barra, listas e menus (mantem ClearType)
        Set-Reg "$U\Control Panel\Desktop\WindowMetrics" MinAnimate '0' String
        Set-Reg "$U\Control Panel\Desktop" MenuShowDelay '0' String
        Set-Reg "$U\Control Panel\Desktop" DragFullWindows '1' String
        Set-Reg $Adv TaskbarAnimations 0
        Set-Reg $Adv ListviewAlphaSelect 0
        Set-Reg $Adv ListviewShadow 0
        Set-Reg "$U\Software\Microsoft\Windows\DWM" EnableAeroPeek 0
        # Mascara de "melhor desempenho" que desliga animacoes/fades mas mantem a suavizacao
        # de fontes (ClearType). Bytes conhecidos do Windows para esse conjunto.
        Set-Reg "$U\Control Panel\Desktop" UserPreferencesMask ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) Binary
    }

    if ($Cfg.RemoveOneDrive) {
        Remove-RegValue "$U\Software\Microsoft\Windows\CurrentVersion\Run" OneDriveSetup
        Set-Reg "$U\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" System.IsPinnedToNameSpaceTree 0
    }
}

# ===================================================================================
#  1. Apps pre-instalados
# ===================================================================================
if ($Cfg.RemoveBloatApps) {
    Section "Removendo apps pre-instalados"
    $list = $BloatApps
    if (-not $Cfg.KeepXboxApps) { $list += $XboxApps }
    foreach ($pkg in (Get-AppxPackage -AllUsers | Where-Object { $list -contains $_.Name })) {
        try { Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop; Log "  removido: $($pkg.Name)" }
        catch { Log "  ! $($pkg.Name): $($_.Exception.Message)" 'Yellow' }
    }
    foreach ($prov in (Get-AppxProvisionedPackage -Online | Where-Object { $list -contains $_.DisplayName })) {
        try { Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop | Out-Null; Log "  desprovisionado: $($prov.DisplayName)" }
        catch { Log "  ! $($prov.DisplayName): $($_.Exception.Message)" 'Yellow' }
    }
}

# ===================================================================================
#  2. Telemetria
# ===================================================================================
if ($Cfg.DisableTelemetry) {
    Section "Telemetria e diagnostico"
    Set-Reg "$P\DataCollection" AllowTelemetry 0                 # 0 = Seguranca (Enterprise) / minimo (Home-Pro)
    Set-Reg "$P\DataCollection" DisableOneSettingsDownloads 1
    Set-Reg "$P\DataCollection" DoNotShowFeedbackNotifications 1
    Set-Reg "$P\DataCollection" LimitDiagnosticLogCollection 1
    Set-Reg "$P\DataCollection" LimitDumpCollection 1
    Set-Reg "$P\DataCollection" AllowDeviceNameInTelemetry 0
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' AllowTelemetry 0
    Set-Reg "$P\AppCompat" AITEnable 0                            # Application Impact Telemetry
    Set-Reg "$P\AppCompat" DisableInventory 1                     # inventario de programas
    Set-Reg "$P\AppCompat" DisableUAR 1                           # Gravador de Passos
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows' CEIPEnable 0
    Set-Reg "$P\Windows Error Reporting" Disabled 1
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' Disabled 1
    Set-Reg "$P\PreviewBuilds" AllowBuildPreview 0
    # Autologgers de ETW que alimentam a telemetria
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AutoLogger-Diagtrack-Listener' Start 0
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\SQMLogger' Start 0
    if ($Cfg.DisableServices) { foreach ($s in $Services) { Disable-Svc $s } }
    if ($Cfg.DisableScheduledTasks) { foreach ($t in $Tasks) { Disable-Task $t } }
}

# ===================================================================================
#  3. Privacidade (maquina)
# ===================================================================================
if ($Cfg.Privacy) {
    Section "Privacidade"
    Set-Reg "$P\CloudContent" DisableWindowsConsumerFeatures 1    # sem Candy Crush & cia
    Set-Reg "$P\CloudContent" DisableSoftLanding 1
    Set-Reg "$P\CloudContent" DisableCloudOptimizedContent 1
    Set-Reg "$P\CloudContent" DisableConsumerAccountStateContent 1
    Set-Reg "$P\AdvertisingInfo" DisabledByGroupPolicy 1
    Set-Reg "$P\OOBE" DisablePrivacyExperience 1
    Set-Reg "$P\System" EnableActivityFeed 0                     # historico de atividades
    Set-Reg "$P\System" PublishUserActivities 0
    Set-Reg "$P\System" UploadUserActivities 0
    Set-Reg "$P\LocationAndSensors" DisableLocation 1
    Set-Reg "$P\TextInput" AllowLinguisticDataCollection 0
    Set-Reg "$P\Windows Search" AllowCortana 0
    Set-Reg "$P\Windows Search" DisableWebSearch 1
    Set-Reg "$P\Windows Search" ConnectedSearchUseWeb 0
    Set-Reg "$P\Maps" AutoDownloadAndUpdateMapData 0
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice' AllowFindMyDevice 0
    Set-Reg "$P\DeliveryOptimization" DODownloadMode 0           # sem P2P de updates
}

# ===================================================================================
#  4. Copilot / Recall / Widgets / Chat
# ===================================================================================
if ($Cfg.DisableCopilotRecall) {
    Section "Copilot e Recall"
    Set-Reg "$P\WindowsCopilot" TurnOffWindowsCopilot 1
    Set-Reg "$P\WindowsAI" DisableAIDataAnalysis 1
    Set-Reg "$P\WindowsAI" TurnOffSavingSnapshots 1
    Set-Reg "$P\WindowsAI" DisableClickToDo 1
    try { Disable-WindowsOptionalFeature -Online -FeatureName 'Recall' -NoRestart -ErrorAction Stop | Out-Null; Log "  recurso Recall desabilitado" } catch {}
}
if ($Cfg.DisableWidgetsChat) {
    Section "Widgets e Chat"
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' AllowNewsAndInterests 0
    Set-Reg "$P\Windows Chat" ChatIcon 3
    # ConfigureChatAutoInstall (CurrentVersion\Communications) pertence ao TrustedInstaller e nao
    # aceita escrita; a remocao do MSTeams + ChatIcon=3 ja resolvem.
}

# ===================================================================================
#  5. OneDrive
# ===================================================================================
if ($Cfg.RemoveOneDrive) {
    Section "OneDrive"
    Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    foreach ($od in "$env:SystemRoot\System32\OneDriveSetup.exe", "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
        if (Test-Path $od) { Start-Process $od -ArgumentList '/uninstall' -Wait -NoNewWindow -ErrorAction SilentlyContinue; Log "  executado: $od /uninstall" }
    }
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        & winget uninstall --id Microsoft.OneDrive --silent --accept-source-agreements 2>$null | Out-Null
    }
    Set-Reg "$P\OneDrive" DisableFileSyncNGSC 1
    foreach ($d in "$env:LOCALAPPDATA\Microsoft\OneDrive", "$env:ProgramData\Microsoft OneDrive", "$env:SystemDrive\OneDriveTemp") {
        if (Test-Path $d) { Remove-Item $d -Recurse -Force -ErrorAction SilentlyContinue }
    }
    $odHome = "$env:USERPROFILE\OneDrive"
    if ((Test-Path $odHome) -and -not (Get-ChildItem $odHome -Force -ErrorAction SilentlyContinue)) { Remove-Item $odHome -Force -ErrorAction SilentlyContinue }
}

# ===================================================================================
#  6. Jogos (maquina)
# ===================================================================================
if ($Cfg.GamingTweaks) {
    Section "Ajustes de jogos"
    Set-Reg "$P\GameDVR" AllowGameDVR 0
    # HAGS - agendamento de GPU acelerado por hardware (precisa de GPU/driver compativel)
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' HwSchMode 2
    # MMCSS: menos CPU reservada a tarefas de fundo, sem throttling de rede em multimidia
    $MM = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
    Set-Reg $MM SystemResponsiveness 10
    & reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 0xffffffff /f | Out-Null
    Set-Reg "$MM\Tasks\Games" 'GPU Priority' 8
    Set-Reg "$MM\Tasks\Games" 'Priority' 6
    Set-Reg "$MM\Tasks\Games" 'Scheduling Category' 'High' String
    Set-Reg "$MM\Tasks\Games" 'SFIO Priority' 'High' String
    Log "  Game DVR off, HAGS on, MMCSS ajustado"
}

if ($Cfg.PowerPlanUltimate) {
    Section "Plano de energia"
    try {
        $list = (& powercfg.exe /list) -join "`n"
        $guid = $null
        foreach ($m in [regex]::Matches($list, '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\s+\((.+?)\)')) {
            if ($m.Groups[2].Value -match 'Ultimate|Desempenho M') { $guid = $m.Groups[1].Value; break }
        }
        if (-not $guid) {
            $out = (& powercfg.exe -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61) -join ' '
            if ($out -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') { $guid = $Matches[1] }
        }
        if (-not $guid) { $guid = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' }   # Alto desempenho
        & powercfg.exe /setactive $guid | Out-Null
        Log "  plano ativo: $guid"
    } catch { Log "  ! plano de energia: $($_.Exception.Message)" 'Yellow' }
}

if ($Cfg.DisableVBS) {
    Section "Isolamento de Nucleo / VBS"
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' EnableVirtualizationBasedSecurity 0
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' Enabled 0
    Log "  VBS/HVCI desligados (vale apos reiniciar)"
}

if ($Cfg.DisableHibernation) {
    Section "Hibernacao e Inicializacao Rapida"
    & powercfg.exe /hibernate off | Out-Null
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' HiberbootEnabled 0
    Log "  hibernacao e fast startup desligados"
}

if ($Cfg.DisableSysMain) { Section "SysMain"; Disable-Svc 'SysMain' }

if ($Cfg.SilenciarUAC) {
    Section "UAC (sem popup para administrador, protecao mantida)"
    $sys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    # 0 = elevar sem perguntar (contas de admin). NAO desligamos o UAC (EnableLUA fica 1),
    # entao sandbox de apps, integridade e a Microsoft Store continuam funcionando.
    Set-Reg $sys ConsentPromptBehaviorAdmin 0
    Set-Reg $sys PromptOnSecureDesktop 0
    Set-Reg $sys EnableLUA 1
    Log "  admin eleva sem popup; UAC continua ligado (protecao mantida)"
}

if ($Cfg.PreventDeviceEncryption) {
    Section "Criptografia automatica (BitLocker/Device Encryption)"
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker' PreventDeviceEncryption 1
    Log "  auto device encryption impedida (discos ja cifrados nao sao alterados)"
}

if ($Cfg.DualBootUtcClock) {
    Section "Relogio em UTC (dual boot)"
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' RealTimeIsUniversal 1 'QWord'
}

if ($Cfg.DisableNagle) {
    Section "Nagle (TcpAckFrequency/TCPNoDelay)"
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' | ForEach-Object {
        Set-Reg $_.PSPath TcpAckFrequency 1
        Set-Reg $_.PSPath TCPNoDelay 1
    }
}

# ===================================================================================
#  7. Windows Update (continua LIGADO - so tiramos o reboot automatico e, se quiser, drivers)
# ===================================================================================
Section "Windows Update"
Set-Reg "$P\WindowsUpdate\AU" NoAutoRebootWithLoggedOnUsers 1
if ($Cfg.BlockDriverUpdates) {
    Set-Reg "$P\WindowsUpdate" ExcludeWUDriversInQualityUpdate 1
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching' SearchOrderConfig 0
    Log "  drivers via Windows Update bloqueados"
}

# ===================================================================================
#  8. Edge
# ===================================================================================
if ($Cfg.EdgeTweaks) {
    Section "Edge"
    $E = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    Set-Reg $E StartupBoostEnabled 0
    Set-Reg $E BackgroundModeEnabled 0
    Set-Reg $E HubsSidebarEnabled 0
    Set-Reg $E PersonalizationReportingEnabled 0
    Set-Reg $E DiagnosticData 0
    Set-Reg $E ShowRecommendationsEnabled 0
    Set-Reg $E SpotlightExperiencesAndRecommendationsEnabled 0
}

# ===================================================================================
#  9. Defender: exclusoes (opcional). O Defender continua ligado.
# ===================================================================================
if ($Cfg.DefenderExclusions.Count -gt 0) {
    Section "Exclusoes do Defender"
    foreach ($ex in $Cfg.DefenderExclusions) {
        try { Add-MpPreference -ExclusionPath $ex -ErrorAction Stop; Log "  exclusao: $ex" }
        catch { Log "  ! $ex - $($_.Exception.Message)" 'Yellow' }
    }
}

# ===================================================================================
#  10. Ajustes por usuario: usuario atual + perfil padrao
# ===================================================================================
Section "Ajustes do usuario atual ($env:USERNAME)"
Apply-UserTweaks 'HKCU:'

if (-not $SkipDefaultProfile) {
    Section "Ajustes do perfil padrao (novos usuarios)"
    $defHive = "$env:SystemDrive\Users\Default\NTUSER.DAT"
    if (Test-Path $defHive) {
        & reg.exe load HKU\DefUser $defHive | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Apply-UserTweaks 'Registry::HKEY_USERS\DefUser'
            [gc]::Collect(); [gc]::WaitForPendingFinalizers(); Start-Sleep -Seconds 1
            for ($i = 0; $i -lt 5; $i++) {
                & reg.exe unload HKU\DefUser 2>$null | Out-Null
                if ($LASTEXITCODE -eq 0) { break }
                [gc]::Collect(); Start-Sleep -Seconds 2
            }
            Log "  perfil padrao atualizado"
        } else { Log "  ! nao consegui carregar o hive do perfil padrao (em uso?)" 'Yellow' }
    }
}

# ===================================================================================
#  Reaplicar sozinho depois de uma atualizacao do Windows
# ===================================================================================
Section "Reaplicacao automatica apos atualizacoes"
$TaskName = 'Clean Windows - reaplicar apos atualizacao'
$watchSrc = Join-Path $PSScriptRoot 'freedom-watch.ps1'
$watchDst = Join-Path $LogDir 'freedom-watch.ps1'
if ($Cfg.AutoReapplyAfterUpdate) {
    if ((Test-Path $watchSrc) -and ($watchSrc -ne $watchDst)) { Copy-Item $watchSrc $watchDst -Force -ErrorAction SilentlyContinue }
    if (-not (Test-Path $watchDst)) {
        Log '  ! freedom-watch.ps1 nao encontrado; tarefa nao criada' 'Yellow'
    } else {
        try {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
            $act = New-ScheduledTaskAction -Execute 'powershell.exe' `
                     -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$watchDst`""
            $trg = New-ScheduledTaskTrigger -AtLogOn
            $trg.Delay = 'PT3M'
            # O nome do grupo muda com o idioma ("Administrators" x "Administradores"), entao
            # registramos para o usuario atual; se falhar, traduzimos o SID do grupo de admins.
            $prc = try {
                New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest -ErrorAction Stop
            } catch {
                $grp = (New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')).Translate([System.Security.Principal.NTAccount]).Value
                New-ScheduledTaskPrincipal -GroupId $grp -RunLevel Highest
            }
            $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
                     -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)
            Register-ScheduledTask -TaskName $TaskName -Action $act -Trigger $trg -Principal $prc `
                     -Settings $set -Description 'Reaplica os ajustes do Clean Windows quando o Windows se atualiza.' `
                     -Force -ErrorAction Stop | Out-Null
            Log "  tarefa criada: $TaskName (verifica no logon, 3 min depois)"
        } catch { Log "  ! nao consegui criar a tarefa: $($_.Exception.Message)" 'Yellow' }
    }
    # guarda a versao atual para o vigia comparar depois
    try {
        $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        $disp = if ($cv.DisplayVersion) { $cv.DisplayVersion } else { $cv.ReleaseId }
        $ver = "{0}.{1}.{2}" -f $disp, $cv.CurrentBuildNumber, $cv.UBR
        Set-Reg 'HKLM:\SOFTWARE\CleanWindows' LastWindowsVersion $ver 'String'
        Set-Reg 'HKLM:\SOFTWARE\CleanWindows' LastReapply (Get-Date -Format 's') 'String'
        Log "  versao registrada: $ver"
    } catch { Log "  ! nao consegui registrar a versao: $($_.Exception.Message)" 'Yellow' }
} else {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Log '  reaplicacao automatica desligada (tarefa removida se existia)'
}

# ===================================================================================
#  Fim
# ===================================================================================
Set-Content -Path (Join-Path $LogDir 'freedom-tweaks.applied') -Value (Get-Date -Format 's') -ErrorAction SilentlyContinue
Log "Concluido. Reinicie para aplicar tudo (VBS, HAGS, servicos)." 'Green'

if ($Reboot) {
    & shutdown.exe /r /t 20 /c "Ajustes gaming aplicados. Reiniciando em 20 s."
} else {
    Write-Host "`nReinicie o PC para concluir. Log em $Log" -ForegroundColor Green
}
