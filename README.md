# Servidor NFS em Docker com Limite de Espaço (2 GB)

[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-hebertribeiro31%2Fnfs--server-blue?logo=docker)](https://hub.docker.com/r/hebertribeiro31/nfs-server)

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

---

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

### 3. Build e subir os containers (modo local)

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

## 🐳 Usando a imagem publicada no Docker Hub

Se você não quiser buildar localmente, pode usar diretamente a imagem já disponível:

```
image: hebertribeiro31/nfs-server:latest
```

Exemplo no `docker-compose.yml`:

```yaml
services:
  nfs-server:
    image: hebertribeiro31/nfs-server:latest
    container_name: nfs-server
    restart: unless-stopped
    privileged: true
    networks:
      docker-fs-net:
        ipv4_address: 172.25.0.50
    volumes:
      - ./nfs-data/nfs.img:/nfs.img

  nfs-client:
    image: alpine:3.20
    container_name: nfs-client
    command: sh -c "apk add --no-cache nfs-utils && mkdir -p /mnt/test && mount -t nfs -o vers=3,nolock 172.25.0.50:/exports/app /mnt/test && tail -f /dev/null"
    privileged: true
    depends_on:
      - nfs-server
    networks:
      docker-fs-net:
        ipv4_address: 172.25.0.60

networks:
  docker-fs-net:
    external: true
```

📌 Dessa forma, o Docker vai puxar a imagem `hebertribeiro31/nfs-server:latest` direto do Docker Hub, sem necessidade de build local.

---

## ⚠️ Observações

- O container precisa de `privileged: true` para acessar módulos NFS do kernel.  
- O limite é definido pela variável `SIZE_MB` no `entrypoint.sh`.  
- Para alterar (ex.: 4 GB), basta editar:
  ```bash
  SIZE_MB=4096
  ```
- Os dados são persistidos no arquivo `./nfs-data/nfs.img`.  
