# Servidor NFS em Docker com Limite de Espaço (2 GB)

Este projeto cria um servidor NFS rodando em container Docker baseado em Alpine Linux, exportando um diretório com limite rígido de 2 GB usando um arquivo-disco (`nfs.img`).  
Além disso, inclui um cliente NFS (container Alpine) para testes automáticos.

---

## 📂 Estrutura do projeto

```
docker-fs/
├── docker-compose.yml
├── Dockerfile
├── entrypoint.sh
└── nfs-data/
    └── nfs.img   # arquivo persistente (disco virtual limitado a 2 GB)
```

---

## ⚙️ Como funciona

- O `entrypoint.sh` cria um arquivo-disco (`nfs.img`) de 2 GB se não existir.  
- Esse arquivo é formatado em **ext4** e montado no container em `/exports/app`.  
- O container **nfs-server** exporta `/exports/app` via NFS.  
- Os dados ficam persistentes no host (`./nfs-data/nfs.img`) e nunca passam de 2 GB.  
- O container **nfs-client** monta esse export automaticamente em `/mnt/test`.  

---

## 🐳 Arquivos principais

#### entrypoint.sh

#### docker-compose.yml

#### Dockerfile

## 🚀 Como usar

### 1. Criar rede Docker (se não existir)

```bash
docker network create --driver=bridge --subnet=172.25.0.0/16 docker-fs-net
```

### 2. Preparar diretório e arquivo-disco

```bash
mkdir -p ./nfs-data
touch ./nfs-data/nfs.img
```

### 3. Build e subir os containers

```bash
docker compose up -d --build
```

### 4. Ver logs do servidor

```bash
docker logs -f nfs-server
```

Esperado:

```
[nfs-server] criando disco de 2048MB...
exporting *:/exports/app
```

### 5. Testar dentro do cliente

Entrar no container cliente:

```bash
docker exec -it nfs-client sh
```

Verificar montagem:

```sh
df -h /mnt/test
```

Testar escrita:

```sh
echo "funcionou!" > /mnt/test/hello.txt
ls -l /mnt/test
```

Tentar encher até o limite:

```sh
dd if=/dev/zero of=/mnt/test/bigfile bs=100M count=30
```

Quando atingir 2 GB:

```
dd: writing to 'bigfile': No space left on device
```

---

## ⚠️ Observações

- O container precisa de `privileged: true` para acessar módulos NFS do kernel.  
- O limite é definido pela variável `SIZE_MB` no `entrypoint.sh`.  
- Para alterar (ex.: 4 GB), basta editar:
  ```bash
  SIZE_MB=4096
  ```
- Os dados são persistidos no arquivo `./nfs-data/nfs.img`.  
