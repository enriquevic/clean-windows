#!/usr/bin/env bash
# =====================================================================================
#  usb-ventoy.sh - prepara o pendrive Ventoy para instalar no PC real (Linux/macOS)
#
#  Pre-requisito: pendrive ja formatado com o Ventoy (https://www.ventoy.net) e montado.
#  O script copia para a raiz da particao Ventoy:
#      - a ISO oficial do Windows
#      - autounattend.xml, Scripts\ e $OEM$\ (mesmo conteudo do kit.iso)
#      - ventoy/ventoy.json com o plugin auto_install apontando para o autounattend.xml
#
#  Uso:  ./usb-ventoy.sh /media/$USER/Ventoy [caminho/da/ISO] [--oem-key]
#
#  --oem-key  remove o bloco <ProductKey> do autounattend.xml copiado. Use em PC de marca
#             (Acer, Dell, Lenovo...) que veio com Windows: a chave esta gravada na placa
#             (tabela ACPI MSDM) e o instalador a le sozinho, escolhendo a edicao certa
#             (Home/Pro) para a licenca digital ativar. No Linux, confira com:
#                 ls /sys/firmware/acpi/tables/MSDM
# =====================================================================================
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST=""; ISO="$HOME/Downloads/Win11_25H2_BrazilianPortuguese_x64_v2.iso"; OEMKEY=0
for a in "$@"; do
    case "$a" in
        --oem-key) OEMKEY=1 ;;
        *.iso|*.ISO) ISO="$a" ;;
        *) DEST="$a" ;;
    esac
done
[ -n "$DEST" ] || { echo "uso: $0 /ponto/de/montagem/do/Ventoy [ISO] [--oem-key]"; exit 1; }
[ -d "$DEST" ] && [ -w "$DEST" ] || { echo "pasta nao existe ou sem permissao de escrita: $DEST"; exit 1; }
[ -f "$ISO" ] || { echo "ISO nao encontrada: $ISO"; exit 1; }
[ -d "$DEST/ventoy" ] || [ -f "$DEST/../VTOYEFI" ] || echo "AVISO: $DEST nao parece uma particao Ventoy (sem pasta ventoy/). Continuando mesmo assim."
for f in autounattend.xml freedom-tweaks.ps1 freedom-watch.ps1 apps.ps1 verify.ps1; do [ -f "$HERE/$f" ] || { echo "falta $f ao lado do script"; exit 1; }; done

ISONAME="$(basename "$ISO")"
echo "==> ISO: $ISONAME"
if [ -f "$DEST/$ISONAME" ] && [ "$(stat -c %s "$DEST/$ISONAME")" = "$(stat -c %s "$ISO")" ]; then
    echo "    ja esta no pendrive (mesmo tamanho), pulando copia"
else
    echo "    copiando $(du -h "$ISO" | cut -f1)... (varios minutos)"
    cp "$ISO" "$DEST/$ISONAME"
fi

echo "==> Kit (autounattend.xml, Scripts, \$OEM\$)"
mkdir -p "$DEST/Scripts" "$DEST/\$OEM\$/\$\$/Setup/Scripts" "$DEST/ventoy"
for f in freedom-tweaks.ps1 freedom-watch.ps1 apps.ps1 verify.ps1; do
    cp "$HERE/$f" "$DEST/Scripts/$f"
    cp "$HERE/$f" "$DEST/\$OEM\$/\$\$/Setup/Scripts/$f"
done
if [ "$OEMKEY" = 1 ]; then
    python3 - "$HERE/autounattend.xml" "$DEST/autounattend.xml" <<'PY'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
s = open(src, encoding='utf-8').read()
s2 = re.sub(r'\n[ \t]*<ProductKey>.*?</ProductKey>', '', s, count=1, flags=re.S)
open(dst, 'w', encoding='utf-8').write(s2)
print("    <ProductKey> removido: o instalador vai usar a chave OEM da placa" if s2 != s else "    (bloco <ProductKey> nao encontrado; nada alterado)")
PY
else
    cp "$HERE/autounattend.xml" "$DEST/autounattend.xml"
fi

echo "==> ventoy/ventoy.json (plugin auto_install)"
if [ -f "$DEST/ventoy/ventoy.json" ]; then
    cp "$DEST/ventoy/ventoy.json" "$DEST/ventoy/ventoy.json.bak"
    echo "    ja existia; backup em ventoy.json.bak"
fi
cat > "$DEST/ventoy/ventoy.json" <<JSON
{
    "auto_install": [
        {
            "image": "/$ISONAME",
            "template": "/autounattend.xml",
            "autosel": 1,
            "timeout": 5
        }
    ]
}
JSON
sync
echo
echo "Pronto. Conteudo do pendrive:"
ls -1 "$DEST" | sed 's/^/    /'
echo
echo "Desmonte com seguranca antes de tirar (ou: udisksctl unmount -b /dev/sdXN)."
