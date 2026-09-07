#!/usr/bin/env python3
r"""
make-kit-iso.py - gera kit.iso (Linux/macOS/Windows), um "segundo DVD" com:
    /autounattend.xml                       -> o instalador do Windows encontra sozinho
    /$OEM$/$$/Setup/Scripts/*.ps1           -> copiado para C:\Windows\Setup\Scripts
    /Scripts/*.ps1                          -> fallback usado pelo FirstLogonCommands
    /README.md

Serve para testar no VirtualBox (ou instalar num PC real) SEM precisar do build-iso.ps1:
basta dar boot pela ISO oficial da Microsoft com o kit.iso no segundo drive de DVD.
A remocao dos apps pre-instalados acontece online, no primeiro logon (freedom-tweaks.ps1).

Requer a biblioteca pycdlib (pura Python):  pip install pycdlib
   ou, sem pip: baixe o .whl em https://pypi.org/project/pycdlib/#files, extraia (e um zip)
   e aponte PYTHONPATH para a pasta extraida.

Uso:  python3 make-kit-iso.py [saida.iso]
"""
import os
import sys

try:
    import pycdlib
except ImportError:
    sys.exit("pycdlib nao encontrado. Instale com: pip install pycdlib")

KIT = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(KIT, "kit.iso")
SCRIPTS = {"freedom-tweaks.ps1": "FREEDOM.PS1", "apps.ps1": "APPS.PS1",
           "verify.ps1": "VERIFY.PS1", "freedom-watch.ps1": "FREEWTCH.PS1"}

for f in ["autounattend.xml", "README.md", *SCRIPTS]:
    if not os.path.exists(os.path.join(KIT, f)):
        sys.exit(f"arquivo do kit nao encontrado: {f}")

iso = pycdlib.PyCdlib()
# ISO9660 nivel 1 (nomes 8.3) + Joliet (nomes longos, com $, usados pelo Windows)
iso.new(interchange_level=1, joliet=3, vol_ident="CLEANWINDOWS")

def add_dir(iso_path, joliet_path):
    iso.add_directory(iso_path, joliet_path=joliet_path)

def add_file(src, iso_path, joliet_path):
    iso.add_file(src, iso_path, joliet_path=joliet_path)

add_file(os.path.join(KIT, "autounattend.xml"), "/AUTOUNAT.XML;1", "/autounattend.xml")
add_file(os.path.join(KIT, "README.md"), "/README.MD;1", "/README.md")

add_dir("/OEM", "/$OEM$")
add_dir("/OEM/SS", "/$OEM$/$$")
add_dir("/OEM/SS/SETUP", "/$OEM$/$$/Setup")
add_dir("/OEM/SS/SETUP/SCRIPTS", "/$OEM$/$$/Setup/Scripts")
add_dir("/SCRIPTS", "/Scripts")

for name, short in SCRIPTS.items():
    src = os.path.join(KIT, name)
    add_file(src, f"/OEM/SS/SETUP/SCRIPTS/{short};1", f"/$OEM$/$$/Setup/Scripts/{name}")
    add_file(src, f"/SCRIPTS/{short};1", f"/Scripts/{name}")

# /Scripts vira o kit completo para uso dentro do Windows (criar-pendrive, build-iso...)
EXTRA = {"autounattend.xml": "AUTOUNAT.XML", "criar-pendrive.ps1": "CRIARPEN.PS1",
         "criar-pendrive.cmd": "CRIARPEN.CMD", "build-iso.ps1": "BUILDISO.PS1",
         "clean-windows.ps1": "CLEANWIN.PS1", "clean-windows.cmd": "CLEANWIN.CMD",
         "preparar.ps1": "PREPARAR.PS1",
         "preparar.cmd": "PREPARAR.CMD", "CleanWindowsLauncher.cs": "LAUNCHER.CS",
         "CleanWindows.manifest": "CLEANWIN.MAN", "CleanWindows.ico": "CLEANWIN.ICO"}
for name, short in EXTRA.items():
    src = os.path.join(KIT, name)
    if os.path.exists(src):
        add_file(src, f"/SCRIPTS/{short};1", f"/Scripts/{name}")

iso.write(OUT)
iso.close()
print(f"kit.iso gerado: {OUT} ({os.path.getsize(OUT) // 1024} KB)")
