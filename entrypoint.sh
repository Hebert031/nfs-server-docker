#!/bin/bash
set -eu

SIZE_MB=2048   # tamanho em MB (2GB)
DISK_IMG=/nfs.img
MOUNT_DIR=/exports/app

# cria disco se não existir ou estiver vazio
if [ ! -s "$DISK_IMG" ]; then
  echo "[nfs-server] criando disco de ${SIZE_MB}MB..."
  dd if=/dev/zero of=$DISK_IMG bs=1M count=$SIZE_MB
  mkfs.ext4 -q $DISK_IMG
fi

mkdir -p $MOUNT_DIR
mount -o loop $DISK_IMG $MOUNT_DIR

echo "$MOUNT_DIR *(rw,sync,no_subtree_check,no_root_squash)" > /etc/exports
exportfs -rv

echo "[nfs-server] iniciando serviços..."
rpcbind -w
rpc.nfsd
exec rpc.mountd -F
