<p align="center">
  <img src="CleanWindows-preview.png" width="140" alt="Clean Windows">
</p>

# Clean Windows 1.2

Monte a **sua** edição enxuta do Windows 11, a partir da ISO **oficial da Microsoft**:
sem bloatware, sem telemetria, sem Copilot/Recall/Widgets/OneDrive, com os ajustes de
jogos ligados — e com **todo o código aberto**, para você (e o antivírus) lerem antes de rodar.

Dá para usar de dois jeitos:

- **Limpar o Windows que já está instalado** nesta máquina (nada é formatado); ou
- **Criar um pendrive** que instala um Windows 11 já limpo do zero em qualquer PC.

> **Baixar:** pegue o `clean-windows-1.2.zip` na aba **[Releases](../../releases)**, extraia
> numa pasta e siga o passo a passo abaixo.

## O que voce ganha

- **Mais leve:** menos programas e servicos rodando em segundo plano, menos RAM ocupada.
- **Mais rapido no dia a dia:** sem transparencia, sombras e animacoes que pesam na tela.
- **Mais privado:** sai a telemetria, o Copilot/Recall, os apps promovidos e o OneDrive.
- **Menos incomodo:** sem propaganda no Iniciar, sem Widgets, e (opcional) sem o popup de
  administrador a cada acao.
- **Se mantem limpo:** apos uma atualizacao do Windows que reponha o bloatware, o programa
  reaplica os ajustes sozinho.
- **Voce ve o resultado:** ao final, o programa mostra **quanto o seu Windows ficou mais
  enxuto** (processos, RAM, apps e servicos, antes e depois).

Defender, Secure Boot, TPM, Windows Update e a Microsoft Store continuam **ligados** — a sua
protecao nao e desativada.

---

## Como começar

1. Extraia o `clean-windows-1.2.zip` numa pasta (ex.: `C:\Clean Windows`).
2. Dê **dois cliques em `preparar.cmd`** — só na primeira vez. Ele desbloqueia os arquivos
   e cria o **`CleanWindows.exe`** (usando o compilador que já vem no Windows; nada é baixado).
3. Dê **dois cliques em `CleanWindows.exe`**. Abre um menu com duas opções:

| Opção | O que faz |
|---|---|
| **Limpar ESTE Windows** | Aplica os ajustes no Windows já instalado. Nada é formatado; seus arquivos e programas continuam onde estão. |
| **Criar pendrive de instalação** | Grava um pendrive para instalar o Windows 11 já limpo em qualquer PC. **O pendrive é apagado.** |

Se preferir não gerar o `.exe`, o `clean-windows.cmd` faz o mesmo (mostrando uma janela
de terminal por um instante).

---

## Opção 1 — Limpar o Windows atual

1. Se você usa OneDrive, **tire seus arquivos da pasta do OneDrive antes** (o script o desinstala).
2. Abra o `CleanWindows.exe` → **Limpar ESTE Windows**.
3. Deixe marcado **"Criar um ponto de restauração antes"** (recomendado).
4. Confirme. Uma janela mostra o progresso; ao terminar, **reinicie o PC**.

Depois do reinício, ele fica assim para sempre — e, a cada **atualização de versão** do
Windows (ex.: 25H2 → 26H1), o Clean Windows se **reaplica sozinho**: avisa na tela, cria um
ponto de restauração e refaz os ajustes (as atualizações de versão costumam reinstalar
Copilot, Widgets e OneDrive). Para desligar isso, edite `AutoReapplyAfterUpdate = $false`
no topo do `freedom-tweaks.ps1`.

---

## Opção 2 — Criar o pendrive de instalação

Você vai precisar de: a **ISO oficial do Windows 11** (baixe em
<https://www.microsoft.com/software-download/windows11>) e um **pendrive de 8 GB ou mais**
(ele será apagado).

1. Abra o `CleanWindows.exe` → **Criar pendrive de instalação**.
2. **ISO:** clique em *Procurar...* e escolha a ISO baixada.
3. **Pendrive:** escolha o seu na lista (só aparecem dispositivos USB). Se não aparecer,
   conecte e clique em *Atualizar*.
4. **Incluir o kit:** deixe marcado (instalação automática, sem perguntas, cria a conta
   local **Freedom**).
5. **Licença do destino** — a escolha mais importante; o programa detecta e sugere:
   - **PC de marca** (Acer, Dell, Lenovo, Positivo...): usa a chave gravada na placa. Instala
     a edição certa e ativa sozinho. *(É a opção correta para a maioria dos notebooks.)*
   - **PC montado — Pro** ou **— Home**: usa uma chave genérica de instalação; você ativa
     depois com a sua chave.
6. **Criar pendrive** e confirme. Ao terminar, ejete o pendrive com segurança.

### Instalar no PC de destino

1. Ligue o PC com o pendrive espetado e abra o **menu de boot** da BIOS
   (Acer/Lenovo/Dell: **F12**; ASUS: **F8**; MSI: **F11**), escolhendo o pendrive em **modo UEFI**.
2. Aperte uma tecla quando aparecer *"Press any key to boot from..."*.
3. A única pergunta é **onde instalar**: escolha o disco/partição de destino. Em PC com mais
   de um disco, confira pelo tamanho para não apagar o disco errado.
4. O resto é automático: sem telas de idioma, conta Microsoft, Wi-Fi ou privacidade. No
   primeiro logon o sistema aplica a limpeza sozinho e reinicia uma vez.

Depois de instalado: conecte à internet, instale o driver da placa de vídeo
(NVIDIA/AMD/Intel) e rode o `apps.ps1` (em `C:\Windows\Setup\Scripts`) para instalar Steam,
Discord, Visual C++ etc.

---

## O que é removido e o que fica

**Removido:** apps promovidos e pré-instalados (Bing, Copilot, Clipchamp, Solitaire, Teams,
Outlook novo, Notícias, Mapas...), telemetria e tarefas de diagnóstico, Copilot e Recall,
Widgets, Chat, e o OneDrive.

**Fica ligado de propósito:** Microsoft Defender, Secure Boot, TPM, Windows Update e a
Microsoft Store — desligar isso é o que faz as "edições piratas" quebrarem com o tempo e
travarem anti-cheats de jogos. A Segurança do Windows continua ativa.

**Ajustes de jogos:** Game Mode ligado, Game DVR desligado, HAGS, plano de energia de alto
desempenho (em notebook, ajuste `PowerPlanUltimate = $false`), mouse sem aceleração.

**Leveza visual:** desliga transparencia, sombras e animacoes (mantendo o ClearType das
fontes). **UAC:** opcionalmente (`SilenciarUAC`), contas de administrador elevam sem o popup
"Deseja permitir..." — isso **nao desliga o UAC**: a protecao, a sandbox de apps e a
Microsoft Store continuam funcionando.

Cada item liga/desliga no bloco `$Cfg`, no topo do `freedom-tweaks.ps1`.

---

## Termo de uso

Antes de **limpar o Windows** ou **criar o pendrive**, o programa mostra um termo de uso que
o usuário precisa ler e aceitar (marcar "Li e concordo"). O termo deixa claro o que o
programa faz — remove o que a Microsoft usa para observar o uso e que deixa o PC pesado, e
ajuda a proteger a privacidade — e que a **responsabilidade é inteiramente do usuário**.
Sem o aceite, nada é executado.

## Atualizações automáticas

Toda vez que o `CleanWindows.exe` (ou o `clean-windows.cmd`) abre, ele pergunta ao GitHub
qual é a última versão publicada. Se houver uma **Release mais nova** que a instalada, aparece
"Nova versão X disponível — baixar agora?". Se a pessoa disser **Sim**, ele baixa o `.zip` da
Release, extrai na pasta Downloads e abre a pasta — aí é só rodar o `preparar.cmd` e o
`CleanWindows.exe` de lá. Nada é executado sozinho, e se o PC estiver offline a verificação
passa em silêncio.

**Para lançar uma nova versão** (é isso que dispara o aviso em quem já baixou):
1. Aumente `$Versao` no topo do `clean-windows.ps1` (ex.: `'1.1'`).
2. Publique uma **Release** no GitHub com a tag correspondente (ex.: `v1.1`) e o `.zip` anexado.

Um commit sozinho não avisa ninguém — o que os clientes comparam é o número da Release.
Para desligar a verificação, deixe `$RepoUpdate = ''`.

## Antivírus

Um antivírus **pode marcar** estes scripts — é um falso positivo previsível: eles fazem o
que um programa indesejado também faria (mexer no registro, desativar serviços), e a
heurística não distingue intenção. Ferramentas conhecidas do gênero passam pelo mesmo.

Por isso, aqui **nada é escondido**: o código é texto legível, sem ofuscação nem download em
tempo de execução. O `preparar.cmd` remove a "marca da web" dos arquivos, gera um
`SHA256SUMS.txt` para conferência e, com `preparar.cmd -Assinar`, cria um certificado da
própria máquina e assina os scripts. O kit **nunca** desliga o Defender. Se o Defender
bloquear algo, abra o arquivo, leia, e só então decida adicionar a pasta às exclusões.

---

## Feedback e apoio

No menu há **Feedback** (abre seu e-mail já preenchido) e **Apoiar o projeto** (chave Pix
para copiar). O Clean Windows é gratuito e continua assim; qualquer valor ajuda.

---

## Aviso de marca

Projeto **independente**, **não afiliado nem endossado pela Microsoft**. *Windows* é marca
registrada da Microsoft Corporation; o nome é usado apenas para indicar compatibilidade.

## Licença

[MIT](LICENSE) © enriquevic
