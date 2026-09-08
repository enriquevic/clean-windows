<#
=====================================================================================
  freedom-restore.ps1  -  desfaz o Clean Windows (botao "Reativar")
=====================================================================================
  Volta o Windows ao comportamento PADRAO: religa transparencia, sombras e animacoes;
  reativa os servicos e as tarefas agendadas; remove as politicas de telemetria/
  Copilot/Widgets; restaura o popup do UAC; religa hibernacao e o Isolamento de Nucleo;
  e tenta reinstalar o OneDrive e os apps removidos (pela Loja/winget, quando possivel).

  Mede a "leveza" antes e depois de reativar, para o programa mostrar quanto o Windows
  ficou MAIS PESADO ao voltar ao padrao.

  Uso:  powershell -ep bypass -f freedom-restore.ps1
  Log:  C:\Windows\Setup\Scripts\freedom-restore.log
=====================================================================================
#>
[CmdletBinding()] param([switch]$Quiet)

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"") ; exit
}

$ErrorActionPreference = 'Continue'
$LogDir = "$env:SystemRoot\Setup\Scripts"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }
$Log = Join-Path $LogDir 'freedom-restore.log'
$CW  = 'HKLM:\SOFTWARE\CleanWindows'
function Log($m,$c='Gray'){ $l="[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'),$m; Write-Host $l -ForegroundColor $c; Add-Content $Log $l -Encoding UTF8 -EA SilentlyContinue }
function Section($m){ Log "==== $m ====" 'Cyan' }
function Get-Metricas {
    $ram=0; try { $os=Get-CimInstance Win32_OperatingSystem -EA Stop; $ram=[math]::Round(($os.TotalVisibleMemorySize-$os.FreePhysicalMemory)/1024) } catch {}
    $ini=0; foreach($rk in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'){ try{$ini+=@((Get-Item $rk -EA Stop).Property).Count}catch{} }
    [pscustomobject]@{ Processos=@(Get-Process -EA SilentlyContinue).Count; RamUsoMB=[int]$ram
        Servicos=@(Get-Service -EA SilentlyContinue|?{$_.Status -eq 'Running'}).Count
        Appx=@(Get-AppxPackage -EA SilentlyContinue).Count
        Tarefas=@(Get-ScheduledTask -EA SilentlyContinue|?{$_.State -eq 'Ready'}).Count; Inicio=$ini }
}
function Del-Key($path){ if(Test-Path $path){ try{ Remove-Item $path -Recurse -Force -EA Stop; Log "  removido: $path" }catch{} } }
function Set-U($path,$name,$val,$type='DWord'){ try{ if(-not(Test-Path $path)){New-Item $path -Force|Out-Null}; New-ItemProperty $path $name -Value $val -PropertyType $type -Force|Out-Null }catch{} }

Log "freedom-restore.ps1 iniciado por $env:USERNAME" 'Green'
$limpo = Get-Metricas
Log "estado atual (limpo): $($limpo.Processos) processos, $($limpo.RamUsoMB) MB, $($limpo.Servicos) servicos"

# ---- servicos e tarefas que o Clean Windows desativa (mesma lista) ----
$Services = @('DiagTrack','dmwappushservice','diagnosticshub.standardcollector.service','WerSvc','wercplsupport',
    'RetailDemo','MapsBroker','RemoteRegistry','Fax','WMPNetworkSvc','lfsvc','wisvc','MessagingService',
    'SEMgrSvc','WpcMonSvc','TrkWks','PhoneSvc','SysMain')
$Tasks = @(
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp',
    '\Microsoft\Windows\Application Experience\ProgramDataUpdater',
    '\Microsoft\Windows\Application Experience\PcaPatchDbTask',
    '\Microsoft\Windows\Application Experience\MareBackup',
    '\Microsoft\Windows\Application Experience\StartupAppTask',
    '\Microsoft\Windows\Autochk\Proxy',
    '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
    '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip',
    '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector',
    '\Microsoft\Windows\Feedback\Siuf\DmClient',
    '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload',
    '\Microsoft\Windows\Windows Error Reporting\QueueReporting',
    '\Microsoft\Windows\Maps\MapsUpdateTask','\Microsoft\Windows\Maps\MapsToastTask',
    '\Microsoft\Windows\Device Information\Device','\Microsoft\Windows\Device Information\Device User',
    '\Microsoft\Windows\NetTrace\GatherNetworkInfo',
    '\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem',
    '\Microsoft\Windows\PI\Sqm-Tasks',
    '\Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures',
    '\Microsoft\Windows\Flighting\OneSettings\RefreshCache')
# tipos de partida padrao (fallback se nao houver estado salvo)
$SvcPad = @{ DiagTrack='Automatic'; dmwappushservice='Manual'; 'diagnosticshub.standardcollector.service'='Manual';
    WerSvc='Manual'; wercplsupport='Manual'; RetailDemo='Manual'; MapsBroker='Automatic'; RemoteRegistry='Disabled';
    Fax='Manual'; WMPNetworkSvc='Manual'; lfsvc='Manual'; wisvc='Manual'; MessagingService='Manual'; SEMgrSvc='Manual';
    WpcMonSvc='Manual'; TrkWks='Automatic'; PhoneSvc='Manual'; SysMain='Automatic' }

# ---- 1. Servicos ----
Section "Reativando servicos"
$orig = @{}
try {
    $raw = (Get-ItemProperty $CW -Name ServicosOriginais -EA Stop).ServicosOriginais
    foreach($pair in ($raw -split ';')){ if($pair -match '='){ $k,$v=$pair -split '=',2; $orig[$k]=$v } }
} catch {}
foreach($n in $Services){
    $modo = if($orig.ContainsKey($n)){ $orig[$n] } elseif($SvcPad.ContainsKey($n)){ $SvcPad[$n] } else { 'Manual' }
    $modo = switch($modo){ 'Auto'{'Automatic'} 'Automatic'{'Automatic'} 'Disabled'{'Manual'} default{$modo} }
    try { Set-Service -Name $n -StartupType $modo -EA Stop; Log "  $n -> $modo" } catch {}
}

# ---- 2. Tarefas agendadas ----
Section "Reativando tarefas agendadas"
foreach($fp in $Tasks){
    $i=$fp.LastIndexOf('\'); $tp=$fp.Substring(0,$i+1); $tn=$fp.Substring($i+1)
    $t=Get-ScheduledTask -TaskPath $tp -TaskName $tn -EA SilentlyContinue
    if($t){ try{ $t|Enable-ScheduledTask -EA Stop|Out-Null }catch{} }
}

# ---- 3. Politicas (telemetria, Copilot, Widgets, etc.) de volta ao padrao ----
Section "Removendo politicas (volta ao padrao)"
$Pol='HKLM:\SOFTWARE\Policies\Microsoft\Windows'
foreach($k in "$Pol\DataCollection","$Pol\CloudContent","$Pol\WindowsCopilot","$Pol\WindowsAI","$Pol\Windows Search",
    "$Pol\System","$Pol\Windows Chat","$Pol\AppCompat","$Pol\Windows Error Reporting","$Pol\PreviewBuilds",
    "$Pol\DeliveryOptimization","$Pol\OneDrive","$Pol\GameDVR","$Pol\Windows Feeds","$Pol\Dsh",
    'HKLM:\SOFTWARE\Policies\Microsoft\Dsh','HKLM:\SOFTWARE\Policies\Microsoft\Edge',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'){ Del-Key $k }
Set-U 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications' ConfigureChatAutoInstall 1

# ---- 4. UAC de volta (popup padrao) ----
Section "UAC padrao (com popup)"
$sys='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
Set-U $sys ConsentPromptBehaviorAdmin 5
Set-U $sys PromptOnSecureDesktop 1
Set-U $sys EnableLUA 1

# ---- 5. Hibernacao e Isolamento de Nucleo (VBS) de volta ----
Section "Hibernacao e Isolamento de Nucleo"
& powercfg.exe /hibernate on 2>$null | Out-Null
Set-U 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' HiberbootEnabled 1
Set-U 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' EnableVirtualizationBasedSecurity 1
Set-U 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' Enabled 1

# ---- 6. Efeitos visuais de volta (usuario atual) ----
Section "Efeitos visuais (transparencia, sombras, animacoes)"
$Th='HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
$Adv='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-U $Th EnableTransparency 1
Set-U $Adv TaskbarAnimations 1
Set-U $Adv ListviewAlphaSelect 1
Set-U $Adv ListviewShadow 1
Set-U 'HKCU:\Software\Microsoft\Windows\DWM' EnableAeroPeek 1
Set-U 'HKCU:\Control Panel\Desktop\WindowMetrics' MinAnimate '1' String
Set-U 'HKCU:\Control Panel\Desktop' MenuShowDelay '400' String
Set-U 'HKCU:\Control Panel\Desktop' UserPreferencesMask ([byte[]](0x9E,0x1E,0x07,0x80,0x12,0x00,0x00,0x00)) Binary

# ---- 7. OneDrive e apps removidos (best-effort) ----
Section "Reinstalando OneDrive e apps (pela Loja/winget)"
if (Get-Command winget -EA SilentlyContinue) {
    & winget install --id Microsoft.OneDrive --silent --accept-package-agreements --accept-source-agreements 2>$null | Out-Null
    $apps = try { (Get-ItemProperty $CW -Name AppsRemovidos -EA Stop).AppsRemovidos -split ';' } catch { @() }
    $map = @{ 'Microsoft.MicrosoftSolitaireCollection'='9WZDNCRFHWD2'; 'Microsoft.WindowsAlarms'='9WZDNCRFJ3PR';
        'Microsoft.WindowsSoundRecorder'='9WZDNCRFHWKN'; 'Microsoft.ZuneMusic'='9WZDNCRFJ3PT'; 'Microsoft.ZuneVideo'='9WZDNCRFJ3P2';
        'Microsoft.WindowsMaps'='9WZDNCRDTBVB'; 'Clipchamp.Clipchamp'='9P1J8S7CCWWT'; 'Microsoft.Todos'='9NFTCH6J7T27';
        'Microsoft.BingWeather'='9WZDNCRFJ3Q2'; 'Microsoft.BingNews'='9WZDNCRFHVFW'; 'Microsoft.MicrosoftStickyNotes'='9NNCRFHVFW' }
    foreach($a in $apps){ $a=$a.Trim(); if($map.ContainsKey($a)){ try{ & winget install --id $map[$a] --source msstore --accept-package-agreements --accept-source-agreements 2>$null | Out-Null; Log "  reinstalado: $a" }catch{} } }
    Log "  apps que nao voltaram automaticamente podem ser reinstalados pela Microsoft Store."
} else { Log "  winget indisponivel; reinstale os apps pela Microsoft Store." 'Yellow' }

# ---- medicao final e sinal para o menu ----
Start-Sleep -Seconds 2
$pesado = Get-Metricas
foreach($par in @{ Limpo=$limpo; Pesado=$pesado }.GetEnumerator()){
    $pref=$par.Key; $m=$par.Value
    Set-U $CW "R_${pref}_Processos" $m.Processos; Set-U $CW "R_${pref}_RamMB" $m.RamUsoMB
    Set-U $CW "R_${pref}_Servicos" $m.Servicos;   Set-U $CW "R_${pref}_Appx" $m.Appx
    Set-U $CW "R_${pref}_Tarefas" $m.Tarefas;     Set-U $CW "R_${pref}_Inicio" $m.Inicio
}
Set-U $CW MostrarRestauracao 1
Set-U $CW LimpezaAplicada 0
Log "Concluido. Reinicie para o Windows voltar totalmente ao padrao." 'Green'
if (-not $Quiet) { Write-Host "`nReinicie o PC. Log em $Log" -ForegroundColor Green }
