<#
=====================================================================================
  catalogo.ps1  -  catalogo do que o Clean Windows desativa/remove + janela de escolha
=====================================================================================
  Fonte unica da lista de tudo que o programa mexe, para que o usuario possa MARCAR ou
  DESMARCAR item por item, tanto ao "Limpar ESTE Windows" quanto ao "Criar pendrive".

  Este arquivo NAO faz nada sozinho: so define funcoes. Quem usa:
    - clean-windows.ps1  -> mostra a janela antes de limpar
    - criar-pendrive.ps1 -> mostra a janela antes de gravar (a escolha vai junto no kit)
    - freedom-tweaks.ps1 -> le a escolha (selecao.txt) e aplica so o que ficou marcado

  A "selecao" e um arquivo texto (selecao.txt) com os IDs marcados, um por linha.
  Sem esse arquivo, o freedom-tweaks aplica os padroes (tudo que tem Padrao=$true).

  IDs:  app:<pacote>   svc:<servico>   task:<caminho>   grp:<chave de recurso>
=====================================================================================
#>

# -----------------------------------------------------------------------------
#  Catalogo: categorias -> itens. Cada item: Id, Rot(ulo), Tipo, Padrao, Detalhe
# -----------------------------------------------------------------------------
function Get-CleanWindowsCatalog {
    function It($id, $rot, $tipo, $padrao, $det) {
        [pscustomobject]@{ Id = $id; Rot = $rot; Tipo = $tipo; Padrao = [bool]$padrao; Detalhe = $det }
    }

    @(
        # ---------------------------------------------------------------- APLICATIVOS
        [pscustomobject]@{
            Nome = 'Aplicativos pre-instalados (serao desinstalados)'
            Desc = 'Apps da Microsoft que vem de fabrica. Desmarque os que voce usa.'
            Itens = @(
                It 'app:Clipchamp.Clipchamp'                        'Clipchamp (editor de video)'          app $true  'Editor de video da Microsoft.'
                It 'app:Microsoft.549981C3F5F10'                    'Cortana'                              app $true  'Assistente de voz Cortana.'
                It 'app:Microsoft.BingNews'                         'Noticias (MSN)'                       app $true  'App de noticias com anuncios.'
                It 'app:Microsoft.BingSearch'                       'Pesquisa Bing na barra'               app $true  'Integra Bing/web na busca do Windows.'
                It 'app:Microsoft.BingWeather'                      'Clima (MSN)'                          app $true  'App de previsao do tempo.'
                It 'app:Microsoft.Copilot'                          'Copilot'                              app $true  'Assistente de IA da Microsoft.'
                It 'app:Microsoft.Windows.Ai.Copilot.Provider'      'Provedor do Copilot (IA)'             app $true  'Componente de IA do Copilot.'
                It 'app:Microsoft.Edge.GameAssist'                  'Edge Game Assist'                     app $true  'Barra do Edge para jogos.'
                It 'app:Microsoft.GetHelp'                          'Obter Ajuda'                          app $true  'App de suporte da Microsoft.'
                It 'app:Microsoft.Getstarted'                       'Dicas / Introducao ao Windows'        app $true  'Dicas e sugestoes do Windows.'
                It 'app:Microsoft.MicrosoftOfficeHub'               'Office (hub/atalho)'                  app $true  'Atalho promocional do Office 365.'
                It 'app:Microsoft.MicrosoftSolitaireCollection'     'Colecao Solitaire'                    app $true  'Jogos de cartas com anuncios.'
                It 'app:Microsoft.MicrosoftStickyNotes'             'Notas Autoadesivas'                   app $true  'Post-its na area de trabalho.'
                It 'app:Microsoft.OutlookForWindows'                'Novo Outlook'                         app $true  'Novo cliente de email da Microsoft.'
                It 'app:Microsoft.People'                           'Pessoas (Contatos)'                   app $true  'Agenda de contatos.'
                It 'app:Microsoft.PowerAutomateDesktop'             'Power Automate'                        app $true  'Automacao de tarefas.'
                It 'app:Microsoft.Todos'                            'Microsoft To Do'                      app $true  'Lista de tarefas.'
                It 'app:Microsoft.Windows.DevHome'                  'Dev Home'                             app $true  'Painel para desenvolvedores.'
                It 'app:Microsoft.WindowsAlarms'                    'Alarmes e Relogio'                    app $true  'Despertador, cronometro e timer.'
                It 'app:Microsoft.WindowsFeedbackHub'               'Hub de Comentarios'                   app $true  'Envia feedback (e dados) a Microsoft.'
                It 'app:Microsoft.WindowsMaps'                      'Mapas'                                app $true  'Mapas offline da Microsoft.'
                It 'app:Microsoft.WindowsSoundRecorder'             'Gravador de Voz'                      app $true  'Gravador de audio.'
                It 'app:Microsoft.YourPhone'                        'Vincular ao Celular'                  app $true  'Conexao com o telefone.'
                It 'app:Microsoft.ZuneMusic'                        'Media Player / Groove'               app $true  'Reprodutor de musica.'
                It 'app:Microsoft.ZuneVideo'                        'Filmes e TV'                          app $true  'Reprodutor/loja de video.'
                It 'app:MicrosoftCorporationII.QuickAssist'         'Assistencia Rapida'                   app $true  'Suporte remoto.'
                It 'app:MicrosoftCorporationII.MicrosoftFamily'     'Seguranca Familiar'                   app $true  'Controle dos pais.'
                It 'app:microsoft.windowscommunicationsapps'        'Email e Calendario'                   app $true  'App classico de Email/Calendario.'
                It 'app:MicrosoftWindows.Client.WebExperience'      'Widgets (painel)'                     app $true  'Painel de widgets/noticias.'
                It 'app:MicrosoftWindows.CrossDevice'               'Entre Dispositivos'                   app $true  'Continuidade com celular.'
                It 'app:MSTeams'                                    'Microsoft Teams (pessoal)'            app $true  'Chat/Teams pessoal.'
                It 'app:Microsoft.MixedReality.Portal'              'Portal de Realidade Mista'            app $true  'Realidade mista/VR.'
                It 'app:Microsoft.Microsoft3DViewer'                'Visualizador 3D'                      app $true  'Visualizador de modelos 3D.'
                It 'app:Microsoft.Print3D'                          'Impressao 3D'                         app $true  'Impressao em 3D.'
                It 'app:Microsoft.Wallet'                           'Carteira'                             app $true  'Carteira digital.'
                It 'app:Microsoft.Messaging'                        'Mensagens'                            app $true  'App de mensagens.'
                It 'app:Microsoft.OneConnect'                       'Assistente de Mobilidade'             app $true  'OneConnect (planos moveis).'
                It 'app:Microsoft.SkypeApp'                         'Skype'                                app $true  'Skype.'
                It 'app:Microsoft.Office.OneNote'                   'OneNote (versao da Loja)'             app $true  'OneNote UWP.'
                It 'app:Microsoft.LinkedIn'                         'LinkedIn'                             app $true  'App do LinkedIn.'
                # Xbox: marcados por padrao (tudo ligado). DESMARQUE se voce joga com Game Pass/Xbox.
                It 'app:Microsoft.GamingApp'                        'App Xbox (Game Pass)'                 app $true  'DESMARQUE se voce usa o Game Pass ou joga pela Store no PC.'
                It 'app:Microsoft.XboxGamingOverlay'                'Xbox Game Bar (Win+G)'                app $true  'Overlay/gravacao Win+G. Desmarque se usa.'
                It 'app:Microsoft.XboxGameOverlay'                  'Xbox (overlay)'                       app $true  'Componente do Game Bar.'
                It 'app:Microsoft.Xbox.TCUI'                        'Xbox (TCUI)'                          app $true  'Interface comum do Xbox.'
                It 'app:Microsoft.XboxIdentityProvider'             'Xbox (login/identidade)'              app $true  'DESMARQUE se voce joga por Xbox/Game Pass (login dos jogos).'
                It 'app:Microsoft.XboxSpeechToTextOverlay'          'Xbox (legendas por voz)'              app $true  'Legendas de voz no Game Bar.'
            )
        }

        # ---------------------------------------------------------------- RECURSOS
        [pscustomobject]@{
            Nome = 'Recursos e ajustes do sistema'
            Desc = 'Politicas e ajustes de privacidade, desempenho e interface.'
            Itens = @(
                It 'grp:DisableTelemetry'        'Telemetria e diagnostico (coleta de dados)'                 grupo $true  'Desliga o envio de dados de uso a Microsoft.'
                It 'grp:Privacy'                 'Privacidade (anuncios, sugestoes, localizacao, Cortana)'    grupo $true  'ID de publicidade, Spotlight, localizacao, busca no Bing.'
                It 'grp:RelogioManualSemLocalizacao' 'Fuso horario manual quando a localizacao e desligada'   grupo $true  'Sem localizacao, o "fuso automatico" pode errar a hora. Deixa o fuso manual (o horario continua sincronizando pela internet).'
                It 'grp:DisableCopilotRecall'    'Copilot, Recall e Click to Do'                              grupo $true  'Desliga o assistente de IA e a captura de tela do Recall.'
                It 'grp:DisableWidgetsChat'      'Widgets, Chat e noticias'                                   grupo $true  'Remove o painel de widgets e o botao de chat.'
                It 'grp:RemoveOneDrive'          'Remover OneDrive (permite reinstalar depois)'               grupo $true  'Desinstala o OneDrive. Voce pode baixar e reinstalar quando quiser; o Windows nao o reinstala sozinho.'
                It 'grp:GamingTweaks'            'Ajustes de jogos (Game Mode, DVR off, HAGS, MMCSS)'         grupo $true  'Otimizacoes para jogos; desliga a gravacao em segundo plano.'
                It 'grp:PowerPlanUltimate'       'Plano de energia Desempenho Maximo'                         grupo $true  'Em NOTEBOOK, desmarque (gasta mais bateria).'
                It 'grp:DisableVBS'              'Desligar Isolamento de Nucleo / VBS'                        grupo $true  'Ganha FPS em alguns jogos; reduz a protecao contra malware de kernel.'
                It 'grp:DisableHibernation'      'Desligar hibernacao e Inicializacao Rapida'                 grupo $true  'Evita bugs de driver/rede apos desligar; libera espaco.'
                It 'grp:DesempenhoVisual'        'Efeitos visuais mais leves (sem transparencia/sombra/animacao)' grupo $true 'Mantem a nitidez das fontes (ClearType).'
                It 'grp:SilenciarUAC'            'Admin eleva sem popup do UAC (protecao mantida)'            grupo $true  'Tira o "Deseja permitir..." para contas de administrador. O UAC continua ligado.'
                It 'grp:ExplorerQoL'             'Explorer: extensoes visiveis, menu classico, sem Visao de Tarefas' grupo $true 'Ajustes de conforto no Explorador de Arquivos.'
                It 'grp:EdgeTweaks'              'Edge mais leve (sem segundo plano / barra lateral)'         grupo $true  'Impede o Edge de rodar sozinho em segundo plano.'
                It 'grp:PreventDeviceEncryption' 'Impedir criptografia automatica (BitLocker)'                grupo $true  'Evita que o Win11 24H2/25H2 cifre o disco sozinho. Nao decifra discos ja cifrados.'
                It 'grp:AutoReapplyAfterUpdate'  'Reaplicar os ajustes apos atualizacoes do Windows'          grupo $true  'Uma atualizacao grande pode religar telemetria/Copilot; isto reaplica sozinho.'
                # avancados
                It 'grp:DisableSysMain'          'Desligar SysMain/Superfetch'                                grupo $true  'Em geral tudo bem em SSD; se notar travadinhas (stutter), desmarque.'
                It 'grp:BlockDriverUpdates'      'Bloquear troca de drivers pelo Windows Update'              grupo $true  'Evita o Windows trocar o driver da GPU. Desmarque se ainda precisa baixar drivers pela primeira vez.'
                It 'grp:DualBootUtcClock'        'Relogio em UTC (SO para dual boot com Linux)'               grupo $false 'Deixe DESMARCADO se este PC so tem Windows, senao a hora fica errada. Marque so se tiver Linux no mesmo PC.'
            )
        }

        # ---------------------------------------------------------------- SERVICOS
        [pscustomobject]@{
            Nome = 'Servicos do Windows (serao desativados)'
            Desc = 'Servicos que ficam em segundo plano. Desmarque os que voce precisa.'
            Itens = @(
                It 'svc:DiagTrack'                                  'Telemetria (Experiencias Conectadas)' servico $true 'Servico central de telemetria.'
                It 'svc:dmwappushservice'                           'Roteamento WAP (telemetria)'          servico $true 'Roteia mensagens de telemetria.'
                It 'svc:diagnosticshub.standardcollector.service'   'Coletor de diagnostico'               servico $true 'Coleta dados de diagnostico.'
                It 'svc:WerSvc'                                     'Relatorio de Erros do Windows'        servico $true 'Envia relatorios de falha.'
                It 'svc:wercplsupport'                              'Suporte ao painel de erros'           servico $true 'Painel dos relatorios de erro.'
                It 'svc:RetailDemo'                                 'Modo Demonstracao de loja'            servico $true 'So util em PC de vitrine.'
                It 'svc:MapsBroker'                                 'Mapas offline'                        servico $true 'Precisa so se voce usa o app Mapas.'
                It 'svc:RemoteRegistry'                             'Registro Remoto'                      servico $true 'Acesso remoto ao registro (risco).'
                It 'svc:Fax'                                        'Fax'                                  servico $true 'Envio/recebimento de fax.'
                It 'svc:WMPNetworkSvc'                              'Compartilhamento do Media Player'     servico $true 'Compartilha midia na rede.'
                It 'svc:lfsvc'                                      'Geolocalizacao'                       servico $true 'Localizacao do dispositivo.'
                It 'svc:wisvc'                                      'Windows Insider'                      servico $true 'Programa de testes (Insider).'
                It 'svc:MessagingService'                           'Mensagens (SMS)'                      servico $true 'Servico de SMS.'
                It 'svc:SEMgrSvc'                                   'Pagamentos e NFC'                      servico $true 'Pagamentos por aproximacao.'
                It 'svc:WpcMonSvc'                                  'Controle dos Pais'                    servico $true 'Monitor de controle parental.'
                It 'svc:TrkWks'                                     'Rastreamento de Links'                servico $true 'Rastreia atalhos movidos.'
                It 'svc:PhoneSvc'                                   'Telefonia (Vincular ao Celular)'      servico $true 'Suporte a chamadas/telefonia.'
            )
        }

        # ---------------------------------------------------------------- TAREFAS
        [pscustomobject]@{
            Nome = 'Tarefas agendadas (serao desativadas)'
            Desc = 'Tarefas de coleta/diagnostico que rodam sozinhas.'
            Itens = @(
                It 'task:\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser'     'Avaliador de compatibilidade' tarefa $true 'Coleta dados de compatibilidade (telemetria).'
                It 'task:\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp' 'Avaliador de compatibilidade (Exp)' tarefa $true 'Variante do avaliador (25H2).'
                It 'task:\Microsoft\Windows\Application Experience\ProgramDataUpdater'                    'Inventario de programas'      tarefa $true 'Inventaria programas instalados.'
                It 'task:\Microsoft\Windows\Application Experience\PcaPatchDbTask'                        'PCA - banco de correcoes'     tarefa $true 'Assistente de compatibilidade.'
                It 'task:\Microsoft\Windows\Application Experience\MareBackup'                            'MareBackup (Appraiser)'       tarefa $true 'Backup do avaliador.'
                It 'task:\Microsoft\Windows\Application Experience\StartupAppTask'                        'Analise de apps de inicio'    tarefa $true 'Analisa apps de inicializacao.'
                It 'task:\Microsoft\Windows\Autochk\Proxy'                                               'Autochk Proxy (CEIP)'         tarefa $true 'Coleta do programa CEIP.'
                It 'task:\Microsoft\Windows\Customer Experience Improvement Program\Consolidator'        'CEIP - Consolidator'          tarefa $true 'Envia dados do CEIP.'
                It 'task:\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip'             'CEIP - USB'                   tarefa $true 'Dados de uso de USB.'
                It 'task:\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector' 'Diagnostico de disco'        tarefa $true 'Coleta de diagnostico de disco.'
                It 'task:\Microsoft\Windows\Feedback\Siuf\DmClient'                                      'Feedback (DmClient)'          tarefa $true 'Pedidos de feedback.'
                It 'task:\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload'                    'Feedback (cenario)'           tarefa $true 'Pedidos de feedback (cenario).'
                It 'task:\Microsoft\Windows\Windows Error Reporting\QueueReporting'                      'Relatorio de erros (fila)'    tarefa $true 'Fila de relatorios de erro.'
                It 'task:\Microsoft\Windows\Maps\MapsUpdateTask'                                         'Atualizacao de Mapas'         tarefa $true 'Atualiza mapas offline.'
                It 'task:\Microsoft\Windows\Maps\MapsToastTask'                                          'Notificacoes de Mapas'        tarefa $true 'Avisos do app Mapas.'
                It 'task:\Microsoft\Windows\Device Information\Device'                                    'Informacoes do dispositivo'   tarefa $true 'Coleta info do dispositivo.'
                It 'task:\Microsoft\Windows\Device Information\Device User'                               'Info do dispositivo (usuario)' tarefa $true 'Coleta info por usuario.'
                It 'task:\Microsoft\Windows\NetTrace\GatherNetworkInfo'                                  'Coleta de info de rede'       tarefa $true 'Coleta dados da rede.'
                It 'task:\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem'                   'Eficiencia de energia'        tarefa $true 'Analise de energia.'
                It 'task:\Microsoft\Windows\PI\Sqm-Tasks'                                                'SQM (telemetria)'             tarefa $true 'Metricas de qualidade (SQM).'
                It 'task:\Microsoft\Windows\Flighting\FeatureConfig\ReconcileFeatures'                   'Recursos experimentais'       tarefa $true 'Ativa testes A/B de recursos.'
                It 'task:\Microsoft\Windows\Flighting\OneSettings\RefreshCache'                          'OneSettings (cache)'          tarefa $true 'Baixa configuracoes da nuvem.'
            )
        }
    )
}

# -----------------------------------------------------------------------------
#  Selecao (selecao.txt): leitura e escrita
# -----------------------------------------------------------------------------
# Le a selecao. Retorna $null se o arquivo nao existir (= usar os padroes), ou um
# HashSet com os IDs marcados.
function Read-CwSelecao([string]$Path) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) { return $null }
    $set = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($line in (Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue)) {
        $l = $line.Trim()
        if ($l -and -not $l.StartsWith('#')) { [void]$set.Add($l) }
    }
    return $set
}

function Write-CwSelecao([string]$Path, [string[]]$Ids) {
    $header = @(
        '# Clean Windows - selecao de itens (gerado pelo programa).'
        '# Cada linha e um ID marcado. Apagar este arquivo faz voltar aos padroes.'
    )
    Set-Content -LiteralPath $Path -Value ($header + $Ids) -Encoding UTF8 -ErrorAction SilentlyContinue
}

# -----------------------------------------------------------------------------
#  Janela de escolha (checklist). Retorna $true se o usuario confirmou (e grava
#  a selecao em $SelecaoPath); $false se cancelou.
# -----------------------------------------------------------------------------
function Show-Checklist {
    param(
        [System.Windows.Forms.IWin32Window]$Parent,
        [string]$SelecaoPath,
        [string]$Contexto = 'Limpar este Windows'
    )
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $cat  = Get-CleanWindowsCatalog
    $sel  = Read-CwSelecao $SelecaoPath
    $total = ($cat | ForEach-Object { $_.Itens.Count } | Measure-Object -Sum).Sum
    # mapa id -> padrao, para o botao "Restaurar padrao"
    $padrao = @{}
    foreach ($c in $cat) { foreach ($it in $c.Itens) { $padrao[$it.Id] = [bool]$it.Padrao } }

    $f = New-Object System.Windows.Forms.Form
    $f.Text = "Escolha o que aplicar - $Contexto"
    $f.ClientSize = New-Object System.Drawing.Size(680, 640)
    $f.StartPosition = 'CenterParent'
    $f.FormBorderStyle = 'FixedDialog'; $f.MaximizeBox = $false; $f.MinimizeBox = $false
    $f.BackColor = [System.Drawing.Color]::White

    $h = New-Object System.Windows.Forms.Label
    $h.Text = "$total itens serao aplicados"
    $h.Font = New-Object System.Drawing.Font('Segoe UI', 13, [System.Drawing.FontStyle]::Bold)
    $h.Location = New-Object System.Drawing.Point(18, 14); $h.Size = New-Object System.Drawing.Size(644, 26)
    $f.Controls.Add($h)

    $sb = New-Object System.Windows.Forms.Label
    $sb.Text = 'Marque o que quer aplicar e desmarque o que quer manter. Passe o mouse para ver o que cada item faz.'
    $sb.ForeColor = [System.Drawing.Color]::FromArgb(96, 96, 96)
    $sb.Location = New-Object System.Drawing.Point(18, 42); $sb.Size = New-Object System.Drawing.Size(644, 20)
    $f.Controls.Add($sb)

    $pan = New-Object System.Windows.Forms.Panel
    $pan.AutoScroll = $true; $pan.BorderStyle = 'FixedSingle'
    $pan.Location = New-Object System.Drawing.Point(18, 68); $pan.Size = New-Object System.Drawing.Size(644, 486)
    $pan.Anchor = 'Top,Bottom,Left,Right'    # encolhe junto com a janela em telas menores
    $f.Controls.Add($pan)

    $tip = New-Object System.Windows.Forms.ToolTip
    $tip.AutoPopDelay = 15000; $tip.InitialDelay = 300; $tip.ReshowDelay = 100
    $boxes = New-Object System.Collections.ArrayList
    # estado que os manipuladores de evento acessam (escopo de script = confiavel dentro do WinForms)
    $script:cwBoxes  = $boxes
    $script:cwHdr    = $h
    $script:cwTotal  = $total
    $script:cwPadrao = $padrao

    $y = 8
    foreach ($c in $cat) {
        $hd = New-Object System.Windows.Forms.Label
        $hd.Text = $c.Nome
        $hd.Font = New-Object System.Drawing.Font('Segoe UI', 10.5, [System.Drawing.FontStyle]::Bold)
        $hd.ForeColor = [System.Drawing.Color]::FromArgb(0x1B, 0x5E, 0x8A)
        $hd.Location = New-Object System.Drawing.Point(10, $y); $hd.Size = New-Object System.Drawing.Size(460, 22)
        $pan.Controls.Add($hd)

        $lnk = New-Object System.Windows.Forms.LinkLabel
        $lnk.Text = 'marcar/desmarcar grupo'
        $lnk.Font = New-Object System.Drawing.Font('Segoe UI', 8)
        $lnk.Location = New-Object System.Drawing.Point(474, ($y + 3)); $lnk.Size = New-Object System.Drawing.Size(140, 18)
        $grpBoxes = New-Object System.Collections.ArrayList
        $lnk.Add_LinkClicked({
            $bs = $this.Tag
            $novo = -not (@($bs | Where-Object { $_.Checked }).Count -gt 0)
            foreach ($b in $bs) { $b.Checked = $novo }
        })
        $pan.Controls.Add($lnk)
        $y += 24

        if ($c.Desc) {
            $dl = New-Object System.Windows.Forms.Label
            $dl.Text = $c.Desc
            $dl.Font = New-Object System.Drawing.Font('Segoe UI', 8)
            $dl.ForeColor = [System.Drawing.Color]::FromArgb(120, 120, 120)
            $dl.Location = New-Object System.Drawing.Point(12, $y); $dl.Size = New-Object System.Drawing.Size(596, 18)
            $pan.Controls.Add($dl)
            $y += 20
        }

        foreach ($it in $c.Itens) {
            $cb = New-Object System.Windows.Forms.CheckBox
            $cb.Text = $it.Rot
            $cb.Tag = $it.Id
            $cb.Font = New-Object System.Drawing.Font('Segoe UI', 9)
            $cb.Location = New-Object System.Drawing.Point(24, $y); $cb.Size = New-Object System.Drawing.Size(584, 20)
            if ($null -eq $sel) { $cb.Checked = [bool]$it.Padrao } else { $cb.Checked = $sel.Contains($it.Id) }
            if ($it.Detalhe) { $tip.SetToolTip($cb, $it.Detalhe) }
            $cb.Add_CheckedChanged({
                $n = @($script:cwBoxes | Where-Object { $_.Checked }).Count
                $script:cwHdr.Text = "$n de $($script:cwTotal) itens serao aplicados"
            })
            $pan.Controls.Add($cb); [void]$boxes.Add($cb); [void]$grpBoxes.Add($cb)
            $y += 22
        }
        $lnk.Tag = $grpBoxes.ToArray()
        $y += 10
    }

    # ---- botoes (ancorados na base, para continuarem visiveis se a janela encolher) ----
    $bPad = New-Object System.Windows.Forms.Button
    $bPad.Text = 'Restaurar padrao'
    $bPad.Location = New-Object System.Drawing.Point(18, 566); $bPad.Size = New-Object System.Drawing.Size(130, 30)
    $bPad.Anchor = 'Bottom,Left'
    $bPad.Add_Click({ foreach ($b in $script:cwBoxes) { $b.Checked = [bool]$script:cwPadrao[[string]$b.Tag] } })
    $f.Controls.Add($bPad)

    $bAll = New-Object System.Windows.Forms.Button
    $bAll.Text = 'Marcar tudo'
    $bAll.Location = New-Object System.Drawing.Point(156, 566); $bAll.Size = New-Object System.Drawing.Size(100, 30)
    $bAll.Anchor = 'Bottom,Left'
    $bAll.Add_Click({ foreach ($b in $script:cwBoxes) { $b.Checked = $true } })
    $f.Controls.Add($bAll)

    $bNone = New-Object System.Windows.Forms.Button
    $bNone.Text = 'Desmarcar tudo'
    $bNone.Location = New-Object System.Drawing.Point(264, 566); $bNone.Size = New-Object System.Drawing.Size(110, 30)
    $bNone.Anchor = 'Bottom,Left'
    $bNone.Add_Click({ foreach ($b in $script:cwBoxes) { $b.Checked = $false } })
    $f.Controls.Add($bNone)

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = 'Aplicar selecao'; $ok.Font = New-Object System.Drawing.Font('Segoe UI', 9.5, [System.Drawing.FontStyle]::Bold)
    $ok.Location = New-Object System.Drawing.Point(444, 566); $ok.Size = New-Object System.Drawing.Size(138, 30)
    $ok.Anchor = 'Bottom,Right'
    $ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $f.Controls.Add($ok)

    $no = New-Object System.Windows.Forms.Button
    $no.Text = 'Cancelar'
    $no.Location = New-Object System.Drawing.Point(590, 566); $no.Size = New-Object System.Drawing.Size(72, 30)
    $no.Anchor = 'Bottom,Right'
    $no.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $f.Controls.Add($no)

    $f.AcceptButton = $ok; $f.CancelButton = $no
    $h.Text = "$(@($boxes | Where-Object { $_.Checked }).Count) de $total itens serao aplicados"

    # Cabe em telas pequenas / com escala de tela alta: se a janela for mais alta que a area
    # util, encolhe (o painel tem rolagem e os botoes ficam ancorados na base, sempre visiveis).
    try {
        $wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height
        if ($f.Height -gt $wa) { $f.Height = $wa }
    } catch {}

    $r = $f.ShowDialog($Parent)
    if ($r -eq [System.Windows.Forms.DialogResult]::OK) {
        $ids = @($boxes | Where-Object { $_.Checked } | ForEach-Object { [string]$_.Tag })
        Write-CwSelecao $SelecaoPath $ids
        return $true
    }
    return $false
}
