#!/usr/bin/env bash
# =====================================================================================
#  vbox-test-pendrive.sh - testa o "pendrive" criado pelo criar-pendrive.ps1 dentro da VM
#
#  Cria a VM "Win11-Pendrive-Teste" (EFI, TPM 2.0, Secure Boot) que da boot pelo disco
#  virtual pendrive-teste.vdi (o "pendrive") e instala num segundo disco vazio de 64 GB.
#  Antes: desligue a Win11-Gaming (o .vdi nao pode estar em uso por duas VMs ao mesmo tempo).
#
#  Uso:      ./vbox-test-pendrive.sh
#  Remover:  VBoxManage unregistervm Win11-Pendrive-Teste --delete
# =====================================================================================
set -euo pipefail
VM="Win11-Pendrive-Teste"; SRC_VM="Win11-Gaming"
VMDIR="$(VBoxManage list systemproperties | sed -n 's/^Default machine folder: *//p')"
PEN="$VMDIR/$SRC_VM/pendrive-teste.vdi"
[ -f "$PEN" ] || { echo "nao achei $PEN (crie o disco de teste primeiro)"; exit 1; }
if VBoxManage showvminfo "$VM" >/dev/null 2>&1; then
    echo "A VM '$VM' ja existe. Apague com: VBoxManage unregistervm \"$VM\" --delete"; exit 1
fi
S=$(VBoxManage showvminfo "$SRC_VM" --machinereadable | sed -n 's/^VMState="\(.*\)"/\1/p')
[ "$S" = "poweroff" ] || { echo "Desligue a $SRC_VM primeiro (estado: $S)"; exit 1; }

echo "==> Soltando o pendrive-teste.vdi da $SRC_VM (porta SATA 3)"
VBoxManage storageattach "$SRC_VM" --storagectl SATA --port 3 --device 0 --type hdd --medium none

echo "==> Criando $VM"
VBoxManage createvm --name "$VM" --ostype Windows11_64 --register >/dev/null
VBoxManage modifyvm "$VM" --memory 6144 --cpus 4 --firmware efi --tpm-type 2.0 \
    --graphicscontroller vboxsvga --vram 128 --accelerate-3d on --nic1 nat \
    --audio-enabled off --usb-xhci on --mouse usbtablet --nested-paging on
VBoxManage modifynvram "$VM" inituefivarstore
VBoxManage modifynvram "$VM" enrollmssignatures
VBoxManage modifynvram "$VM" enrollorclpk
VBoxManage modifynvram "$VM" secureboot --enable
VBoxManage createmedium disk --filename "$VMDIR/$VM/$VM.vdi" --size 65536 --format VDI >/dev/null
VBoxManage storagectl "$VM" --name SATA --add sata --controller IntelAhci --portcount 2 --bootable on
VBoxManage storageattach "$VM" --storagectl SATA --port 0 --device 0 --type hdd --medium "$PEN"
VBoxManage storageattach "$VM" --storagectl SATA --port 1 --device 0 --type hdd --medium "$VMDIR/$VM/$VM.vdi" --nonrotational on
echo
echo "VM '$VM' criada: porta 0 = pendrive-teste.vdi (boot), porta 1 = disco vazio de 64 GB."
echo "Inicie com:  VBoxManage startvm \"$VM\""
echo "Se subir o instalador do Windows direto na tela de disco, o pendrive esta aprovado."
