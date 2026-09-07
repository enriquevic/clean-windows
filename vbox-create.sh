#!/usr/bin/env bash
# =====================================================================================
#  vbox-create.sh - cria a VM "Win11-Gaming" no VirtualBox 7.x (Linux/macOS) pronta para
#  o Windows 11: EFI, TPM 2.0, Secure Boot, disco 80 GB, DVD 1 = ISO oficial,
#  DVD 2 = kit.iso (autounattend + scripts). Nao inicia a VM.
#
#  Uso:  ./vbox-create.sh [ISO_do_Windows] [kit.iso]
#  Variaveis opcionais: VM=nome RAM=MB CPUS=n DISK_MB=MB
#  Remover depois:      VBoxManage unregistervm "Win11-Gaming" --delete
# =====================================================================================
set -euo pipefail

VM="${VM:-Win11-Gaming}"
RAM="${RAM:-8192}"
CPUS="${CPUS:-4}"
DISK_MB="${DISK_MB:-81920}"
HERE="$(cd "$(dirname "$0")" && pwd)"
WIN_ISO="${1:-$HOME/Downloads/Win11_25H2_BrazilianPortuguese_x64_v2.iso}"
KIT_ISO="${2:-$HERE/kit.iso}"

[ -f "$WIN_ISO" ] || { echo "ISO do Windows nao encontrada: $WIN_ISO"; exit 1; }
[ -f "$KIT_ISO" ] || { echo "kit.iso nao encontrado: $KIT_ISO (gere com: python3 make-kit-iso.py)"; exit 1; }
command -v VBoxManage >/dev/null || { echo "VBoxManage nao encontrado (instale o VirtualBox)"; exit 1; }
if VBoxManage showvminfo "$VM" >/dev/null 2>&1; then
    echo "A VM '$VM' ja existe. Apague com:  VBoxManage unregistervm \"$VM\" --delete"; exit 1
fi

VMDIR="$(VBoxManage list systemproperties | sed -n 's/^Default machine folder: *//p')"
DISK="$VMDIR/$VM/$VM.vdi"

echo "==> Criando VM $VM ($RAM MB RAM, $CPUS CPUs, disco $((DISK_MB/1024)) GB)"
VBoxManage createvm --name "$VM" --ostype Windows11_64 --register >/dev/null

VBoxManage modifyvm "$VM" \
    --memory "$RAM" --cpus "$CPUS" \
    --firmware efi --tpm-type 2.0 \
    --graphicscontroller vboxsvga --vram 256 --accelerate-3d on \
    --nic1 nat \
    --audio-enabled on --audio-driver default --audio-controller hda --audio-out on \
    --usb-xhci on --mouse usbtablet \
    --clipboard-mode bidirectional --drag-and-drop bidirectional \
    --nested-paging on

echo "==> Secure Boot: inicializando NVRAM e registrando as chaves da Microsoft"
VBoxManage modifynvram "$VM" inituefivarstore
VBoxManage modifynvram "$VM" enrollmssignatures
VBoxManage modifynvram "$VM" enrollorclpk
VBoxManage modifynvram "$VM" secureboot --enable

echo "==> Disco e DVDs"
VBoxManage createmedium disk --filename "$DISK" --size "$DISK_MB" --format VDI >/dev/null
VBoxManage storagectl "$VM" --name SATA --add sata --controller IntelAhci --portcount 4 --bootable on
VBoxManage storageattach "$VM" --storagectl SATA --port 0 --device 0 --type hdd --medium "$DISK" --nonrotational on
VBoxManage storageattach "$VM" --storagectl SATA --port 1 --device 0 --type dvddrive --medium "$WIN_ISO"
VBoxManage storageattach "$VM" --storagectl SATA --port 2 --device 0 --type dvddrive --medium "$KIT_ISO"

cat <<MSG

VM '$VM' criada.
  Iniciar:  VBoxManage startvm "$VM"   (ou pelo VirtualBox)
  Assim que aparecer "Press any key to boot from CD or DVD", aperte uma tecla.
  Se perder o momento e cair no shell EFI, digite  exit  e escolha o DVD no Boot Manager.
MSG
