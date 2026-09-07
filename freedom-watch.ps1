<#
=====================================================================================
  freedom-watch.ps1  -  reaplica o Clean Windows depois que o Windows se atualiza
=====================================================================================
  Roda sozinho no logon (tarefa agendada criada pelo freedom-tweaks.ps1 quando
  $Cfg.AutoReapplyAfterUpdate = $true). O que faz:

    1. Compara a versao atual do Windows com a que estava guardada.
    2. Se nao mudou nada, sai em silencio (nao incomoda o usuario).
    3. Se o Windows se atualizou, mostra um aviso na tela, cria um ponto de
       restauracao e roda o freedom-tweaks.ps1 de novo (atualizacoes de versao
       reinstalam Copilot, Widgets, OneDrive e reativam telemetria).

  Rodar na mao para testar:  powershell -ep bypass -f freedom-watch.ps1 -Force
  Log: C:\Windows\Setup\Scripts\freedom-watch.log
=====================================================================================
#>
[CmdletBinding()]
param(
    [switch]$Force,       # reaplica mesmo que a versao nao tenha mudado
    [switch]$Quiet        # sem janela de aviso
)

# A tarefa agendada ja roda elevada; ao rodar na mao, se eleva sozinho (grava em HKLM).
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($Force) { $a += '-Force' }
    if ($Quiet) { $a += '-Quiet' }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $a
    exit
}

$ErrorActionPreference = 'Continue'
$Dir = "$env:SystemRoot\Setup\Scripts"
$Log = Join-Path $Dir 'freedom-watch.log'
$Tweaks = Join-Path $Dir 'freedom-tweaks.ps1'
$StateKey = 'HKLM:\SOFTWARE\CleanWindows'

function Say([string]$m) {
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m
    Add-Content -Path $Log -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

# ---- versao atual do Windows: 25H2.26100.8037 ----
function Get-WinVersao {
    $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    try {
        $p = Get-ItemProperty $k -ErrorAction Stop
        $disp = if ($p.DisplayVersion) { $p.DisplayVersion } else { $p.ReleaseId }
        "{0}.{1}.{2}" -f $disp, $p.CurrentBuildNumber, $p.UBR
    } catch { '' }
}

$agora = Get-WinVersao
if (-not $agora) { Say 'nao consegui ler a versao do Windows'; exit }

$antes = try { (Get-ItemProperty $StateKey -Name LastWindowsVersion -ErrorAction Stop).LastWindowsVersion } catch { '' }

if (-not $Force -and $antes -eq $agora) { exit }            # nada mudou: sai calado
if (-not (Test-Path $Tweaks)) { Say "freedom-tweaks.ps1 nao encontrado em $Dir"; exit }

# Primeira execucao (sem estado guardado): so registra, nao reaplica do nada.
if (-not $Force -and [string]::IsNullOrWhiteSpace($antes)) {
    if (-not (Test-Path $StateKey)) { New-Item -Path $StateKey -Force | Out-Null }
    Set-ItemProperty -Path $StateKey -Name LastWindowsVersion -Value $agora -Force
    Say "primeira execucao; versao registrada: $agora"
    exit
}

Say "Windows mudou de '$antes' para '$agora': reaplicando os ajustes"

# ---- aviso na tela (fecha sozinho) ----
if (-not $Quiet) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        $f = New-Object System.Windows.Forms.Form
        $f.Text = 'Clean Windows'
        $f.ClientSize = New-Object System.Drawing.Size(520, 170)
        $f.StartPosition = 'CenterScreen'
        $f.FormBorderStyle = 'FixedDialog'
        $f.MaximizeBox = $false; $f.MinimizeBox = $false; $f.TopMost = $true
        $f.BackColor = [System.Drawing.Color]::White

        $t = New-Object System.Windows.Forms.Label
        $t.Text = 'O Windows foi atualizado'
        $t.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
        $t.Location = New-Object System.Drawing.Point(24, 22)
        $t.Size = New-Object System.Drawing.Size(470, 32)
        $f.Controls.Add($t)

        $d = New-Object System.Windows.Forms.Label
        $d.Text = ("Criando uma imagem de seguranca do sistema (ponto de restauracao) e" + [Environment]::NewLine +
                   "reaplicando os ajustes do Clean Windows." + [Environment]::NewLine + [Environment]::NewLine +
                   "Pode continuar usando o PC. Esta janela fecha sozinha.")
        $d.Font = New-Object System.Drawing.Font('Segoe UI', 10)
        $d.ForeColor = [System.Drawing.Color]::FromArgb(96, 96, 96)
        $d.Location = New-Object System.Drawing.Point(24, 58)
        $d.Size = New-Object System.Drawing.Size(470, 90)
        $f.Controls.Add($d)

        $tm = New-Object System.Windows.Forms.Timer
        $tm.Interval = 9000
        $tm.Add_Tick({ $tm.Stop(); $f.Close() })
        $tm.Start()
        [void]$f.Show()
        for ($i = 0; $i -lt 90 -and -not $f.IsDisposed; $i++) {
            [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 100
        }
        if (-not $f.IsDisposed) { $f.Close() }
    } catch { Say "aviso na tela falhou: $($_.Exception.Message)" }
}

# ---- reaplica ----
$p = Start-Process powershell.exe -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$Tweaks`"", '-RestorePoint'
     ) -PassThru -Wait -WindowStyle Minimized
Say "freedom-tweaks.ps1 terminou (codigo $($p.ExitCode))"

if (-not (Test-Path $StateKey)) { New-Item -Path $StateKey -Force | Out-Null }
Set-ItemProperty -Path $StateKey -Name LastWindowsVersion -Value $agora -Force
Set-ItemProperty -Path $StateKey -Name LastReapply -Value (Get-Date -Format 's') -Force
Say 'estado atualizado'
