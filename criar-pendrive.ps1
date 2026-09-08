<#
=====================================================================================
  criar-pendrive.ps1  -  Clean Windows para o kit Clean Windows (Windows 10/11)
=====================================================================================
  Janela simples: escolhe a ISO do Windows, o pendrive, a licenca do PC de destino, e
  clica em "Criar". A licenca decide se o autounattend leva chave ou nao:
    - PC de marca  -> XML sem chave: o instalador usa a gravada na placa (edicao certa, ativa)
    - PC montado   -> chave generica de instalacao (Pro ou Home); nao ativa, so escolhe a edicao
  O programa:
    1. Apaga o pendrive e cria GPT + particao FAT32 (boot UEFI em qualquer PC moderno)
    2. Copia o conteudo da ISO (oficial da Microsoft ou a CleanWindows.iso do build-iso.ps1)
    3. Se o install.wim passar de 4 GB (limite do FAT32), divide em install.swm/install2.swm
       com o DISM do proprio Windows. O instalador do Windows le .swm nativamente.
    4. (opcional) Injeta o kit: autounattend.xml na raiz + scripts em sources\$OEM$ e \Scripts
    5. (opcional) Copia uma pasta de drivers para \Drivers no pendrive
  Somente ferramentas nativas do Windows: Storage cmdlets, robocopy, DISM. Nada baixado.

  Limites conhecidos (de proposito, para manter simples):
    - Boot UEFI apenas (Windows 11 exige UEFI). PCs so-BIOS/legacy nao sao suportados.
    - FAT32 e formatado com ate 32 GB; em pendrives maiores o resto vira uma particao
      NTFS "DADOS" para uso comum.
    - ISO com install.esd maior que 4 GB (Media Creation Tool) nao e suportada: use a ISO
      do site da Microsoft (install.wim) ou a CleanWindows.iso gerada pelo build-iso.ps1.

  Uso: duplo clique em criar-pendrive.cmd (ou: powershell -ep bypass -sta -f criar-pendrive.ps1)
       -AllowFixedDisk  -> lista tambem discos nao-USB (SO para testar dentro de uma VM!)
=====================================================================================
#>
[CmdletBinding()]
param([switch]$AllowFixedDisk)

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-File', "`"$PSCommandPath`"")
    if ($AllowFixedDisk) { $argList += '-AllowFixedDisk' }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argList
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:KitDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:KitFiles = @('autounattend.xml', 'freedom-tweaks.ps1', 'freedom-watch.ps1', 'freedom-restore.ps1', 'apps.ps1', 'verify.ps1', 'catalogo.ps1')
$script:HasKit   = @($script:KitFiles | Where-Object { -not (Test-Path (Join-Path $script:KitDir $_)) }).Count -eq 0
$script:Disks    = @()
$script:Busy     = $false
# Escolha do que sera aplicado na instalacao (checklist). Vai como selecao.txt dentro do kit.
$script:SelPendrive = Join-Path $env:TEMP 'clean-windows-selecao-pendrive.txt'
$script:Catalogo    = Join-Path $script:KitDir 'catalogo.ps1'
if (Test-Path $script:Catalogo) { . $script:Catalogo }

# ----------------------------------------------------------------------------- janela
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Clean Windows - criar pendrive de instalacao'
$form.ClientSize = New-Object System.Drawing.Size(660, 540)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

function Add-Control($ctl, $x, $y, $w, $h) {
    $ctl.Location = New-Object System.Drawing.Point($x, $y)
    $ctl.Size     = New-Object System.Drawing.Size($w, $h)
    $form.Controls.Add($ctl)
    $ctl
}
function New-Label($text, $x, $y, $w = 110) {
    $l = New-Object System.Windows.Forms.Label; $l.Text = $text; $l.TextAlign = 'MiddleLeft'
    Add-Control $l $x $y $w 24
}
function New-Button($text, $x, $y, $w = 100, $h = 26) {
    $b = New-Object System.Windows.Forms.Button; $b.Text = $text
    Add-Control $b $x $y $w $h
}

[void](New-Label 'ISO (ou DVD, ex. D:\):' 12 14)
$txtIso = Add-Control (New-Object System.Windows.Forms.TextBox) 125 14 340 24
$btnDvd = New-Button 'DVD' 470 13 70
$btnIso = New-Button 'Procurar...' 548 13

[void](New-Label 'Pendrive:' 12 48)
$cmbUsb = New-Object System.Windows.Forms.ComboBox; $cmbUsb.DropDownStyle = 'DropDownList'
[void](Add-Control $cmbUsb 125 48 415 24)
$btnRefresh = New-Button 'Atualizar' 548 47

$chkKit = New-Object System.Windows.Forms.CheckBox
$chkKit.Text = 'Incluir o kit (instalacao automatica: autounattend + scripts)'
$chkKit.Checked = $script:HasKit; $chkKit.Enabled = $script:HasKit
[void](Add-Control $chkKit 125 82 385 22)
$btnSel = New-Button 'Escolher itens...' 515 81 130 24
$btnSel.Enabled = $script:HasKit

[void](New-Label 'Licenca do destino:' 12 108)
$cmbLic = New-Object System.Windows.Forms.ComboBox
$cmbLic.DropDownStyle = 'DropDownList'
$cmbLic.Enabled = $script:HasKit
[void](Add-Control $cmbLic 125 106 415 24)
[void]$cmbLic.Items.Add('PC de marca (Acer, Dell, Lenovo...) - usa a chave gravada na placa')
[void]$cmbLic.Items.Add('PC montado / sem licenca de fabrica - instalar Windows 11 Pro')
[void]$cmbLic.Items.Add('PC montado / sem licenca de fabrica - instalar Windows 11 Home')
$cmbLic.SelectedIndex = 0

[void](New-Label 'Drivers (opcional):' 12 138)
$txtDrv = Add-Control (New-Object System.Windows.Forms.TextBox) 125 138 415 24
$btnDrv = New-Button 'Pasta...' 548 137

$btnGo = New-Button 'Criar pendrive' 125 176 200 34
$btnGo.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)

$lblWarn = New-Label '' 335 176 315
$lblWarn.ForeColor = [System.Drawing.Color]::Firebrick
if ($AllowFixedDisk) { $lblWarn.Text = 'MODO DE TESTE: discos internos tambem listados!' }
elseif (-not $script:HasKit) { $lblWarn.Text = 'Kit nao encontrado ao lado do script (pendrive sem automacao).' }

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true; $txtLog.ReadOnly = $true; $txtLog.ScrollBars = 'Vertical'
$txtLog.Font = New-Object System.Drawing.Font('Consolas', 9)
$txtLog.BackColor = [System.Drawing.Color]::White
[void](Add-Control $txtLog 12 222 636 306)

# ----------------------------------------------------------------------------- helpers
function Log([string]$m) {
    $txtLog.AppendText(("[{0}] {1}`r`n" -f (Get-Date -Format 'HH:mm:ss'), $m))
    [System.Windows.Forms.Application]::DoEvents()
}
function Wait-Idle([int]$ms = 400) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds $ms }
function Msg([string]$text, [string]$title = 'Criar pendrive', [string]$icon = 'Information') {
    [void][System.Windows.Forms.MessageBox]::Show($form, $text, $title, 'OK', $icon)
}
# Le a chave OEM gravada na placa (tabela ACPI MSDM). Vazio = este PC nao tem licenca de fabrica.
function Get-OemInfo {
    $modelo = try { (Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).Model } catch { '' }
    $fab    = try { (Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).Manufacturer } catch { '' }
    $chave  = try { (Get-CimInstance -ClassName SoftwareLicensingService -ErrorAction Stop).OA3xOriginalProductKey } catch { '' }
    [pscustomobject]@{
        Nome    = (("$fab $modelo").Trim())
        TemOem  = -not [string]::IsNullOrWhiteSpace($chave)
        Edicao  = try { (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name EditionID -ErrorAction Stop).EditionID } catch { '' }
    }
}
function Find-WindowsDvd {
    foreach ($v in (Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'CD-ROM' })) {
        $root = "$($v.DriveLetter):\"
        if ([System.IO.File]::Exists("${root}sources\boot.wim")) { return $root }
    }
    return $null
}
function Get-VolumeSummary {
    (Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter } | Sort-Object DriveLetter |
        ForEach-Object { "$($_.DriveLetter): [$($_.DriveType)] $($_.FileSystemLabel)" }) -join '   '
}
function Get-CandidateDisks {
    Get-Disk | Where-Object {
        -not $_.IsSystem -and -not $_.IsBoot -and $_.Size -gt 0 -and
        ($_.BusType -eq 'USB' -or $AllowFixedDisk)
    } | Sort-Object Number
}
function Refresh-Disks {
    $cmbUsb.Items.Clear()
    $script:Disks = @(Get-CandidateDisks)
    foreach ($d in $script:Disks) {
        [void]$cmbUsb.Items.Add(('Disco {0}   {1}   {2:N1} GB   [{3}]' -f $d.Number, $d.FriendlyName, ($d.Size / 1GB), $d.BusType))
    }
    if ($cmbUsb.Items.Count -gt 0) { $cmbUsb.SelectedIndex = 0 } else { Log 'Nenhum pendrive USB encontrado. Conecte um e clique em Atualizar.' }
}

# ----------------------------------------------------------------------------- trabalho
function Invoke-Build {
    $iso = $txtIso.Text.Trim('"', ' ')
    if ($iso -match '^[A-Za-z]:$') { $iso += '\' }
    $isFolder = [System.IO.Directory]::Exists($iso)
    if (-not $isFolder -and -not [System.IO.File]::Exists($iso)) {
        Log ("Caminho nao encontrado: '$iso'. Unidades: " + (Get-VolumeSummary))
        Msg "Nao encontrei '$iso'.`n`nUse Procurar... para uma ISO, ou o botao DVD para localizar a unidade com a ISO do Windows." 'Atencao' 'Warning'; return
    }
    if ($cmbUsb.SelectedIndex -lt 0 -or $cmbUsb.SelectedIndex -ge $script:Disks.Count) { Msg 'Selecione o pendrive.' 'Atencao' 'Warning'; return }
    $disk = Get-Disk -Number $script:Disks[$cmbUsb.SelectedIndex].Number
    $withKit = $chkKit.Checked; $lic = $cmbLic.SelectedIndex; $drv = $txtDrv.Text.Trim('"', ' ')
    if ($drv -and -not (Test-Path -LiteralPath $drv)) { Msg 'Pasta de drivers nao encontrada.' 'Atencao' 'Warning'; return }
    if ($disk.IsSystem -or $disk.IsBoot) { Msg 'Esse e o disco do sistema. Recusado.' 'Atencao' 'Error'; return }

    $q = "TODOS OS DADOS do Disco $($disk.Number) serao APAGADOS:`n`n$($disk.FriendlyName)  -  $([math]::Round($disk.Size / 1GB, 1)) GB  [$($disk.BusType)]`n`nContinuar?"
    $r = [System.Windows.Forms.MessageBox]::Show($form, $q, 'Confirmar', 'YesNo', 'Warning', 'Button2')
    if ($r -ne 'Yes') { return }

    $script:Busy = $true; $btnGo.Enabled = $false
    $mounted = $false; $dst = $null
    try {
        Log "Origem: $iso"
        if ($isFolder) {
            $src = $iso.TrimEnd('\')
            Log 'Origem e uma pasta/unidade: usando diretamente.'
        } else {
            Log 'Montando a ISO...'
            Mount-DiskImage -ImagePath $iso -ErrorAction Stop | Out-Null; $mounted = $true
            $src = $null
            for ($i = 0; $i -lt 15 -and -not $src; $i++) {
                Wait-Idle 1000
                $l = (Get-DiskImage -ImagePath $iso -ErrorAction SilentlyContinue | Get-Volume -ErrorAction SilentlyContinue).DriveLetter
                if ($l) { $src = "${l}:" }
            }
            if (-not $src) { throw 'Nao consegui obter a letra da ISO montada.' }
        }
        if (-not [System.IO.File]::Exists("$src\sources\boot.wim")) { throw 'Isto nao parece uma ISO de instalacao do Windows (sources\boot.wim ausente).' }
        if (-not [System.IO.File]::Exists("$src\efi\boot\bootx64.efi")) { throw 'ISO sem boot UEFI (efi\boot\bootx64.efi ausente).' }

        $wim = "$src\sources\install.wim"; $esd = "$src\sources\install.esd"
        $wimLen = if ([System.IO.File]::Exists($wim)) { (New-Object System.IO.FileInfo $wim).Length } else { 0 }
        $esdLen = if ([System.IO.File]::Exists($esd)) { (New-Object System.IO.FileInfo $esd).Length } else { 0 }
        $bigImage = ($wimLen -ge 4GB) -or ($esdLen -ge 4GB)
        $imgName = if ($wimLen -ge 4GB) { 'install.wim' } elseif ($esdLen -ge 4GB) { 'install.esd' } else { $null }

        # Win11 24H2/25H2 pode cifrar automaticamente discos de dados fixos (Device Encryption/
        # BitLocker), o que torna a midia ilegivel para o firmware. Prevenimos antes de criar.
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker' -Name PreventDeviceEncryption -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        Log "Apagando o Disco $($disk.Number) e criando GPT + FAT32..."
        Set-Disk -Number $disk.Number -IsOffline $false -ErrorAction SilentlyContinue
        Set-Disk -Number $disk.Number -IsReadOnly $false -ErrorAction SilentlyContinue
        # Solta as letras/volumes antigos DESTE disco antes de apagar. Sem isso o Windows pode
        # manter o volume antigo montado, a nova particao herda a mesma letra e a copia vai
        # parar num volume fantasma (o disco fica vazio no fim).
        foreach ($op in (Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue)) {
            if ($op.DriveLetter) {
                try { Remove-PartitionAccessPath -DiskNumber $disk.Number -PartitionNumber $op.PartitionNumber -AccessPath "$($op.DriveLetter):\" -ErrorAction Stop } catch {}
            }
        }
        Wait-Idle 800
        if ((Get-Disk -Number $disk.Number).PartitionStyle -ne 'RAW') {
            Clear-Disk -Number $disk.Number -RemoveData -RemoveOEM -Confirm:$false -ErrorAction Stop
        }
        Initialize-Disk -Number $disk.Number -PartitionStyle GPT -ErrorAction Stop
        Wait-Idle 1000
        # O Initialize-Disk cria uma particao reservada (MSR) automatica. Removemos: midia de
        # instalacao nao deve ter MSR, e queremos uma unica particao de boot.
        Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue |
            Remove-Partition -Confirm:$false -ErrorAction SilentlyContinue
        Wait-Idle 500
        function Disable-Bl([string]$mp) {
            try {
                $mb = "$env:SystemRoot\System32\manage-bde.exe"
                if (Test-Path $mb) { & $mb -off $mp 2>&1 | Out-Null }
                Disable-BitLocker -MountPoint $mp -ErrorAction SilentlyContinue | Out-Null
                for ($bi = 0; $bi -lt 60; $bi++) {
                    $bst = (Get-BitLockerVolume -MountPoint $mp -ErrorAction SilentlyContinue).VolumeStatus
                    if (-not $bst -or $bst -eq 'FullyDecrypted') { break }
                    if ($bi -eq 0) { Log "Aguardando o BitLocker desligar no $mp..." }
                    Wait-Idle 2000
                }
            } catch {}
        }

        # ==== Particoes ====
        # O Windows Setup exige a imagem em \sources\ NA MESMA particao de boot (ele NAO procura
        # em outros volumes - testado). Como o FAT32 nao aceita arquivo > 4 GB, o install.wim
        # grande e DIVIDIDO em install.swm/install2.swm com o DISM (metodo oficial da Microsoft).
        # Particao unica FAT32, sem letra ate formatar (evita o aviso "Formate o disco").
        $espMax = 32GB - 64MB
        if ($disk.Size -le 32GB) {
            $part = New-Partition -DiskNumber $disk.Number -UseMaximumSize -ErrorAction Stop
        } else {
            $part = New-Partition -DiskNumber $disk.Number -Size $espMax -ErrorAction Stop
        }
        Format-Volume -Partition $part -FileSystem FAT32 -NewFileSystemLabel 'CLEANWIN' -Confirm:$false -ErrorAction Stop | Out-Null
        $part | Add-PartitionAccessPath -AssignDriveLetter -ErrorAction Stop
        Update-Disk -Number $disk.Number -ErrorAction SilentlyContinue
        try { Update-HostStorageCache -ErrorAction SilentlyContinue } catch {}
        Wait-Idle 800
        $letter = (Get-Partition -DiskNumber $disk.Number -PartitionNumber $part.PartitionNumber).DriveLetter
        if (-not $letter) { throw 'Nao consegui atribuir letra a particao de boot.' }
        $dst = "${letter}:"
        Log "Particao de boot: $dst (FAT32, $([math]::Round($part.Size / 1GB, 1)) GB)"
        Disable-Bl $dst
        $dst2 = $null
        if ($disk.Size -gt 32GB + 1GB) {
            try {
                $p2 = New-Partition -DiskNumber $disk.Number -UseMaximumSize -ErrorAction Stop
                Format-Volume -Partition $p2 -FileSystem NTFS -NewFileSystemLabel 'DADOS' -Confirm:$false -ErrorAction Stop | Out-Null
                $p2 | Add-PartitionAccessPath -AssignDriveLetter -ErrorAction Stop
                $l2 = (Get-Partition -DiskNumber $disk.Number -PartitionNumber $p2.PartitionNumber).DriveLetter
                $dst2 = "${l2}:"; Log "Particao extra para uso comum: $dst2 (NTFS)"
                Disable-Bl $dst2
            } catch { $dst2 = $null }
        }

        # ==== Copia ====
        Log 'Copiando os arquivos da ISO (varios minutos, a janela pode parecer parada)...'
        $rcArgs = @("$src\", "$dst\", '/E', '/R:1', '/W:1', '/NFL', '/NDL', '/NJH', '/NJS', '/NP')
        if ($bigImage) { $rcArgs += @('/XF', 'install.wim', 'install.esd') }
        $p = Start-Process -FilePath robocopy.exe -ArgumentList $rcArgs -PassThru -WindowStyle Hidden
        while (-not $p.HasExited) { Wait-Idle 500 }
        if ($p.ExitCode -ge 8) { throw "robocopy falhou (codigo $($p.ExitCode))" }
        & attrib.exe -R "$dst\*" /S /D | Out-Null
        $copied = (Get-ChildItem -LiteralPath $dst -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum)
        Log "Boot copiado: $($copied.Count) arquivos, $([math]::Round($copied.Sum / 1GB, 2)) GB."

        if ($bigImage) {
            # Le a imagem 1x da origem para um NTFS local (dividir direto de DVD/pendrive lento
            # causa "dispositivo nao esta pronto"), depois divide para o pendrive.
            $tmpDir = Join-Path $env:SystemDrive 'criar-pendrive-tmp'
            New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
            $tmpImg = Join-Path $tmpDir $imgName
            $imgLen = [math]::Max($wimLen, $esdLen)
            $freeC = (Get-PSDrive ($env:SystemDrive.TrimEnd(':')) -ErrorAction SilentlyContinue).Free
            if ($freeC -and $freeC -lt ($imgLen + 2GB)) { throw "Sem espaco em $env:SystemDrive para a copia temporaria de $imgName ($([math]::Round($imgLen/1GB,1)) GB)." }
            Log "Copiando $imgName ($([math]::Round($imgLen / 1GB, 2)) GB) para $tmpDir (varios minutos)..."
            $rc2 = Start-Process robocopy.exe -ArgumentList @("$src\sources", $tmpDir, $imgName, '/R:2', '/W:5', '/NFL', '/NDL', '/NJH', '/NJS', '/NP') -PassThru -WindowStyle Hidden
            while (-not $rc2.HasExited) { Wait-Idle 500 }
            if (-not [System.IO.File]::Exists($tmpImg)) { throw "Nao consegui copiar $imgName da origem (robocopy codigo $($rc2.ExitCode))." }

            Log 'Dividindo a imagem em .swm de 3,8 GB com o DISM (varios minutos)...'
            $dismLog = Join-Path $env:TEMP 'criar-pendrive-dism.log'
            $dismOut = Join-Path $env:TEMP 'criar-pendrive-dism-out.txt'
            Remove-Item $dismLog, $dismOut -Force -ErrorAction SilentlyContinue
            $dArgs = @('/Split-Image', "/ImageFile:`"$tmpImg`"", "/SWMFile:`"$dst\sources\install.swm`"", '/FileSize:3800', "/LogPath:`"$dismLog`"")
            $pd = Start-Process -FilePath "$env:SystemRoot\System32\dism.exe" -ArgumentList $dArgs -PassThru -NoNewWindow -RedirectStandardOutput $dismOut
            while (-not $pd.HasExited) { Wait-Idle 800 }
            try { $pd.WaitForExit() } catch {}
            Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
            if (-not [System.IO.File]::Exists("$dst\sources\install.swm")) {
                $tail = (Get-Content $dismOut -ErrorAction SilentlyContinue | Where-Object { $_.Trim() } | Select-Object -Last 6) -join ' | '
                throw "DISM /Split-Image nao gerou install.swm. $tail  [log: $dismLog]"
            }
            # Grava o cache AGORA: os .swm sao enormes e podem ficar so em memoria.
            try { Write-VolumeCache -DriveLetter $letter -ErrorAction SilentlyContinue } catch {}
            Wait-Idle 2000
            $swm = Get-ChildItem "$dst\sources\install*.swm" | Sort-Object Name
            Log ('Partes: ' + (($swm | ForEach-Object { "$($_.Name) ($([math]::Round($_.Length / 1GB, 2)) GB)" }) -join ', '))
            $somaSwm = ($swm | Measure-Object -Property Length -Sum).Sum
            if ($somaSwm -lt ($imgLen * 0.8)) { throw "As partes .swm somam so $([math]::Round($somaSwm/1GB,2)) GB para uma imagem de $([math]::Round($imgLen/1GB,2)) GB. Gravacao incompleta." }
        }

        if ($withKit) {
            Log 'Injetando o kit (autounattend.xml + scripts)...'
            $xml = Get-Content -LiteralPath (Join-Path $script:KitDir 'autounattend.xml') -Raw
            switch ($lic) {
                0 {   # PC de marca: sem chave no XML -> o instalador le a chave da placa (MSDM)
                    $xml2 = [regex]::Replace($xml, '\r?\n[ \t]*<ProductKey>.*?</ProductKey>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
                    if ($xml2 -ne $xml) { Log '  sem chave no XML: o instalador vai usar a chave gravada na placa do PC de destino' }
                    $xml = $xml2
                }
                1 { Log '  chave generica de instalacao do Windows 11 Pro (nao ativa; ative depois com a sua)' }
                2 {   # troca a chave generica de Pro pela de Home
                    $xml = $xml.Replace('VK7JG-NPHTM-C97JM-9MPGT-3V66T', 'YTMG3-N6DKC-DKB77-7M9GH-8HVX7')
                    Log '  chave generica de instalacao do Windows 11 Home (nao ativa; ative depois com a sua)'
                }
            }
            $enc = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText("$dst\autounattend.xml", $xml, $enc)
            [System.IO.File]::WriteAllText("$dst\sources\autounattend.xml", $xml, $enc)   # p/ midia vista como disco fixo
            $oemDir = Join-Path $dst 'sources\$OEM$\$$\Setup\Scripts'
            New-Item -ItemType Directory -Force -Path $oemDir, "$dst\Scripts" | Out-Null
            foreach ($f in 'freedom-tweaks.ps1', 'freedom-watch.ps1', 'freedom-restore.ps1', 'apps.ps1', 'verify.ps1', 'catalogo.ps1') {
                $fp = Join-Path $script:KitDir $f
                if (Test-Path $fp) {
                    Copy-Item -LiteralPath $fp -Destination $oemDir -Force
                    Copy-Item -LiteralPath $fp -Destination "$dst\Scripts" -Force
                }
            }
            # leva a escolha do usuario (checklist), se houver: freedom-tweaks a le no 1o logon
            if (Test-Path $script:SelPendrive) {
                Copy-Item -LiteralPath $script:SelPendrive -Destination (Join-Path $oemDir 'selecao.txt') -Force
                Copy-Item -LiteralPath $script:SelPendrive -Destination "$dst\Scripts\selecao.txt" -Force
                Log '  selecao personalizada incluida (selecao.txt).'
            }
            Log '  kit injetado.'
        }

        # ==== Verificacao (nao dizer CONCLUIDO sem conferir que os arquivos existem) ====
        Log 'Conferindo a midia...'
        $must = @("$dst\efi\boot\bootx64.efi", "$dst\sources\boot.wim", "$dst\bootmgr")
        if ($withKit) { $must += "$dst\autounattend.xml" }
        if ($bigImage) { $must += "$dst\sources\install.swm" } else { $must += "$dst\sources\$(if ($wimLen -gt 0) {'install.wim'} else {'install.esd'})" }
        $faltando = @($must | Where-Object { -not [System.IO.File]::Exists($_) })
        if ($faltando.Count -gt 0) {
            throw ("Arquivos essenciais nao foram gravados: " + ($faltando -join ', ') +
                   ". O pendrive NAO esta pronto. Tire e recoloque o pendrive e rode de novo.")
        }
        $rootCount = @(Get-ChildItem -LiteralPath "$dst\" -Force -ErrorAction SilentlyContinue).Count
        Log "  OK: bootx64.efi, boot.wim, bootmgr presentes ($rootCount itens na raiz de $dst)."

        # IMPORTANTE: a particao de boot fica como "Basic data", NAO como EFI System Partition.
        # Marcar como ESP faz o Windows OCULTAR o volume e nao dar letra a ele; ai o proprio
        # instalador nao consegue ler \sources\ e mostra "Instalar driver para mostrar o
        # hardware". E assim que o Rufus e a ferramenta da Microsoft fazem: o firmware UEFI
        # acha o \EFI\BOOT\BOOTX64.EFI em pendrive removivel independente do tipo da particao.

        # Grava tudo que estiver em cache antes de terminar.
        foreach ($fl in @($letter, $(if ($dst2) { $dst2.TrimEnd(':') }))) {
            if ($fl) { try { Write-VolumeCache -DriveLetter $fl -ErrorAction SilentlyContinue } catch {} }
        }
        Wait-Idle 1500

        if ($drv) {
            Log "Copiando drivers para $dst\Drivers..."
            Copy-Item -LiteralPath $drv -Destination "$dst\Drivers" -Recurse -Force
            Log '  no instalador: "Carregar Driver" > Procurar > pendrive > Drivers.'
        }

        Log "CONCLUIDO. Pendrive $dst pronto para boot UEFI. Ejete com seguranca antes de remover."
        Msg "Pendrive pronto ($dst).`n`nNo PC de destino: menu de boot da BIOS (F12/F11/F8/Del), escolha o pendrive em modo UEFI e aperte uma tecla no 'Press any key'."
    }
    catch {
        Log "ERRO: $($_.Exception.Message)"
        Msg "Falhou:`n`n$($_.Exception.Message)" 'Erro' 'Error'
    }
    finally {
        if ($mounted) { Dismount-DiskImage -ImagePath $iso -ErrorAction SilentlyContinue | Out-Null }
        $script:Busy = $false; $btnGo.Enabled = $true
    }
}

# ----------------------------------------------------------------------------- eventos
$btnIso.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = 'Imagem ISO (*.iso)|*.iso'; $dlg.Title = 'Escolha a ISO do Windows'
    if ($dlg.ShowDialog($form) -eq 'OK') { $txtIso.Text = $dlg.FileName }
})
$btnDrv.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Pasta com os drivers (.inf) a copiar para o pendrive'
    if ($dlg.ShowDialog($form) -eq 'OK') { $txtDrv.Text = $dlg.SelectedPath }
})
$btnDvd.Add_Click({
    $d = Find-WindowsDvd
    if ($d) { $txtIso.Text = $d; Log "DVD com instalacao do Windows encontrado em $d" }
    else { Log ('Nenhum DVD com sources\boot.wim. Unidades: ' + (Get-VolumeSummary)); Msg 'Nenhum DVD de instalacao do Windows encontrado.' 'Atencao' 'Warning' }
})
$btnRefresh.Add_Click({ Refresh-Disks })
$btnGo.Add_Click({ Invoke-Build })
$chkKit.Add_CheckedChanged({ $cmbLic.Enabled = $chkKit.Checked; $btnSel.Enabled = $chkKit.Checked })
$btnSel.Add_Click({
    if (-not (Get-Command Show-Checklist -ErrorAction SilentlyContinue)) {
        Msg 'catalogo.ps1 nao encontrado ao lado do script; nao da para escolher os itens.' 'Atencao' 'Warning'; return
    }
    if (Show-Checklist -Parent $form -SelecaoPath $script:SelPendrive -Contexto 'Instalacao pelo pendrive') {
        $n = @(Get-Content -LiteralPath $script:SelPendrive -EA SilentlyContinue | Where-Object { $_.Trim() -and -not $_.StartsWith('#') }).Count
        Log "Selecao personalizada salva: $n itens marcados (vao junto no pendrive)."
    }
})
$form.Add_FormClosing({ if ($script:Busy) { $_.Cancel = $true; Msg 'Aguarde terminar antes de fechar.' 'Atencao' 'Warning' } })
$form.Add_Shown({
    Log ('Kit: ' + $(if ($script:HasKit) { $script:KitDir } else { 'NAO encontrado (coloque este script na pasta do kit)' }))
    Log ('Unidades: ' + (Get-VolumeSummary))
    $oi = Get-OemInfo
    if ($oi.TemOem) {
        Log ("Este PC: $($oi.Nome) - TEM chave de fabrica na placa" + $(if ($oi.Edicao) { " (edicao $($oi.Edicao))" }))
        Log '  Se o pendrive e para ESTE PC, deixe "PC de marca" selecionado em Licenca do destino.'
    } else {
        Log ("Este PC: $($oi.Nome) - sem chave de fabrica na placa")
    }
    $d = Find-WindowsDvd
    if ($d) { $txtIso.Text = $d; Log "DVD com instalacao do Windows encontrado em $d (pode trocar por uma ISO em Procurar...)" }
    Refresh-Disks
})

[void]$form.ShowDialog()
