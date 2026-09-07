# Clean Windows 1.0 — monte a SUA edição do Windows 11

> **Baixar:** pegue o arquivo `clean-windows.zip` na aba **Releases** deste repositório,
> extraia numa pasta e dê dois cliques em **`preparar.cmd`** (uma vez) e depois em
> **`CleanWindows.exe`**. Todo o código é aberto de propósito — leia antes de rodar.


Este kit transforma a **ISO oficial da Microsoft** numa ISO sua: sem bloatware, sem
telemetria, sem OneDrive/Copilot/Widgets/Teams, com os ajustes de desempenho que as
"gaming editions" fazem — só que **todo o código está aqui, em texto claro, para você
ler e editar**. Nada é baixado de terceiros, nenhum binário desconhecido roda no seu PC.

## Por que fazer assim (e não baixar uma "Gaming Edition" pronta)

| Edição pronta (Ghost Spectre, etc.) | Clean Windows |
|---|---|
| ISO remontada por desconhecidos; impossível auditar | ISO oficial + scripts que você lê |
| Costuma arrancar componentes com DISM; Windows Update e Store quebram | Componentes ficam; só apps e políticas mudam. Update, Store, Game Pass e anti-cheats funcionam |
| Desliga Defender, Secure Boot, mitigações | Defender, Secure Boot, TPM e Update continuam ligados (verificável com `verify.ps1`) |
| "Ganha 30% de FPS" | Ganhos reais vêm de poucas coisas: VBS off, Game DVR off, plano de energia, sem apps de fundo. É isso que o kit faz |

## Arquivos

| Arquivo | O que faz | Quando roda |
|---|---|---|
| `build-iso.ps1` | Extrai a ISO oficial, exporta só a edição escolhida, remove 40+ apps pré-instalados da imagem, aplica políticas offline (telemetria, apps promovidos, Chat, Copilot, OneDrive), injeta o `autounattend.xml` e os scripts, gera a ISO final | Uma vez, no seu PC atual |
| `autounattend.xml` | Instalação sem perguntas: pt-BR/ABNT2, fuso de Brasília, sem conta Microsoft, sem Wi-Fi obrigatório, sem telas de privacidade, conta local `Freedom`. **Não** particiona disco sozinho | Durante a instalação |
| `freedom-tweaks.ps1` | Todos os tweaks online: telemetria, privacidade, Copilot/Recall, Widgets, OneDrive, Game Mode, Game DVR off, HAGS, MMCSS, mouse sem aceleração, plano de energia, VBS off, hibernação off, serviços, tarefas agendadas, Edge, QoL do Explorador | Automático no 1º logon (e quando você quiser) |
| `apps.ps1` | Instala Steam, Discord, VC++ AIO, DirectX, Gaming Services etc. via `winget` | Você roda, depois de conectar à internet |
| `freedom-watch.ps1` | Vigia de atualizações: no logon, compara a versão do Windows com a última registrada. Se o Windows se atualizou, avisa na tela, cria um ponto de restauração e roda o `freedom-tweaks.ps1` de novo | Automático (tarefa agendada) |
| `verify.ps1` | Mostra `[OK]`/`[--]` para cada ajuste e confirma que Defender, Secure Boot, TPM e Update seguem ligados | Você roda, quando quiser conferir |
| `make-kit-iso.py` | Gera o `kit.iso`: um "segundo DVD" só com `autounattend.xml` + scripts. Permite instalar/testar **sem** o `build-iso.ps1` (e sem Windows para montar a ISO) | No Linux/macOS/Windows, uma vez |
| `vbox-create.sh` | Cria a VM no VirtualBox 7 já com EFI, TPM 2.0, Secure Boot, 80 GB, ISO oficial no DVD 1 e `kit.iso` no DVD 2 | No Linux/macOS, uma vez |
| `preparar.ps1` + `preparar.cmd` | **Rode uma vez ao copiar o kit para um PC.** Remove a "marca da web" dos arquivos, compila o `CleanWindows.exe` com o compilador que já vem no Windows e (com `-Assinar`) assina os scripts com um certificado da própria máquina | No Windows, uma vez por PC |
| `CleanWindowsLauncher.cs` + `.manifest` + `.ico` | Código-fonte do `CleanWindows.exe`: um lançador de 5 KB que abre o menu sem janela preta e pede a permissão de administrador uma única vez | Lido/compilado pelo `preparar.ps1` |
| `clean-windows.ps1` + `clean-windows.cmd` | **Ponto de entrada.** Menu com as duas opções: *Limpar ESTE Windows* (roda o `freedom-tweaks.ps1` na máquina atual) ou *Criar pendrive de instalação* (abre o gravador). Duplo clique no `.cmd` | No Windows, sempre que for usar o kit |
| `criar-pendrive.ps1` + `criar-pendrive.cmd` | **Clean Windows** com janela: escolhe a ISO e o pendrive, apaga, cria GPT + FAT32, copia a ISO, divide o `install.wim` em `.swm` se passar de 4 GB, injeta o kit e (opcional) drivers. Só ferramentas nativas do Windows | No Windows (inclusive a VM), para o PC real |
| `usb-ventoy.sh` | Copia ISO oficial + `autounattend.xml` + `Scripts` + `$OEM$` para um pendrive Ventoy e configura o plugin `auto_install`. `--oem-key` deixa o instalador usar a chave gravada na placa (PC de marca) | No Linux/macOS, para o PC real |

## Passo a passo

### 1. Baixe a ISO oficial
https://www.microsoft.com/pt-br/software-download/windows11 → "Baixar imagem de disco (ISO)
do Windows 11", idioma **Português (Brasil)**. Guarde em, por exemplo, `D:\ISOs\`.

### 2. Instale o oscdimg (gera a ISO)
Windows ADK: https://learn.microsoft.com/windows-hardware/get-started/adk-install
No instalador marque **somente "Deployment Tools"**. Isso instala o `oscdimg.exe` no
caminho que o script já procura. (Alternativa sem ADK: seção *Sem oscdimg* abaixo.)

### 3. Personalize (opcional)
- `build-iso.ps1` → lista `$RemoveApps` (o que sai da imagem).
- `autounattend.xml` → nome do usuário/senha, nome do PC, chave de produto.
- `freedom-tweaks.ps1` → bloco `$Cfg` no topo. Cada linha tem o motivo ao lado.
  Em **notebook**, deixe `PowerPlanUltimate = $false`.

### 4. Gere a ISO
Abra o **PowerShell como Administrador** na pasta do kit:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\build-iso.ps1 -IsoPath "D:\ISOs\Win11_24H2_BrazilianPortuguese_x64.iso" -Edition "Windows 11 Pro"
```

Opções: `-Edition "Windows 11 Home"`, `-DriversPath "D:\drivers"` (integra .inf de
chipset/LAN/NVMe), `-RemoveXbox` (tira Xbox app e Game Bar; **não** use se joga Game Pass
ou usa controle Xbox sem fio), `-WorkDir`, `-OutputIso`.
Leva de 15 a 40 minutos. Resultado: `C:\WinGamingBuild\CleanWindows.iso`.

### 5. Teste numa VM antes do PC real
Hyper-V (Geração 2, com TPM habilitado) ou VirtualBox 7 (EFI + TPM 2.0 + Secure Boot).
Instale, espere o reboot automático do primeiro logon, rode `verify.ps1`.
No Linux, veja a seção *Testar no VirtualBox* abaixo (o `vbox-create.sh` aceita a
`CleanWindows.iso` no lugar da oficial; nesse caso o `kit.iso` é dispensável).

### 6. Grave e instale
Rufus (https://rufus.ie) → selecione a ISO → GPT / UEFI → gravar. Deixe as opções
extras do Rufus desmarcadas (o kit já cuida disso). Boot pelo pendrive, escolha o
disco/partição na tela do instalador, e o resto é automático.

### 7. Depois de instalar
1. Conecte à internet e instale o driver da GPU direto da NVIDIA/AMD/Intel.
2. `powershell -ExecutionPolicy Bypass -File C:\Windows\Setup\Scripts\apps.ps1`
3. `powershell -ExecutionPolicy Bypass -File C:\Windows\Setup\Scripts\verify.ps1`
4. Se o Windows Update ficar trocando seu driver de GPU, ative `BlockDriverUpdates`
   no `freedom-tweaks.ps1` e rode-o de novo.

## Dois jeitos de usar o kit

| | ISO customizada (`build-iso.ps1`) | ISO oficial + `kit.iso` (segundo DVD) |
|---|---|---|
| Precisa de Windows para montar | Sim (DISM/oscdimg) | **Não** (só Python) |
| Apps removidos | Offline, antes de instalar | Online, no primeiro logon |
| Só a edição escolhida na mídia | Sim | Não (a chave do XML escolhe a Pro) |
| Resultado final no PC | Idêntico | Idêntico |

Se você está no Linux, comece pelo segundo jeito. O primeiro fica para quando tiver um
Windows à mão (inclusive a própria VM que você vai criar agora).

## Testar no VirtualBox a partir do Linux (passo a passo)

1. **Gerar o `kit.iso`** (só na primeira vez ou depois de editar os scripts):
   ```bash
   pip install pycdlib        # ou veja o cabeçalho do make-kit-iso.py se não tiver pip
   python3 make-kit-iso.py
   ```
2. **Criar a VM** (EFI, TPM 2.0, Secure Boot, 8 GB, 4 CPUs, 80 GB; ajuste com `RAM=`, `CPUS=`):
   ```bash
   ./vbox-create.sh ~/Downloads/Win11_25H2_BrazilianPortuguese_x64_v2.iso ./kit.iso
   ```
   Ou na mão, pelo VirtualBox: Nova → tipo *Windows 11 (64-bit)* → "Pular instalação
   desassistida" → 8192 MB / 4 CPUs → disco 80 GB → em *Sistema* marque **EFI**,
   **TPM 2.0** e **Secure Boot** → em *Armazenamento* adicione **dois** drives ópticos:
   a ISO oficial e o `kit.iso`.
3. **Iniciar a VM** e apertar uma tecla quando aparecer *Press any key to boot from CD or DVD*.
   Se perder o momento e cair no shell EFI, digite `exit`, entre em *Boot Manager* e
   escolha o DVD.
4. O instalador já vem em português e pula idioma, EULA e chave. Na tela de disco,
   selecione o *Espaço não alocado* do disco 0 e clique em Avançar. (Para nem isso
   perguntar, habilite o bloco `DiskConfiguration` comentado no `autounattend.xml`,
   **apenas para VM**.)
5. Sem perguntas de conta Microsoft, Wi-Fi ou privacidade. O primeiro logon entra
   como `Freedom`, roda o `freedom-tweaks.ps1` (janela azul do PowerShell, 1 a 3 min)
   e reinicia sozinho uma vez.
6. Depois do reboot: *Dispositivos → Inserir CD dos Adicionais para Convidado* e
   instale (resolução/clipboard). Aí confira:
   ```powershell
   powershell -ExecutionPolicy Bypass -File C:\Windows\Setup\Scripts\verify.ps1
   ```
   Na VM, HAGS e plano Desempenho Máximo podem aparecer como `[--]`: o VirtualBox não
   expõe esses recursos. Todo o resto deve ser `[OK]`.
7. Gostou? Use a **mesma VM** para rodar o `build-iso.ps1` (pasta compartilhada com o
   kit + ISO) e produzir a `CleanWindows.iso` para o PC real. Ou pule isso e instale no
   PC real com a ISO oficial num pendrive + `kit.iso` gravado num segundo pendrive
   (funciona igual: o instalador procura o `autounattend.xml` em qualquer mídia removível).

Para apagar a VM depois: `VBoxManage unregistervm "Win11-Gaming" --delete`.

## Por onde começar (no Windows)

**Primeira vez num PC:** duplo clique em `preparar.cmd`. Ele desbloqueia os arquivos e cria
o **`CleanWindows.exe`**. Depois disso, use sempre o `CleanWindows.exe`: ele abre o menu
direto, sem janela preta de linha de comando, e pede a permissão de administrador uma vez só.

Se preferir não gerar o `.exe`, o `clean-windows.cmd` faz o mesmo (mostrando uma janela
preta por um instante).

O menu tem as duas opções do projeto:

| Opção | O que faz |
|---|---|
| **Limpar ESTE Windows** | Aplica tudo no Windows já instalado nesta máquina. Oferece criar um ponto de restauração antes. Nada é formatado |
| **Criar pendrive de instalação** | Abre o gravador de pendrive para instalar do zero em qualquer PC. Pergunta a licença do PC de destino. O pendrive é apagado |

Os dois caminhos usam os mesmos scripts; o menu só escolhe qual rodar. Se preferir ir
direto a um deles, o `criar-pendrive.cmd` continua funcionando sozinho, e o
`freedom-tweaks.ps1` também.

## Instalar no PC real a partir do Windows (gravador de pendrive)

Se você tem um Windows à mão (o seu atual ou a VM), o menu do `clean-windows.cmd` →
**Criar pendrive de instalação** faz o papel do Rufus, sem baixar nada: duplo clique → escolha a ISO (oficial ou `CleanWindows.iso`) →
escolha o pendrive → marque "PC de marca" se a chave estiver na placa → **Criar pendrive**.
Ele apaga o pendrive, cria GPT + FAT32, copia a ISO, injeta `autounattend.xml` +
`sources\$OEM$` + `\Scripts`, e copia uma pasta de drivers se você indicar. Quando a imagem
passa de 4 GB, ela é dividida em `install.swm`/`install2.swm` com o DISM, que é o método
oficial da Microsoft para FAT32. **Validado numa VM com Windows 11 25H2:** o pendrive dá
boot em UEFI com Secure Boot, o instalador pula idioma/teclado/chave pelo `autounattend.xml`
e chega à tela de seleção de disco.

Três armadilhas que o programa evita, todas descobertas em teste real:

1. **Nunca marque a partição como EFI System Partition.** O Windows oculta volumes ESP e não
   lhes dá letra, então o próprio instalador não lê a mídia e mostra "Instalar driver para
   mostrar o hardware". Rufus e a ferramenta da Microsoft usam partição comum.
2. **A imagem tem que ficar na mesma partição de boot.** O Setup não procura `install.wim`
   em outras partições, então o esquema de duas partições não funciona.
3. **Cache de escrita.** Arquivos de vários GB podem ficar só na memória; o programa força a
   gravação e confere se a soma dos `.swm` bate com a imagem original antes de dizer que
   terminou.

**Licença do destino** (a pergunta mais importante da tela): o programa detecta se a máquina
atual tem chave de fábrica na placa (tabela ACPI `MSDM`) e mostra isso no log. Escolha:

| Opção | O que grava no `autounattend.xml` | Quando usar |
|---|---|---|
| **PC de marca** (padrão) | Nenhuma chave | Acer, Dell, Lenovo, Positivo... O instalador lê a chave da placa, instala a edição certa e ativa sozinho |
| **PC montado — Pro** | Chave genérica de instalação do Pro | PC sem licença de fábrica; ative depois com a sua chave |
| **PC montado — Home** | Chave genérica de instalação do Home | Idem, se sua licença for Home |

As chaves genéricas **não ativam nada**, só evitam a pergunta e escolhem a edição. O erro caro
é instalar Pro por chave genérica num PC cuja licença de fábrica é Home: não ativa, e o Windows
não rebaixa edição, então só reinstalando. Por isso o padrão é "PC de marca", que é seguro nos
dois casos: se não houver chave na placa, o instalador apenas pergunta a edição.

Limites: só boot UEFI (Windows 11 exige). Funciona com a ISO oficial e com a do Media
Creation Tool. Em disco fixo (não removível), o programa desliga o BitLocker que o Windows
11 25H2 tenta ligar sozinho; num pendrive USB comum isso não ocorre.

**Testar dentro da VM antes de usar de verdade** (o VirtualBox sem Extension Pack só passa
USB 1.1, lento demais para 7 GB; então testamos com um disco virtual fazendo papel de
pendrive):
```bash
# com a VM Win11-Gaming DESLIGADA
VBoxManage createmedium disk --filename ~/"VirtualBox VMs/Win11-Gaming/pendrive-teste.vdi" --size 16384 --format VDI
VBoxManage storageattach Win11-Gaming --storagectl SATA --port 3 --device 0 --type hdd --medium ~/"VirtualBox VMs/Win11-Gaming/pendrive-teste.vdi"
```
Na VM, pasta compartilhada com o kit (Dispositivos → Pastas Compartilhadas) ou copie o kit
para dentro, e rode `powershell -ep bypass -sta -f criar-pendrive.ps1 -AllowFixedDisk`
(o `-AllowFixedDisk` lista o disco virtual, que não é USB). Depois crie uma VM nova que use
o `pendrive-teste.vdi` como primeiro disco e um disco vazio como segundo: se o instalador
subir e chegar na tela de disco, o pendrive está bom.

## Instalar no PC real a partir do Linux (pendrive Ventoy)

O Rufus só existe para Windows. No Linux, o caminho mais simples é o **Ventoy**: o pendrive
vira exFAT (sem limite de 4 GB), você copia a ISO oficial como arquivo e o kit fica na raiz.

### Antes de começar
1. **Backup** de tudo que está no Windows atual (pasta `C:\Users\<voce>`, área de trabalho,
   downloads, saves de jogos). A partição vai ser formatada.
2. **Edição da licença**: PC de marca (Acer, Dell, Lenovo...) tem a chave gravada na placa
   (tabela ACPI `MSDM`; no Linux `ls /sys/firmware/acpi/tables/MSDM`). Nesse caso use
   `--oem-key` no `usb-ventoy.sh`: o instalador lê a chave sozinho e escolhe a edição certa
   (Home/Pro), e a licença digital ativa ao conectar à internet. PC montado com licença
   comprada: deixe a chave genérica e ative depois com a sua, ou coloque a sua no XML.
3. **Revise `$Cfg`** no `freedom-tweaks.ps1`: notebook → `PowerPlanUltimate = $false`;
   dual boot com Linux → `DualBootUtcClock = $true`; sem Game Pass/controle Xbox →
   `KeepXboxApps = $false`.
4. **Drivers**: baixe antes o driver de rede/Wi-Fi do fabricante para um pendrive, por
   garantia. GPU e chipset podem vir depois pela internet.

### Preparar o pendrive (8 GB ou mais; ele será apagado)
```bash
lsblk -o NAME,SIZE,MODEL,TRAN            # identifique o pendrive pelo tamanho e TRAN=usb
# baixe ventoy-X.Y.Z-linux.tar.gz em https://github.com/ventoy/Ventoy/releases e extraia
sudo sh Ventoy2Disk.sh -i /dev/sdX        # sdX = o PENDRIVE (nunca o disco interno!)
# remova e reinsira o pendrive; ele monta em /media/$USER/Ventoy
./usb-ventoy.sh /media/$USER/Ventoy ~/Downloads/Win11_25H2_BrazilianPortuguese_x64_v2.iso --oem-key
```
Se o Secure Boot estiver ligado na BIOS, o Ventoy pede para registrar a chave dele na
primeira vez (tela azul do MOK Manager: *Enroll key from disk → VTOYEFI →
ENROLL_THIS_KEY_IN_MOKMANAGER.cer*). Mais simples: desligar o Secure Boot só durante a
instalação e religar depois. O instalador do Windows 11 exige apenas que o firmware seja
*capaz* de Secure Boot, não que esteja ligado.

### Instalar
1. Reinicie com o pendrive, abra o menu de boot da BIOS (Acer/Lenovo: F12; ASUS: F8; MSI:
   F11; Dell: F12; Gigabyte: F12) e escolha o pendrive **em modo UEFI**. Use o menu de
   boot único em vez de mudar a ordem, assim o disco continua primeiro depois.
2. No menu do Ventoy, escolha a ISO → *Boot in normal mode*. Deixe o Ventoy selecionar o
   `autounattend.xml` sozinho (5 s). Aperte uma tecla no *Press any key*.
3. Única pergunta: **onde instalar**. Selecione a partição do Windows antigo (pelo tamanho,
   ex.: 222,8 GB), clique em **Formatar Partição**, confirme, mantenha-a selecionada e
   **Avançar**. Não apague nem toque nas partições do Linux, na EFI (~100 MB a 1 GB, FAT32)
   nem no disco de dados. Se o PC é só Windows e você quer zerar o disco, apague todas as
   partições daquele disco e selecione o espaço não alocado.
4. Nos reboots seguintes, não aperte tecla nenhuma. Deixe o pendrive conectado até o
   primeiro logon terminar (o script pode rodar a partir dele).
5. Primeiro logon como `Freedom`: janela do PowerShell, reinício automático. Pronto.

### Depois da instalação
1. Conecte à internet. Configurações → Sistema → Ativação deve mostrar "ativado".
2. Driver da GPU (NVIDIA/AMD/Intel) e chipset direto do fabricante; Windows Update; reinicie.
3. `powershell -ep bypass -f C:\Windows\Setup\Scripts\verify.ps1` — tudo `[OK]`.
4. `powershell -ep bypass -f C:\Windows\Setup\Scripts\apps.ps1` — Steam, VC++ etc.
5. Religue o **Secure Boot** na BIOS (anti-cheats como Vanguard/FACEIT exigem). Confira em
   `msinfo32` → "Estado do Secure Boot: Ativado".
6. Se o Windows Update ficar trocando o driver da GPU: `BlockDriverUpdates = $true` e rode o
   `freedom-tweaks.ps1` de novo.

### Dual boot com Linux: o que muda
- O instalador reaproveita a partição EFI existente e coloca o Windows em primeiro na ordem
  de boot. Para voltar o GRUB ao primeiro lugar, no Linux: `sudo efibootmgr` (veja o número
  da entrada `debian`/`ubuntu`) e `sudo efibootmgr -o XXXX,YYYY`. O GRUB já lista o Windows
  (`sudo update-grub` se não listar).
- `DualBootUtcClock = $true` evita a hora trocar a cada alternância de sistema.
- Inicialização Rápida e hibernação já ficam desligadas pelo kit; isso é obrigatório para o
  Linux montar a partição NTFS sem "disco sujo".
- Com Secure Boot religado, o Linux continua iniciando (shim assinado), mas drivers de
  kernel fora da árvore (ex.: NVIDIA proprietário no Debian) precisam de assinatura MOK.

## Reaplicação automática depois das atualizações do Windows

Atualizações mensais de segurança não desfazem nada. Já as **atualizações de versão**
(25H2 → 26H1, por exemplo) são uma reinstalação por cima: reinstalam Copilot, Widgets,
DevHome e OneDrive, reativam tarefas de telemetria e religam o VBS.

Por isso o `freedom-tweaks.ps1` cria, por padrão (`AutoReapplyAfterUpdate = $true`), a tarefa
agendada **"Clean Windows - reaplicar apos atualizacao"**. No logon, 3 minutos depois, ela roda
o `freedom-watch.ps1`, que:

1. Compara a versão do Windows com a guardada em `HKLM\SOFTWARE\CleanWindows`.
2. Se nada mudou, sai em silêncio — você nunca vê nada.
3. Se o Windows se atualizou, mostra um aviso na tela ("Criando uma imagem de segurança do
   sistema e reaplicando os ajustes"), cria o ponto de restauração e roda o
   `freedom-tweaks.ps1 -RestorePoint`.

Para desligar, ponha `AutoReapplyAfterUpdate = $false` e rode o script uma vez: ele remove a
tarefa. Para testar sem esperar uma atualização:
```powershell
powershell -ep bypass -f C:\Windows\Setup\Scripts\freedom-watch.ps1 -Force
```
Log em `C:\Windows\Setup\Scripts\freedom-watch.log`.

## Usar só o `freedom-tweaks.ps1` num Windows já instalado
Funciona sem a ISO: o script remove os apps e aplica todas as políticas online, então o
resultado é o mesmo da instalação limpa (menos a limpeza de programas/drivers que você
mesmo instalou).

1. Copie `freedom-tweaks.ps1`, `apps.ps1` e `verify.ps1` para o PC (pendrive, zip...).
2. **Se usa OneDrive**, tire seus arquivos da pasta OneDrive antes: o script o desinstala.
3. Ajuste `$Cfg` no topo do script (notebook: `PowerPlanUltimate = $false`).
4. Botão direito no PowerShell → *Executar como administrador*, e na pasta dos arquivos:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\freedom-tweaks.ps1 -RestorePoint
   ```
   `-RestorePoint` cria um ponto de restauração antes de mexer em qualquer coisa.
5. Reinicie e rode `C:\Windows\Setup\Scripts\verify.ps1` (o script se copia para lá).

Apps promovidos que já vieram instalados (Candy Crush, Spotify, TikTok...) variam de PC
para PC. Veja o nome com `Get-AppxPackage | Select Name` e acrescente na lista
`$BloatApps`. Conta Microsoft já existente continua funcionando; nada é convertido.

## Feedback e apoio ao projeto

O menu tem dois botões no rodapé:

- **Feedback** abre o programa de e-mail do usuário com assunto e mensagem já começados,
  endereçados a `roothub.softwares@gmail.com`, e inclui a versão do Windows dele para ajudar
  a entender problemas relatados. Para mudar o destinatário, edite `$EmailFeedback` no topo
  do `clean-windows.ps1`.
- **Apoiar o projeto** fica desabilitado enquanto não houver forma de doação configurada.
  No topo do `clean-windows.ps1` preencha:
  - `$ChavePix` — sua chave Pix (CPF, e-mail, telefone ou aleatória). O botão copia a chave
    para a área de transferência. Taxa zero, e é o meio que o público brasileiro já usa.
  - `$UrlDonativo` — página de doação para quem prefere cartão ou está fora do Brasil,
    por exemplo `https://ko-fi.com/seu-usuario`. O Ko-fi não cobra comissão sobre doações
    avulsas, ao contrário do Buy Me a Coffee (5%).

  Basta preencher um dos dois; o botão liga sozinho e mostra só o que estiver configurado.

A versão fica em `$Versao`, também no topo do `clean-windows.ps1`, e aparece na barra de
título, no canto da janela e no assunto do e-mail de feedback.

## Antivírus: por que pode reclamar, e o que fazer

É honesto dizer de saída: **um antivírus pode marcar estes scripts**, e isso é um falso
positivo previsível. Eles fazem exatamente o que um programa indesejado também faria —
remover apps, desligar serviços e tarefas, mexer no registro, criar tarefa agendada — e a
heurística não sabe distinguir intenção. Ferramentas conhecidas do mesmo tipo passam pelo
mesmo (O&O ShutUp10, Winaero Tweaker, W11Debloat).

**O que este kit faz para reduzir o atrito**, sem esconder nada de ninguém:

- **Tudo é texto legível.** Nenhum script é ofuscado, compactado ou codificado em base64,
  não há download de código em tempo de execução, nem `-EncodedCommand`. Você (ou o
  antivírus) consegue ler linha a linha o que vai acontecer.
- **`preparar.ps1` remove a "marca da web"** dos arquivos, que é o que faz o Windows avisar
  "arquivo de origem desconhecida" a cada execução.
- **O `.exe` é compilado na sua máquina**, a partir do `.cs` que acompanha o kit, usando o
  compilador do próprio Windows. Não existe binário baixado de terceiros, e por nascer
  local ele não dispara o aviso do SmartScreen.
- **`preparar.ps1 -Assinar`** cria um certificado próprio do seu PC, marca-o como confiável
  ali e assina os scripts. Passam a rodar mesmo em política `AllSigned`, e o Windows para de
  tratá-los como anônimos. O certificado não sai da sua máquina.
- **`SHA256SUMS.txt`** guarda a impressão digital de cada arquivo, para você conferir depois
  que nada foi alterado.

**Se mesmo assim o Defender bloquear**, o caminho honesto é: abra o arquivo apontado, leia o
que ele faz, e só então decida. Se decidir manter, adicione **a pasta do kit** às exclusões
em Segurança do Windows → Proteção contra vírus → Gerenciar configurações → Exclusões.
Excluir a pasta de uma ferramenta que você leu é diferente de desligar o antivírus — e o kit
nunca desliga o Defender, justamente para você continuar protegido.

O que este kit **não** faz, de propósito: não tenta driblar, silenciar ou cegar antivírus,
não desativa o Defender e não esconde processos. Se um dia precisar disso para funcionar, o
problema é o kit, não o antivírus.

## O que fica ligado de propósito (e por quê)
- **Microsoft Defender** — desligar não dá FPS mensurável e deixa o PC exposto. Se um
  jogo engasgar por causa de scan, adicione a pasta em `DefenderExclusions`.
- **Secure Boot / TPM 2.0** — Valorant (Vanguard), FACEIT, e cada vez mais anti-cheats
  exigem os dois no Windows 11. Por isso o bypass de requisitos fica comentado.
- **Windows Update** — só tiramos o reboot automático. Desligar updates é como as
  edições piratas quebram com o tempo.
- **Microsoft Store, App Installer (winget), Xbox Identity, Gaming Services** — sem eles
  não há Game Pass, Minecraft, Forza, nem `winget`.
- **Codecs (HEIF/AV1/VP9/WebP), Fotos, Calculadora, Bloco de Notas, Terminal,
  Ferramenta de Captura, Câmera, Segurança do Windows** — úteis e não pesam.

## Trade-offs que você decide
- `DisableVBS = $true` (padrão): desliga Isolamento de Núcleo / Integridade da memória.
  Ganho de FPS real em vários jogos, principalmente CPUs mais antigas; menos proteção
  contra drivers maliciosos. Para voltar: Segurança do Windows → Segurança do
  dispositivo → Isolamento de núcleo → ligar.
- `PowerPlanUltimate`: mais consumo em idle; em notebook vira menos bateria.
- `DisableHibernation`: desliga também a Inicialização Rápida (o boot fica 2 a 5 s mais
  lento, mas evita bugs de drivers/rede depois de "desligar").
- `RemoveXbox`: Game Bar fora = sem Win+G, sem captura nativa, sem Game Pass.

## Sem oscdimg (alternativa com Rufus)
1. Rode o `build-iso.ps1` mesmo assim: ele gera a pasta `C:\WinGamingBuild\iso` e avisa
   que não fez a ISO.
2. No Rufus, grave a **ISO original** no pendrive escolhendo **NTFS** como sistema de
   arquivos (o `install.wim` costuma passar de 4 GB).
3. Copie por cima, para o pendrive: `sources\install.wim` (substitui o original;
   apague `install.esd` se existir), `autounattend.xml` na raiz, e a pasta
   `sources\$OEM$` inteira.

## Problemas comuns
- **VM "Abortada" logo ao iniciar, log com `VERR_VMX_IN_VMX_ROOT_MODE` / "VT-x is being used
  by another hypervisor"** → outro hipervisor KVM está rodando e o VirtualBox precisa do
  VT-x exclusivo. Culpados comuns: a VM sandbox do **Claude Desktop** (`claude-cowork-vm`),
  GNOME Boxes, virt-manager, Docker/Podman machine, emulador Android. Confira com
  `pgrep -a qemu-system`, feche o programa (para o Claude Desktop: sair do app por completo)
  e inicie a VM de novo. Log: `~/VirtualBox VMs/Win11-Gaming/Logs/VBox.log`.
- **"Edição não encontrada"** → o script lista as edições da sua ISO; use o nome exato.
- **Instalador ignorou o autounattend** → o arquivo precisa estar na raiz da mídia com
  o nome exato `autounattend.xml`. Com ISO de outro idioma, ajuste `pt-BR`/`0416:00010416`.
- **Tela de conta Microsoft apareceu** → a conta local do XML não foi criada; confira
  se você não removeu o bloco `<UserAccounts>`.
- **O script do primeiro logon não rodou** → veja `C:\Windows\Setup\Scripts\freedom-tweaks.log`.
  Se a pasta não existir, o `$OEM$` não foi copiado (mídia gravada pelo Rufus a partir
  da pasta em vez da ISO? veja seção anterior). Rode o script manualmente.
- **Jogo com anti-cheat reclamando de VBS/HVCI** → raro, mas alguns pedem HVCI ligado;
  religue em Segurança do Windows.
- **winget não existe** → abra a Microsoft Store, atualize "Instalador de Aplicativo".

## Como reverter
Todos os ajustes são registro/serviços/tarefas: `sfc`, reinstalar apps pela Store, ou
`Set-Service X -StartupType Manual` desfaz cada item. Nada é apagado do `WinSxS`, então
o Windows Update continua capaz de reparar/atualizar tudo.
