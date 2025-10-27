
#           PREPARANDO DIRETÓRIOS DE FONTES 


# Cria diretório para armazenar fontes (source code)
sudo mkdir -v $LFS/sources

# Define permissões para o diretório de fontes (leitura/escrita para todos)
sudo chmod -v a+wt $LFS/sources

# Navega para o diretório de fontes
cd $LFS/sources/


#           BAIXANDO FONTES


# Baixa lista de pacotes necessários
wget https://www.linuxfromscratch.org/lfs/view/stable/wget-list-sysv

# Baixa todos os pacotes listados (com continuação de downloads parciais)
wget --input-file=wget-list-sysv --continue