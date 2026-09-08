<#
=====================================================================================
  Clean Windows  -  menu principal
=====================================================================================
  Une os dois caminhos do projeto numa janela so:

    1) Limpar ESTE Windows        -> roda o freedom-tweaks.ps1 na maquina atual
    2) Criar pendrive de instalacao -> abre o criar-pendrive.ps1 (Windows do zero)

  Uso: duplo clique em clean-windows.cmd
       ou: powershell -ep bypass -sta -f clean-windows.ps1  [-AllowFixedDisk]

  -AllowFixedDisk so serve para testar dentro de uma VM: faz a tela do pendrive listar
  tambem discos internos. NAO use no PC real.
=====================================================================================
#>
[CmdletBinding()]
param([switch]$AllowFixedDisk)

# ===================================================================================
#  CONFIGURACAO DO AUTOR  -  preencha aqui e nada mais precisa mudar
# ===================================================================================
$Versao = '1.4'

# Para onde vai o feedback dos usuarios (abre o programa de e-mail da pessoa).
$EmailFeedback = 'roothub.softwares@gmail.com'

# Chave Pix (CPF, e-mail, telefone ou aleatoria). Deixe '' para esconder a opcao Pix.
$ChavePix = '992ffd12-4fa7-407e-bde9-204ac017c16a'

# Pagina de doacao internacional, ex.: 'https://ko-fi.com/seu-usuario'
# Deixe '' para esconder a opcao.
$UrlDonativo = ''

# Verificacao de novas versoes: repositorio no formato 'usuario/repo' no GitHub.
# A cada abertura o programa pergunta ao GitHub qual a ultima Release e, se for mais nova
# que $Versao, oferece baixar. Deixe '' para desligar a verificacao.
$RepoUpdate = 'enriquevic/clean-windows'
# ===================================================================================

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

$KitDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
# Tira a "marca da web" dos arquivos do kit: sem isso o Windows avisa que sao de origem
# desconhecida a cada execucao. Nao muda o conteudo de nada.
Get-ChildItem -LiteralPath $KitDir -File -ErrorAction SilentlyContinue |
    ForEach-Object { Unblock-File -LiteralPath $_.FullName -ErrorAction SilentlyContinue }
$Tweaks  = Join-Path $KitDir 'freedom-tweaks.ps1'
$Pendriv = Join-Path $KitDir 'criar-pendrive.ps1'
$SelPath = Join-Path $KitDir 'selecao.txt'   # a escolha do checklist e gravada aqui
# Catalogo + janela de escolha (o que sera aplicado). Se faltar, o programa segue com os padroes.
$Catalogo = Join-Path $KitDir 'catalogo.ps1'
if (Test-Path $Catalogo) { . $Catalogo }

# ---------------------------------------------------------------------------------
#  Janela de progresso: roda o script escondido e mostra o log aqui dentro, para o
#  usuario nunca ver a janela preta do PowerShell.
# ---------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------
#  Termo de uso: aparece ANTES de limpar o Windows ou criar o pendrive. So prossegue
#  se o usuario marcar "Li e concordo". Mostrado uma vez por sessao.
# ---------------------------------------------------------------------------------
$script:TermosOK = $false
function Confirmar-Termos {
    if ($script:TermosOK) { return $true }

    $texto = @"
TERMO DE USO E RESPONSABILIDADE - Clean Windows $Versao

O QUE ESTE PROGRAMA FAZ
O Clean Windows remove do Windows os aplicativos e servicos que a Microsoft usa para
observar o uso do computador (telemetria, coleta de dados, Copilot, Recall, Widgets,
apps promovidos e OneDrive). Esses componentes tambem consomem recursos e deixam o
computador mais lento. Ao remove-los, o programa deixa o sistema mais leve e ajuda a
proteger a sua privacidade.

O QUE NAO E ALTERADO
Microsoft Defender, Secure Boot, TPM, Windows Update e a Microsoft Store continuam
ligados. O programa nao desativa a sua protecao.

RESPONSABILIDADE
A instalacao e a aplicacao destes ajustes sao feitas por sua conta e risco. A
responsabilidade e inteiramente do usuario. O programa e fornecido "como esta", sem
qualquer garantia. Os autores nao se responsabilizam por perda de dados, falhas do
sistema ou qualquer consequencia decorrente do uso.

RECOMENDACOES
- Faca backup dos seus arquivos importantes antes de continuar.
- Ao LIMPAR ESTE Windows, deixe marcada a criacao de um ponto de restauracao.
- Ao CRIAR PENDRIVE, lembre-se de que o pendrive sera totalmente apagado, e que a
  instalacao formata a particao de destino escolhida.

Projeto independente, NAO afiliado nem endossado pela Microsoft. Windows e marca
registrada da Microsoft Corporation.

Ao marcar "Li e concordo" e clicar em Continuar, voce declara estar ciente de tudo acima.
"@

    $t = New-Object System.Windows.Forms.Form
    $t.Text = 'Termo de uso - Clean Windows'
    $t.ClientSize = New-Object System.Drawing.Size(640, 500)
    $t.StartPosition = 'CenterParent'
    $t.FormBorderStyle = 'FixedDialog'
    $t.MaximizeBox = $false; $t.MinimizeBox = $false
    $t.BackColor = [System.Drawing.Color]::White

    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Multiline = $true; $tb.ReadOnly = $true; $tb.ScrollBars = 'Vertical'; $tb.WordWrap = $true
    $tb.Text = ($texto -replace "`r`n", "`r`n") -replace "(?<!`r)`n", "`r`n"
    $tb.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)
    $tb.BackColor = [System.Drawing.Color]::White
    $tb.Location = New-Object System.Drawing.Point(18, 16)
    $tb.Size = New-Object System.Drawing.Size(604, 380)
    $t.Controls.Add($tb)

    $ck = New-Object System.Windows.Forms.CheckBox
    $ck.Text = 'Li e concordo com o termo de uso e assumo a responsabilidade.'
    $ck.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $ck.Location = New-Object System.Drawing.Point(18, 406)
    $ck.Size = New-Object System.Drawing.Size(604, 24)
    $t.Controls.Add($ck)

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = 'Continuar'; $ok.Enabled = $false
    $ok.Location = New-Object System.Drawing.Point(432, 452); $ok.Size = New-Object System.Drawing.Size(120, 32)
    $ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $t.Controls.Add($ok)

    $no = New-Object System.Windows.Forms.Button
    $no.Text = 'Cancelar'
    $no.Location = New-Object System.Drawing.Point(560, 452); $no.Size = New-Object System.Drawing.Size(64, 32)
    $no.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $t.Controls.Add($no)

    $ck.Add_CheckedChanged({ $ok.Enabled = $ck.Checked })
    $t.AcceptButton = $ok; $t.CancelButton = $no

    $r = $t.ShowDialog($form)
    if ($r -eq [System.Windows.Forms.DialogResult]::OK -and $ck.Checked) {
        $script:TermosOK = $true
        return $true
    }
    return $false
}

function Show-Progresso {
    param([string]$Titulo, [string]$Exe, [string[]]$Argumentos, [string]$LogPath)

    $w = New-Object System.Windows.Forms.Form
    $w.Text = "Clean Windows - $Titulo"
    $w.ClientSize = New-Object System.Drawing.Size(720, 460)
    $w.StartPosition = 'CenterScreen'
    $w.FormBorderStyle = 'FixedDialog'
    $w.MaximizeBox = $false
    $w.BackColor = [System.Drawing.Color]::White

    $lb = New-Object System.Windows.Forms.Label
    $lb.Text = "$Titulo..."
    $lb.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
    $lb.Location = New-Object System.Drawing.Point(20, 16)
    $lb.Size = New-Object System.Drawing.Size(680, 28)
    $w.Controls.Add($lb)

    $sub = New-Object System.Windows.Forms.Label
    $sub.Text = 'Pode levar alguns minutos. Nao desligue o PC.'
    $sub.ForeColor = [System.Drawing.Color]::FromArgb(96, 96, 96)
    $sub.Location = New-Object System.Drawing.Point(20, 44)
    $sub.Size = New-Object System.Drawing.Size(680, 20)
    $w.Controls.Add($sub)

    $bar = New-Object System.Windows.Forms.ProgressBar
    $bar.Style = 'Marquee'
    $bar.MarqueeAnimationSpeed = 30
    $bar.Location = New-Object System.Drawing.Point(20, 70)
    $bar.Size = New-Object System.Drawing.Size(680, 14)
    $w.Controls.Add($bar)

    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Multiline = $true; $tb.ReadOnly = $true; $tb.ScrollBars = 'Vertical'
    $tb.Font = New-Object System.Drawing.Font('Consolas', 9)
    $tb.Location = New-Object System.Drawing.Point(20, 96)
    $tb.Size = New-Object System.Drawing.Size(680, 310)
    $w.Controls.Add($tb)

    $bt = New-Object System.Windows.Forms.Button
    $bt.Text = 'Fechar'
    $bt.Enabled = $false
    $bt.Location = New-Object System.Drawing.Point(620, 418)
    $bt.Size = New-Object System.Drawing.Size(80, 28)
    $bt.Add_Click({ $w.Close() })
    $w.Controls.Add($bt)

    $linhasAntes = if (Test-Path $LogPath) { @(Get-Content -LiteralPath $LogPath -ErrorAction SilentlyContinue).Count } else { 0 }
    $proc = Start-Process -FilePath $Exe -ArgumentList $Argumentos -PassThru -WindowStyle Hidden
    $script:Rodando = $true
    $w.Add_FormClosing({ if ($script:Rodando) { $_.Cancel = $true } })
    [void]$w.Show()

    $mostrado = 0
    while (-not $proc.HasExited) {
        try {
            $todas = @(Get-Content -LiteralPath $LogPath -ErrorAction SilentlyContinue)
            $novas = $todas | Select-Object -Skip ($linhasAntes + $mostrado)
            if ($novas) {
                $tb.AppendText(($novas -join [Environment]::NewLine) + [Environment]::NewLine)
                $mostrado += @($novas).Count
            }
        } catch {}
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 800
    }
    try {
        $todas = @(Get-Content -LiteralPath $LogPath -ErrorAction SilentlyContinue)
        $novas = $todas | Select-Object -Skip ($linhasAntes + $mostrado)
        if ($novas) { $tb.AppendText(($novas -join [Environment]::NewLine) + [Environment]::NewLine) }
    } catch {}
    $script:Rodando = $false
    $bar.Style = 'Continuous'; $bar.Value = 100
    $lb.Text = 'Concluido'
    $sub.Text = 'Reinicie o PC para aplicar tudo (VBS, HAGS, servicos).'
    $bt.Enabled = $true
    while (-not $w.IsDisposed) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 120 }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Clean Windows $Versao"
$form.ClientSize = New-Object System.Drawing.Size(660, 560)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::White

function Add-Ctl($ctl, $x, $y, $w, $h) {
    $ctl.Location = New-Object System.Drawing.Point($x, $y)
    $ctl.Size     = New-Object System.Drawing.Size($w, $h)
    $form.Controls.Add($ctl); $ctl
}
function New-Text($txt, $x, $y, $w, $h, $size, $style, $color) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $txt
    $l.Font = New-Object System.Drawing.Font('Segoe UI', $size, $style)
    $l.ForeColor = $color
    Add-Ctl $l $x $y $w $h
}

$dark = [System.Drawing.Color]::FromArgb(32, 32, 32)
$gray = [System.Drawing.Color]::FromArgb(96, 96, 96)

[void](New-Text 'Clean Windows' 28 22 300 38 18 ([System.Drawing.FontStyle]::Bold) $dark)
$lblVer = New-Text "versao $Versao" 470 36 160 24 10 ([System.Drawing.FontStyle]::Regular) $gray
$lblVer.TextAlign = 'MiddleRight'
[void](New-Text 'O que voce quer fazer?' 30 60 500 24 10 ([System.Drawing.FontStyle]::Regular) $gray)

# ------------------------------------------------------------------ opcao 1
$btn1 = New-Object System.Windows.Forms.Button
$btn1.Text = "   Limpar ESTE Windows"
$btn1.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$btn1.TextAlign = 'MiddleLeft'
$btn1.FlatStyle = 'Standard'
[void](Add-Ctl $btn1 30 100 600 52)

[void](New-Text ("Aplica os ajustes no Windows que ja esta instalado nesta maquina: remove apps" + [Environment]::NewLine +
                 "pre-instalados, telemetria, Copilot, Widgets e OneDrive, e liga os ajustes de jogos." + [Environment]::NewLine +
                 "Nada e formatado, seus arquivos e programas continuam onde estao.") `
        48 156 580 56 9 ([System.Drawing.FontStyle]::Regular) $gray)

$chkRp = New-Object System.Windows.Forms.CheckBox
$chkRp.Text = 'Criar um ponto de restauracao antes (recomendado)'
$chkRp.Checked = $true
$chkRp.Font = New-Object System.Drawing.Font('Segoe UI', 9)
[void](Add-Ctl $chkRp 48 214 420 22)

# ------------------------------------------------------------------ opcao 2
$btn2 = New-Object System.Windows.Forms.Button
$btn2.Text = "   Criar pendrive de instalacao"
$btn2.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$btn2.TextAlign = 'MiddleLeft'
$btn2.FlatStyle = 'Standard'
[void](Add-Ctl $btn2 30 256 600 52)

[void](New-Text ("Grava um pendrive com a ISO oficial do Windows 11 mais este kit, para instalar" + [Environment]::NewLine +
                 "do zero em qualquer PC. O pendrive e APAGADO. A instalacao ja sai limpa e sem" + [Environment]::NewLine +
                 "perguntas, criando a conta local Freedom.") `
        48 312 580 56 9 ([System.Drawing.FontStyle]::Regular) $gray)

$btnReativar = New-Object System.Windows.Forms.Button
$btnReativar.Text = "   Reativar programas e efeitos do Windows"
$btnReativar.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$btnReativar.TextAlign = 'MiddleLeft'; $btnReativar.FlatStyle = 'Standard'
[void](Add-Ctl $btnReativar 30 376 600 44)
$limpezaAplicada = try { (Get-ItemProperty 'HKLM:\SOFTWARE\CleanWindows' -Name LimpezaAplicada -ErrorAction Stop).LimpezaAplicada } catch { 0 }
$btnReativar.Enabled = ($limpezaAplicada -eq 1)
[void](New-Text $(if ($limpezaAplicada -eq 1) {
                "Desfaz a limpeza (volta ao padrao) e mostra quanto o Windows fica mais pesado." }
              else { "Disponivel depois de usar 'Limpar ESTE Windows'." }) `
        48 422 580 20 8 ([System.Drawing.FontStyle]::Regular) $gray)

$lblFoot = New-Text '' 30 500 600 20 8 ([System.Drawing.FontStyle]::Regular) $gray
if ($AllowFixedDisk) {
    $lblFoot.Text = 'MODO DE TESTE: a tela do pendrive lista tambem discos internos.'
    $lblFoot.ForeColor = [System.Drawing.Color]::Firebrick
} else {
    $lblFoot.Text = "Kit: $KitDir"
}

$btnFeed = New-Object System.Windows.Forms.Button
$btnFeed.Text = 'Feedback'
[void](Add-Ctl $btnFeed 30 522 130 30)

$btnDoar = New-Object System.Windows.Forms.Button
$btnDoar.Text = 'Apoiar o projeto'
[void](Add-Ctl $btnDoar 168 522 150 30)
if (-not $ChavePix -and -not $UrlDonativo) { $btnDoar.Enabled = $false }

$btnSair = New-Object System.Windows.Forms.Button
$btnSair.Text = 'Sair'
[void](Add-Ctl $btnSair 550 522 80 30)
$btnSair.Add_Click({ $form.Close() })

# --- Feedback: abre o programa de e-mail do usuario com a mensagem ja comecada ---
$btnFeed.Add_Click({
    $so = try {
        $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        "$($cv.ProductName) $($cv.DisplayVersion) (build $($cv.CurrentBuildNumber).$($cv.UBR))"
    } catch { 'Windows' }

    $assunto = "Clean Windows $Versao - Feedback"
    $corpo   = "Escreva abaixo seu elogio, reclamacao ou sugestao:" + [Environment]::NewLine +
               [Environment]::NewLine + [Environment]::NewLine +
               "----------------------------------------" + [Environment]::NewLine +
               "Clean Windows $Versao" + [Environment]::NewLine +
               "Sistema: $so" + [Environment]::NewLine +
               "(estas duas linhas ajudam a entender o problema; apague se preferir)"

    Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue
    $enc = { param($t) [System.Uri]::EscapeDataString($t) }
    $url = "mailto:$EmailFeedback" + "?subject=" + (& $enc $assunto) + "&body=" + (& $enc $corpo)
    try { Start-Process $url }
    catch {
        [void][System.Windows.Forms.MessageBox]::Show($form,
            "Nao consegui abrir seu programa de e-mail.`n`nMande sua mensagem para:`n$EmailFeedback",
            'Feedback', 'OK', 'Information')
    }
})

# --- Apoiar: Pix (copia a chave) e/ou pagina de doacao ---
$btnDoar.Add_Click({
    $d = New-Object System.Windows.Forms.Form
    $d.Text = 'Apoiar o Clean Windows'
    $d.ClientSize = New-Object System.Drawing.Size(460, 230)
    $d.StartPosition = 'CenterParent'
    $d.FormBorderStyle = 'FixedDialog'
    $d.MaximizeBox = $false; $d.MinimizeBox = $false
    $d.BackColor = [System.Drawing.Color]::White

    $t1 = New-Object System.Windows.Forms.Label
    $t1.Text = 'Obrigado por considerar apoiar!'
    $t1.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
    $t1.Location = New-Object System.Drawing.Point(20, 18)
    $t1.Size = New-Object System.Drawing.Size(420, 28)
    $d.Controls.Add($t1)

    $t2 = New-Object System.Windows.Forms.Label
    $t2.Text = 'O Clean Windows e gratuito e continua assim. Qualquer valor ajuda a manter o projeto.'
    $t2.ForeColor = [System.Drawing.Color]::FromArgb(96, 96, 96)
    $t2.Location = New-Object System.Drawing.Point(20, 48)
    $t2.Size = New-Object System.Drawing.Size(420, 36)
    $d.Controls.Add($t2)

    $y = 94
    if ($ChavePix) {
        $bp = New-Object System.Windows.Forms.Button
        $bp.Text = 'Copiar chave Pix'
        $bp.Location = New-Object System.Drawing.Point(20, $y)
        $bp.Size = New-Object System.Drawing.Size(180, 34)
        $bp.Add_Click({
            try {
                Set-Clipboard -Value $ChavePix
                [void][System.Windows.Forms.MessageBox]::Show(
                    "Chave Pix copiada:`n`n$ChavePix`n`nCole no app do seu banco.", 'Pix', 'OK', 'Information')
            } catch {
                [void][System.Windows.Forms.MessageBox]::Show("Chave Pix:`n`n$ChavePix", 'Pix', 'OK', 'Information')
            }
        })
        $d.Controls.Add($bp)

        $lp = New-Object System.Windows.Forms.TextBox
        $lp.Text = $ChavePix; $lp.ReadOnly = $true
        $lp.Location = New-Object System.Drawing.Point(212, ($y + 4))
        $lp.Size = New-Object System.Drawing.Size(228, 26)
        $d.Controls.Add($lp)
        $y += 46
    }
    if ($UrlDonativo) {
        $bu = New-Object System.Windows.Forms.Button
        $bu.Text = 'Abrir pagina de doacao'
        $bu.Location = New-Object System.Drawing.Point(20, $y)
        $bu.Size = New-Object System.Drawing.Size(420, 34)
        $bu.Add_Click({ try { Start-Process $UrlDonativo } catch {} })
        $d.Controls.Add($bu)
        $y += 46
    }

    $bf = New-Object System.Windows.Forms.Button
    $bf.Text = 'Fechar'
    $bf.Location = New-Object System.Drawing.Point(360, 186)
    $bf.Size = New-Object System.Drawing.Size(80, 28)
    $bf.DialogResult = [System.Windows.Forms.DialogResult]::OK   # fecha o dialogo sozinho
    $d.Controls.Add($bf)
    $d.AcceptButton = $bf; $d.CancelButton = $bf

    [void]$d.ShowDialog($form)
})

# ------------------------------------------------------------------ acoes
$btn1.Add_Click({
    if (-not (Confirmar-Termos)) { return }
    if (-not (Test-Path $Tweaks)) {
        [void][System.Windows.Forms.MessageBox]::Show($form, "Nao encontrei o freedom-tweaks.ps1 em:`n$KitDir", 'Clean Windows', 'OK', 'Error')
        return
    }
    # Deixa o usuario escolher item por item o que sera aplicado (grava selecao.txt ao lado
    # do freedom-tweaks; ele le esse arquivo). Cancelar aqui aborta a limpeza.
    if (Get-Command Show-Checklist -ErrorAction SilentlyContinue) {
        if (-not (Show-Checklist -Parent $form -SelecaoPath $SelPath -Contexto 'Limpar este Windows')) { return }
    }
    $txt = "Os ajustes serao aplicados NESTE Windows agora.`n`n" +
           "- Apps pre-instalados, telemetria, Copilot, Widgets e OneDrive serao removidos.`n" +
           "- Se voce usa o OneDrive, tire seus arquivos da pasta dele ANTES.`n" +
           "- No fim sera preciso reiniciar.`n`n" +
           $(if ($chkRp.Checked) { "Um ponto de restauracao sera criado antes." } else { "SEM ponto de restauracao." }) +
           "`n`nContinuar?"
    $r = [System.Windows.Forms.MessageBox]::Show($form, $txt, 'Limpar este Windows', 'YesNo', 'Warning', 'Button2')
    if ($r -ne 'Yes') { return }
    $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', "`"$Tweaks`"")
    if ($chkRp.Checked) { $a += '-RestorePoint' }
    $form.Hide()
    Show-Progresso -Titulo 'Limpando este Windows' -Exe 'powershell.exe' -Argumentos $a `
                   -LogPath "$env:SystemRoot\Setup\Scripts\freedom-tweaks.log"
    $form.Close()
})

$btnReativar.Add_Click({
    $restore = Join-Path $KitDir 'freedom-restore.ps1'
    if (-not (Test-Path $restore)) {
        [void][System.Windows.Forms.MessageBox]::Show($form, "Nao encontrei o freedom-restore.ps1 em:`n$KitDir", 'Clean Windows', 'OK', 'Error'); return
    }
    $txt = "Isto DESFAZ o Clean Windows e devolve o Windows ao padrao:`n`n" +
           "- Religa transparencia, sombras e animacoes.`n" +
           "- Reativa servicos, tarefas, telemetria e o popup do administrador.`n" +
           "- Tenta reinstalar o OneDrive e os apps (pela Loja).`n`n" +
           "O Windows vai ficar MAIS PESADO. Ao final, mostramos quanto.`n`nContinuar?"
    if ([System.Windows.Forms.MessageBox]::Show($form, $txt, 'Reativar Windows padrao', 'YesNo', 'Warning', 'Button2') -ne 'Yes') { return }
    $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', "`"$restore`"", '-Quiet')
    $form.Hide()
    Show-Progresso -Titulo 'Reativando o Windows padrao' -Exe 'powershell.exe' -Argumentos $a `
                   -LogPath "$env:SystemRoot\Setup\Scripts\freedom-restore.log"
    Show-Restauracao
    $form.Close()
})

$btn2.Add_Click({
    if (-not (Confirmar-Termos)) { return }
    if (-not (Test-Path $Pendriv)) {
        [void][System.Windows.Forms.MessageBox]::Show($form, "Nao encontrei o criar-pendrive.ps1 em:`n$KitDir", 'Clean Windows', 'OK', 'Error')
        return
    }
    $a = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-File', "`"$Pendriv`"")
    if ($AllowFixedDisk) { $a += '-AllowFixedDisk' }
    Start-Process powershell.exe -ArgumentList $a
    $form.Close()
})

# ---------------------------------------------------------------------------------
#  Verifica no GitHub se ha uma versao mais nova. Se houver e o usuario aceitar, baixa
#  o .zip da Release, extrai na pasta Downloads e abre a pasta para ele rodar. NUNCA
#  executa nada sozinho. Falha em silencio se estiver offline.
# ---------------------------------------------------------------------------------
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

# Mostra a comparacao de leveza (antes x depois) uma unica vez, apos a limpeza + reinicio.
function Show-Comparacao {
    $CW = 'HKLM:\SOFTWARE\CleanWindows'
    $flag = try { (Get-ItemProperty $CW -Name MostrarComparacao -ErrorAction Stop).MostrarComparacao } catch { 0 }
    if ($flag -ne 1) { return }
    $a = try { Get-ItemProperty $CW -ErrorAction Stop } catch { $null }
    if (-not $a -or $null -eq $a.Antes_Processos) { return }
    # "depois" = medida no FIM da limpeza (Limpo_*), na mesma janela de tempo do "antes",
    # para nao pegar flutuacao. Se faltar, mede agora.
    if ($null -ne $a.Limpo_Processos) {
        $d = [pscustomobject]@{ Processos=[int]$a.Limpo_Processos; RamUsoMB=[int]$a.Limpo_RamMB
            Servicos=[int]$a.Limpo_Servicos; Appx=[int]$a.Limpo_Appx; Tarefas=[int]$a.Limpo_Tarefas; Inicio=[int]$a.Limpo_Inicio }
    } else { $d = Get-Metricas }

    $itens = @(
        @{ Rot = 'Processos em segundo plano'; Ini = [int]$a.Antes_Processos; Fim = $d.Processos }
        @{ Rot = 'RAM em uso (ociosa)';        Ini = [int]$a.Antes_RamMB;     Fim = $d.RamUsoMB; Un = ' MB' }
        @{ Rot = 'Apps instalados';            Ini = [int]$a.Antes_Appx;      Fim = $d.Appx }
        @{ Rot = 'Servicos em execucao';       Ini = [int]$a.Antes_Servicos;  Fim = $d.Servicos }
        @{ Rot = 'Itens de inicializacao';     Ini = [int]$a.Antes_Inicio;    Fim = $d.Inicio }
        @{ Rot = 'Tarefas agendadas ativas';   Ini = [int]$a.Antes_Tarefas;   Fim = $d.Tarefas }
    )
    $reducoes = @()
    foreach ($i in $itens) {
        if ($i.Ini -gt 0) {
            $pct = [math]::Round((($i.Ini - $i.Fim) / $i.Ini) * 100)
            # limpeza nao aumenta carga: se "aumentou", e ruido de medicao -> tratamos como igual
            if ($pct -lt 0) { $pct = 0; $i.Fim = $i.Ini }
            $i.Pct = $pct
            if ($pct -gt 0) { $reducoes += $pct }
        } else { $i.Pct = 0 }
    }
    $geral = if ($reducoes.Count) { [math]::Round(($reducoes | Measure-Object -Average).Average) } else { 0 }

    $w = New-Object System.Windows.Forms.Form
    $w.Text = 'Resultado da limpeza - Clean Windows'
    $w.ClientSize = New-Object System.Drawing.Size(560, 430)
    $w.StartPosition = 'CenterScreen'
    $w.FormBorderStyle = 'FixedDialog'; $w.MaximizeBox = $false; $w.MinimizeBox = $false
    $w.BackColor = [System.Drawing.Color]::White

    $h = New-Object System.Windows.Forms.Label
    $h.Text = "Seu Windows ficou ~$geral% mais enxuto"
    $h.Font = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
    $h.ForeColor = [System.Drawing.Color]::FromArgb(0x1B, 0x8A, 0x4D)
    $h.Location = New-Object System.Drawing.Point(24, 20); $h.Size = New-Object System.Drawing.Size(520, 34)
    $w.Controls.Add($h)

    $s2 = New-Object System.Windows.Forms.Label
    $s2.Text = 'Comparacao entre antes e depois da limpeza:'
    $s2.ForeColor = [System.Drawing.Color]::FromArgb(96, 96, 96)
    $s2.Location = New-Object System.Drawing.Point(24, 58); $s2.Size = New-Object System.Drawing.Size(520, 20)
    $w.Controls.Add($s2)

    $lv = New-Object System.Windows.Forms.ListView
    $lv.View = 'Details'; $lv.FullRowSelect = $true; $lv.GridLines = $true; $lv.HeaderStyle = 'Nonclickable'
    $lv.Location = New-Object System.Drawing.Point(24, 86); $lv.Size = New-Object System.Drawing.Size(512, 260)
    [void]$lv.Columns.Add('Indicador', 250)
    [void]$lv.Columns.Add('Antes', 80, 'Center')
    [void]$lv.Columns.Add('Depois', 80, 'Center')
    [void]$lv.Columns.Add('Reducao', 90, 'Center')
    foreach ($i in $itens) {
        $un = if ($i.Un) { $i.Un } else { '' }
        $row = New-Object System.Windows.Forms.ListViewItem($i.Rot)
        [void]$row.SubItems.Add("$($i.Ini)$un")
        [void]$row.SubItems.Add("$($i.Fim)$un")
        [void]$row.SubItems.Add($(if ($i.Pct -gt 0) { "-$($i.Pct)%" } elseif ($i.Pct -lt 0) { "+$([math]::Abs($i.Pct))%" } else { '~' }))
        [void]$lv.Items.Add($row)
    }
    $w.Controls.Add($lv)

    $n = New-Object System.Windows.Forms.Label
    $n.Text = 'A leveza vem de remover o que roda em segundo plano; o desempenho real tambem depende do seu hardware.'
    $n.ForeColor = [System.Drawing.Color]::FromArgb(120, 120, 120)
    $n.Font = New-Object System.Drawing.Font('Segoe UI', 8)
    $n.Location = New-Object System.Drawing.Point(24, 352); $n.Size = New-Object System.Drawing.Size(512, 34)
    $w.Controls.Add($n)

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = 'Fechar'; $ok.Location = New-Object System.Drawing.Point(456, 392); $ok.Size = New-Object System.Drawing.Size(80, 28)
    $ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $w.Controls.Add($ok); $w.AcceptButton = $ok

    try { Set-ItemProperty -Path $CW -Name MostrarComparacao -Value 0 -ErrorAction SilentlyContinue } catch {}
    [void]$w.ShowDialog($form)
}

# Mostra quanto o Windows ficou MAIS PESADO ao reativar (desfazer a limpeza).
function Show-Restauracao {
    $CW = 'HKLM:\SOFTWARE\CleanWindows'
    $flag = try { (Get-ItemProperty $CW -Name MostrarRestauracao -ErrorAction Stop).MostrarRestauracao } catch { 0 }
    if ($flag -ne 1) { return }
    $r = try { Get-ItemProperty $CW -ErrorAction Stop } catch { $null }
    if (-not $r -or $null -eq $r.R_Limpo_Processos) { return }

    $itens = @(
        @{ Rot = 'Processos em segundo plano'; L = [int]$r.R_Limpo_Processos; P = [int]$r.R_Pesado_Processos }
        @{ Rot = 'RAM em uso (ociosa)';        L = [int]$r.R_Limpo_RamMB;     P = [int]$r.R_Pesado_RamMB; Un = ' MB' }
        @{ Rot = 'Servicos em execucao';       L = [int]$r.R_Limpo_Servicos;  P = [int]$r.R_Pesado_Servicos }
        @{ Rot = 'Tarefas agendadas ativas';   L = [int]$r.R_Limpo_Tarefas;   P = [int]$r.R_Pesado_Tarefas }
        @{ Rot = 'Apps instalados';            L = [int]$r.R_Limpo_Appx;      P = [int]$r.R_Pesado_Appx }
    )
    $aumentos = @()
    foreach ($i in $itens) {
        if ($i.L -gt 0) { $i.Pct = [math]::Round((($i.P - $i.L) / $i.L) * 100); if ($i.Pct -gt 0) { $aumentos += $i.Pct } }
        else { $i.Pct = 0 }
    }
    $geral = if ($aumentos.Count) { [math]::Round(($aumentos | Measure-Object -Average).Average) } else { 0 }

    $w = New-Object System.Windows.Forms.Form
    $w.Text = 'Windows reativado (padrao) - Clean Windows'
    $w.ClientSize = New-Object System.Drawing.Size(560, 400)
    $w.StartPosition = 'CenterScreen'; $w.FormBorderStyle = 'FixedDialog'; $w.MaximizeBox = $false; $w.MinimizeBox = $false
    $w.BackColor = [System.Drawing.Color]::White

    $h = New-Object System.Windows.Forms.Label
    $h.Text = "Ao reativar, o Windows ficou ~$geral% mais pesado"
    $h.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
    $h.ForeColor = [System.Drawing.Color]::FromArgb(0xC6, 0x28, 0x28)
    $h.Location = New-Object System.Drawing.Point(24, 20); $h.Size = New-Object System.Drawing.Size(520, 32)
    $w.Controls.Add($h)

    $s2 = New-Object System.Windows.Forms.Label
    $s2.Text = 'De volta ao padrao do Windows (limpo -> reativado):'
    $s2.ForeColor = [System.Drawing.Color]::FromArgb(96, 96, 96)
    $s2.Location = New-Object System.Drawing.Point(24, 56); $s2.Size = New-Object System.Drawing.Size(520, 20)
    $w.Controls.Add($s2)

    $lv = New-Object System.Windows.Forms.ListView
    $lv.View = 'Details'; $lv.FullRowSelect = $true; $lv.GridLines = $true; $lv.HeaderStyle = 'Nonclickable'
    $lv.Location = New-Object System.Drawing.Point(24, 84); $lv.Size = New-Object System.Drawing.Size(512, 232)
    [void]$lv.Columns.Add('Indicador', 250)
    [void]$lv.Columns.Add('Limpo', 80, 'Center')
    [void]$lv.Columns.Add('Reativado', 90, 'Center')
    [void]$lv.Columns.Add('Aumento', 80, 'Center')
    foreach ($i in $itens) {
        $un = if ($i.Un) { $i.Un } else { '' }
        $row = New-Object System.Windows.Forms.ListViewItem($i.Rot)
        [void]$row.SubItems.Add("$($i.L)$un"); [void]$row.SubItems.Add("$($i.P)$un")
        [void]$row.SubItems.Add($(if ($i.Pct -gt 0) { "+$($i.Pct)%" } elseif ($i.Pct -lt 0) { "-$([math]::Abs($i.Pct))%" } else { '~' }))
        [void]$lv.Items.Add($row)
    }
    $w.Controls.Add($lv)

    $n = New-Object System.Windows.Forms.Label
    $n.Text = 'Apos reiniciar, o Windows volta a carregar todos esses itens. Para voltar a limpar, use "Limpar ESTE Windows".'
    $n.ForeColor = [System.Drawing.Color]::FromArgb(120, 120, 120); $n.Font = New-Object System.Drawing.Font('Segoe UI', 8)
    $n.Location = New-Object System.Drawing.Point(24, 322); $n.Size = New-Object System.Drawing.Size(512, 34)
    $w.Controls.Add($n)

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = 'Fechar'; $ok.Location = New-Object System.Drawing.Point(456, 362); $ok.Size = New-Object System.Drawing.Size(80, 28)
    $ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $w.Controls.Add($ok); $w.AcceptButton = $ok

    try { Set-ItemProperty -Path $CW -Name MostrarRestauracao -Value 0 -ErrorAction SilentlyContinue } catch {}
    [void]$w.ShowDialog($form)
}

function Test-Atualizacao {
    if (-not $RepoUpdate) { return }
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $hdr = @{ 'User-Agent' = 'CleanWindows'; 'Accept' = 'application/vnd.github+json' }
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$RepoUpdate/releases/latest" `
                    -Headers $hdr -TimeoutSec 6 -ErrorAction Stop
        $tag = "$($rel.tag_name)".TrimStart('v', 'V')
        if (-not $tag) { return }
        $nova = $false
        try { $nova = [version]$tag -gt [version]$Versao } catch { $nova = ($tag -ne $Versao) }
        if (-not $nova) { return }

        $q = "Ha uma nova versao do Clean Windows: $tag`nVoce tem a $Versao.`n`nBaixar agora?"
        if ([System.Windows.Forms.MessageBox]::Show($form, $q, 'Atualizacao disponivel', 'YesNo', 'Information') -ne 'Yes') { return }

        $asset = $rel.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1
        if (-not $asset) { Start-Process "https://github.com/$RepoUpdate/releases/latest"; return }

        $dl  = [Environment]::GetFolderPath('UserProfile') + '\Downloads'
        $zip = Join-Path $dl $asset.name
        $form.Cursor = 'WaitCursor'
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -Headers $hdr -TimeoutSec 180 -ErrorAction Stop
        $form.Cursor = 'Default'

        $destino = Join-Path $dl ("Clean Windows " + $tag)
        try {
            if (Test-Path $destino) { Remove-Item $destino -Recurse -Force -ErrorAction SilentlyContinue }
            Expand-Archive -LiteralPath $zip -DestinationPath $destino -Force -ErrorAction Stop
            $sub = Join-Path $destino 'clean-windows'
            $abrir = if (Test-Path $sub) { $sub } else { $destino }
            Start-Process explorer.exe $abrir
            [void][System.Windows.Forms.MessageBox]::Show($form,
                "Baixado e extraido em:`n$abrir`n`nNessa pasta, rode 'preparar.cmd' (uma vez) e depois 'CleanWindows.exe'.",
                'Atualizacao baixada', 'OK', 'Information')
        } catch {
            Start-Process explorer.exe "/select,`"$zip`""
            [void][System.Windows.Forms.MessageBox]::Show($form,
                "Baixado em:`n$zip`n`nExtraia o arquivo e rode 'preparar.cmd' e depois 'CleanWindows.exe'.",
                'Atualizacao baixada', 'OK', 'Information')
        }
    } catch { $form.Cursor = 'Default' }   # offline / limite de API: silencioso
}
$form.Add_Shown({ Test-Atualizacao; Show-Comparacao; Show-Restauracao })

[void]$form.ShowDialog()
