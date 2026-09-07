<#
=====================================================================================
  preparar.ps1  -  prepara o kit nesta maquina (roda UMA vez, depois nao precisa mais)
=====================================================================================
  Faz tres coisas, todas para reduzir atrito com Windows/antivirus:

   1. DESBLOQUEIA os arquivos. Tudo que vem da internet ganha a "marca da web" e o
      Windows passa a avisar que o arquivo nao e confiavel. Isto remove essa marca
      dos arquivos DESTE kit.

   2. COMPILA o CleanWindows.exe a partir do CleanWindowsLauncher.cs, usando o
      compilador C# que ja vem no Windows (csc.exe do .NET Framework). Nenhum binario
      e baixado: o executavel nasce aqui, do texto que voce pode ler. Por ser criado
      localmente, ele nao carrega marca da web e nao dispara o aviso do SmartScreen.

   3. ASSINA os scripts .ps1 com um certificado proprio desta maquina (opcional,
      -Assinar). Isso identifica os scripts como seus e permite rodar mesmo com
      politica AllSigned. O certificado fica so no seu PC.

  Uso:  powershell -ep bypass -f preparar.ps1  [-Assinar]  [-SemExe]
=====================================================================================
#>
[CmdletBinding()]
param(
    [switch]$Assinar,     # cria um certificado proprio e assina os .ps1
    [switch]$SemExe       # nao compila o CleanWindows.exe
)

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $a = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"")
    if ($Assinar) { $a += '-Assinar' }
    if ($SemExe)  { $a += '-SemExe' }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $a
    exit
}

$ErrorActionPreference = 'Continue'
$Dir = Split-Path -Parent $MyInvocation.MyCommand.Path
function Passo($m) { Write-Host "`n==> $m" -ForegroundColor Cyan }
function Ok($m)    { Write-Host "    $m" -ForegroundColor Green }
function Aviso($m) { Write-Host "    $m" -ForegroundColor Yellow }

# ---------------------------------------------------------------- 1. marca da web
Passo 'Removendo a marca da web dos arquivos do kit'
$n = 0
Get-ChildItem -LiteralPath $Dir -File | ForEach-Object {
    try { Unblock-File -LiteralPath $_.FullName -ErrorAction Stop; $n++ } catch {}
}
Ok "$n arquivos desbloqueados"

# ---------------------------------------------------------------- 2. CleanWindows.exe
if (-not $SemExe) {
    Passo 'Compilando o CleanWindows.exe (compilador do proprio Windows)'
    $csc = @(
        "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
        "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $csc) {
        Aviso 'csc.exe nao encontrado (.NET Framework 4 ausente). Use o clean-windows.cmd.'
    } else {
        $src  = Join-Path $Dir 'CleanWindowsLauncher.cs'
        $man  = Join-Path $Dir 'CleanWindows.manifest'
        $ico  = Join-Path $Dir 'CleanWindows.ico'
        $exe  = Join-Path $Dir 'CleanWindows.exe'
        if (-not (Test-Path $src)) {
            Aviso 'CleanWindowsLauncher.cs nao encontrado'
        } else {
            Remove-Item $exe -Force -ErrorAction SilentlyContinue
            # $args e variavel reservada do PowerShell: usar outro nome.
            # E aqui NAO se coloca aspas dentro do texto: o PowerShell ja passa cada item
            # como um argumento unico, e aspas literais quebrariam o csc.
            $cscArgs = @('/nologo', '/target:winexe', '/optimize+', "/out:$exe",
                         '/reference:System.Windows.Forms.dll', '/reference:System.dll')
            if (Test-Path $man) { $cscArgs += "/win32manifest:$man" }
            if (Test-Path $ico) { $cscArgs += "/win32icon:$ico" }
            $cscArgs += $src
            $out = & $csc @cscArgs 2>&1
            if (Test-Path $exe) {
                Unblock-File -LiteralPath $exe -ErrorAction SilentlyContinue
                Ok "CleanWindows.exe criado ($([math]::Round((Get-Item $exe).Length / 1KB)) KB)"
                Ok 'Use ele para abrir o Clean Windows: sem janela preta, uma unica permissao.'
            } else {
                Aviso "falhou: $($out -join ' ')"
            }
        }
    }
}

# ---------------------------------------------------------------- 3. assinatura
if ($Assinar) {
    Passo 'Assinando os scripts com um certificado desta maquina'
    try {
        $nome = 'Clean Windows (local)'
        $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert -ErrorAction SilentlyContinue |
                    Where-Object { $_.Subject -eq "CN=$nome" } | Select-Object -First 1
        if (-not $cert) {
            $cert = New-SelfSignedCertificate -Subject "CN=$nome" -Type CodeSigningCert `
                        -CertStoreLocation Cert:\CurrentUser\My -NotAfter (Get-Date).AddYears(10) -ErrorAction Stop
            $tmp = Join-Path $env:TEMP 'cleanwindows-cert.cer'
            Export-Certificate -Cert $cert -FilePath $tmp -Force | Out-Null
            Import-Certificate -FilePath $tmp -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
            Import-Certificate -FilePath $tmp -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
            Ok 'certificado criado e marcado como confiavel nesta maquina'
        } else { Ok 'certificado ja existia' }

        $k = 0
        Get-ChildItem -LiteralPath $Dir -Filter *.ps1 | ForEach-Object {
            $r = Set-AuthenticodeSignature -FilePath $_.FullName -Certificate $cert -ErrorAction SilentlyContinue
            if ($r.Status -eq 'Valid') { $k++ }
        }
        Ok "$k scripts assinados"
        if (Test-Path (Join-Path $Dir 'CleanWindows.exe')) {
            Set-AuthenticodeSignature -FilePath (Join-Path $Dir 'CleanWindows.exe') -Certificate $cert -ErrorAction SilentlyContinue | Out-Null
            Ok 'CleanWindows.exe assinado'
        }
    } catch { Aviso "assinatura falhou: $($_.Exception.Message)" }
}

# ---------------------------------------------------------------- resumo
Passo 'Impressoes digitais (SHA-256) dos arquivos'
$sums = Join-Path $Dir 'SHA256SUMS.txt'
Get-ChildItem -LiteralPath $Dir -File | Where-Object { $_.Name -ne 'SHA256SUMS.txt' } |
    ForEach-Object { "{0}  {1}" -f (Get-FileHash $_.FullName -Algorithm SHA256).Hash, $_.Name } |
    Set-Content -Path $sums -Encoding UTF8
Ok "gravadas em SHA256SUMS.txt"

Write-Host @"

Pronto.
  - Abra o kit pelo CleanWindows.exe (sem janela preta).
  - Se o antivirus reclamar de algum script, leia o arquivo: e texto puro, sem nada
    escondido. Veja a secao "Antivirus" do README.
"@ -ForegroundColor Green
