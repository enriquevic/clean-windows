// =====================================================================================
//  CleanWindowsLauncher.cs  -  origem do CleanWindows.exe
// =====================================================================================
//  Programa minusculo, sem console, cuja unica funcao e abrir o menu do Clean Windows
//  (clean-windows.ps1) sem mostrar janela preta. E compilado NA SUA MAQUINA pelo
//  compilador C# que ja vem no Windows (csc.exe do .NET Framework), entao nao existe
//  binario baixado de terceiros: o que roda vem deste texto, que voce pode ler.
//
//  O manifesto embutido pede privilegio de administrador, entao o Windows mostra UMA
//  janela de permissao no nome do proprio CleanWindows, e nada mais aparece depois.
// =====================================================================================
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

static class CleanWindowsLauncher
{
    [STAThread]
    static void Main(string[] args)
    {
        string dir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
        string ps1 = Path.Combine(dir, "clean-windows.ps1");

        if (!File.Exists(ps1))
        {
            MessageBox.Show(
                "Nao encontrei o clean-windows.ps1 nesta pasta:\n\n" + dir +
                "\n\nMantenha o CleanWindows.exe junto com os arquivos do kit.",
                "Clean Windows", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }

        string extra = (args.Length > 0) ? " " + string.Join(" ", args) : "";
        var psi = new ProcessStartInfo("powershell.exe",
            "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File \"" + ps1 + "\"" + extra);
        psi.UseShellExecute = false;
        psi.CreateNoWindow = true;
        psi.WorkingDirectory = dir;

        try { Process.Start(psi); }
        catch (Exception e)
        {
            MessageBox.Show("Nao consegui iniciar o menu:\n\n" + e.Message,
                "Clean Windows", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
