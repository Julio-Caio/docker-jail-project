#!/bin/bash

# Autor: Júlio Caio
# Data: 14/10/2025
# 
# nome: create-jail.sh
# uso: ./create-jail.sh
#
# Version Atual: 1.0.0
#
# Instituição: IFPB
# Disciplina: Virtualização
#
# Objetivo: script para criar diretórios dos binários essenciais 
#  \ para o funcionamento de um \
#  \  container jail
#
# ! Atenção: o arquivo "./dependecies-ldd.txt" deve estar no mesmo diretório
# ! Obs.: Use root!
# 
#################################
#	VARIABLES		#
#################################

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Sem cor

G_CURRENT_DIR="$HOME/jail"
G_DIRS=("bin" "lib/x86_64-linux-gnu" "lib64" "dev" "etc" "home" "usr/bin" "proc")
G_BINS=("bash" "ping" "ls" "ip" "whoami" "clear" "cat" "ps")
G_DEPENDENCIES_LIST_F="./dependencies.txt"
G_REGEX="/lib(64)?/[^ ]+\.so(\.\d+)*"

##################################
# 	FUNCTIONS		 #
##################################
ask_yes_no() {
    while true; do
        read -p "$1 [Y/n]: " yn
        case $yn in
            [Yy]* | "" ) return 0 ;;
            [Nn]* ) return 1 ;;
            * ) echo -e "${YELLOW}Por favor, digite Y ou N.${NC}" ;;
        esac
    done
}

echo -e "${CYAN}[+] Criando estrutura de diretórios em $G_CURRENT_DIR${NC}\n"
sleep 2
for dir in "${G_DIRS[@]}"; do
    TARGET="$G_CURRENT_DIR/$dir"
    if [ -d "$TARGET" ]; then
        echo -e "${YELLOW}[-] Diretório $TARGET já existe, pulando...${NC}"
    else
        echo -e "${GREEN}[+] Criando $TARGET...${NC}"
        mkdir -p "$TARGET"
    fi
done

echo -e "\n${CYAN}[+] Binários que serão copiados para a jail:${NC}"
sleep 1
for i in "${!G_BINS[@]}"; do
    echo -e "   ${i}. ${G_BINS[$i]}"
done

if ! ask_yes_no "Deseja prosseguir com a cópia dos binários?"; then
    echo -e "${RED}[!] Operação cancelada pelo usuário.${NC}"
    exit 1
fi

echo -e "\n${CYAN}[+] Copiando binários...${NC}"
sleep 2
for bin in "${G_BINS[@]}"; do
    temp=$(command -v "$bin")
    if [ -z "$temp" ]; then
        echo -e "${RED}[x] Binário '$bin' não encontrado no PATH, pulando.${NC}"
        continue
    fi
    echo -e "${GREEN}[+] Copiando $temp → $G_CURRENT_DIR/bin/${NC}"
    sudo cp -v "$temp" "$G_CURRENT_DIR/bin/"
    sleep 1
done

echo -e "\n${CYAN}[+] Copiando dependências...${NC}"
sleep 2

sort -u "$G_DEPENDENCIES_LIST_F" | while read -r dep; do
    if [ -f "$dep" ]; then
        target_dir="$G_CURRENT_DIR$(dirname "$dep")"
        sudo mkdir -p "$target_dir"
        sudo cp -v --dereference "$dep" "$target_dir/"
	sleep 1
    else
        echo -e "${RED}[!] Dependência não encontrada: $dep${NC}"
    fi
done

echo -e "\n${CYAN}[+] Criando dispositivos básicos...${NC}"
sleep 2

if [ ! -e "$G_CURRENT_DIR/dev/null" ]; then
	mknod -m 666 "$G_CURRENT_DIR/dev/null" c 1 3
	echo -e "${GREEN}[✔] Dispositivos /dev/null criado.${NC}"
fi


if [ ! -e "$G_CURRENT_DIR/dev/null" ]; then
	mknod -m 666 "$G_CURRENT_DIR/dev/null" c 1 3
	echo -e "${GREEN}[✔] Dispositivos /dev/null.${NC}"
fi

echo -e "\n${CYAN}[+] Copiando arquivos de configuração...${NC}"
sleep 2
sudo cp /etc/passwd "$G_CURRENT_DIR/etc/"
sudo cp /etc/group "$G_CURRENT_DIR/etc/"

echo -e "\n${GREEN}[✔] Estrutura básica da jail criada com sucesso!${NC}"
sleep 2
echo -e "${CYAN}[*] Para entrar nela, execute:${NC}"
echo -e "    sudo chroot \"$G_CURRENT_DIR\" /bin/bash"
