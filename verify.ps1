<#
=====================================================================================
  verify.ps1  -  Confere se os ajustes do kit estao realmente aplicados
=====================================================================================
  powershell -ExecutionPolicy Bypass -File C:\Windows\Setup\Scripts\verify.ps1
=====================================================================================
#>
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Start-Process powershell.exe -Verb RunAs -ArgumentList @('-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`""); exit }

function Check([string]$what, [bool]$ok, [string]$detail = '') {
    $mark = if ($ok) { '[OK] ' } else { '[--] ' }
    $color = if ($ok) { 'Green' } else { 'Yellow' }
    Write-Host ("{0}{1,-52} {2}" -f $mark, $what, $detail) -ForegroundColor $color
}
function RegVal([string]$path, [string]$name) {
    try { (Get-ItemProperty -LiteralPath $path -Name $name -ErrorAction Stop).$name } catch { $null }
}
function SvcState([string]$n) { $s = Get-Service $n -ErrorAction SilentlyContinue; if ($s) { "$($s.Status)/$($s.StartType)" } else { 'inexistente' } }

$P = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows'
Write-Host "`n=== Telemetria ===" -ForegroundColor Cyan
Check 'AllowTelemetry = 0 (politica)'        ((RegVal "$P\DataCollection" AllowTelemetry) -eq 0)
foreach ($s in 'DiagTrack', 'dmwappushservice', 'WerSvc') {
    $st = Get-Service $s -ErrorAction SilentlyContinue
    Check "servico $s desabilitado" ($st -and $st.StartType -eq 'Disabled') (SvcState $s)
}
$appr = Get-ScheduledTask -TaskPath '\Microsoft\Windows\Application Experience\' -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'Microsoft Compatibility Appraiser*' }
if ($appr) {
    $bad = $appr | Where-Object { $_.State -ne 'Disabled' }
    Check 'tarefas Compatibility Appraiser desabilitadas' (-not $bad) (($appr | ForEach-Object { "$($_.TaskName)=$($_.State)" }) -join '; ')
} else {
    Check 'tarefas Compatibility Appraiser desabilitadas' $true 'tarefa nao existe nesta versao do Windows'
}

Write-Host "`n=== Privacidade / bloat ===" -ForegroundColor Cyan
Check 'Apps promovidos bloqueados (ConsumerFeatures)' ((RegVal "$P\CloudContent" DisableWindowsConsumerFeatures) -eq 1)
Check 'ID de publicidade desligado'                   ((RegVal 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' Enabled) -eq 0)
Check 'Copilot desligado (politica)'                  ((RegVal "$P\WindowsCopilot" TurnOffWindowsCopilot) -eq 1)
Check 'Recall desligado (politica)'                   ((RegVal "$P\WindowsAI" DisableAIDataAnalysis) -eq 1)
Check 'Widgets desligados'                            ((RegVal 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' AllowNewsAndInterests) -eq 0)
Check 'Bing na pesquisa desligado'                    ((RegVal 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' BingSearchEnabled) -eq 0)
Check 'OneDrive ausente'                              (-not (Get-Process OneDrive -ErrorAction SilentlyContinue) -and -not (Test-Path "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"))
$bloat = Get-AppxPackage -AllUsers | Where-Object { $_.Name -in 'Microsoft.BingNews', 'Microsoft.BingWeather', 'MSTeams', 'Clipchamp.Clipchamp', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.Copilot', 'MicrosoftWindows.Client.WebExperience' }
Check 'Bloatware removido'                            ($bloat.Count -eq 0) ($(if ($bloat) { ($bloat.Name -join ', ') }))

Write-Host "`n=== Jogos ===" -ForegroundColor Cyan
Check 'Game Mode ligado'                              ((RegVal 'HKCU:\Software\Microsoft\GameBar' AutoGameModeEnabled) -eq 1)
Check 'Game DVR desligado'                            ((RegVal 'HKCU:\System\GameConfigStore' GameDVR_Enabled) -eq 0)
Check 'HAGS (HwSchMode = 2)'                          ((RegVal 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' HwSchMode) -eq 2)
Check 'Aceleracao do mouse desligada'                 ((RegVal 'HKCU:\Control Panel\Mouse' MouseSpeed) -eq '0')
Check 'Atalho Teclas de Aderencia desligado'          ((RegVal 'HKCU:\Control Panel\Accessibility\StickyKeys' Flags) -eq '506')
$mm = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
$nti = RegVal $mm NetworkThrottlingIndex
Check 'MMCSS NetworkThrottlingIndex = 0xffffffff'     ($nti -eq -1 -or $nti -eq 4294967295) "valor atual=$nti SystemResponsiveness=$(RegVal $mm SystemResponsiveness)"
$dg = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction SilentlyContinue
$vbsRunning = $dg -and $dg.VirtualizationBasedSecurityStatus -eq 2
Check 'VBS / Integridade da memoria NAO em execucao'  (-not $vbsRunning) $(if ($dg) { "status=$($dg.VirtualizationBasedSecurityStatus) servicos=$($dg.SecurityServicesRunning -join ',')" })
$active = (& powercfg.exe /getactivescheme) -join ' '
Check 'Plano de energia (Desempenho Maximo/Alto)'     ($active -match 'Ultimate|Desempenho M|Alto desempenho|High') $active
$hib = RegVal 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' HiberbootEnabled
Check 'Inicializacao Rapida desligada'                ($hib -eq 0)

Write-Host "`n=== Seguranca (devem continuar LIGADOS) ===" -ForegroundColor Cyan
$mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
Check 'Microsoft Defender em tempo real'              ($mp -and $mp.RealTimeProtectionEnabled)
$sb = try { Confirm-SecureBootUEFI } catch { $false }
Check 'Secure Boot'                                   $sb
$tpm = Get-Tpm -ErrorAction SilentlyContinue
Check 'TPM presente e pronto'                         ($tpm -and $tpm.TpmReady)
$wu = Get-Service wuauserv -ErrorAction SilentlyContinue
Check 'Windows Update nao desabilitado'               ($wu -and $wu.StartType -ne 'Disabled') (SvcState 'wuauserv')

Write-Host "`nLog do primeiro logon: $env:SystemRoot\Setup\Scripts\freedom-tweaks.log`n"
