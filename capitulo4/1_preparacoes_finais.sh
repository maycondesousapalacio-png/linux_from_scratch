
#           CRIANDO ESTRUTURA DE DIRETÓRIOS LFS 


# Cria diretórios essenciais no sistema LFS
sudo mkdir -pv etc var
sudo mkdir -pv usr/

# Cria subdiretórios dentro de usr/
sudo mkdir -pv bin/
sudo mkdir -pv lib/
sudo mkdir -pv sbin/

# Cria links simbólicos para manter compatibilidade
sudo -i
for i in bin lib sbin; do
    ln -sv usr/$i $LFS/$i
done
# Resultado esperado:
# '/mnt/lfs/bin' -> 'usr/bin'
# '/mnt/lfs/lib' -> 'usr/lib'  
# '/mnt/lfs/sbin' -> 'usr/sbin'
exit

# Cria diretório para bibliotecas 64-bit
sudo mkdir -pv $LFS/lib64

# Cria diretório para ferramentas temporárias
sudo mkdir -pv tools


#           CRIANDO USUÁRIO LFS


# Entra como superusuário
sudo -i

# Cria grupo lfs
groupadd lfs

# Cria usuário lfs com bash como shell padrão
useradd -s /bin/bash -g lfs -m -k /dev/null lfs

# Define senha para o usuário lfs
passwd lfs  # senha: Pitbulls

# Define proprietário dos diretórios LFS para o usuário lfs
chown -v lfs $LFS/usr
chown -v lfs $LFS/lib
chown -v lfs $LFS/lib64
chown -v lfs $LFS/bin
chown -v lfs $LFS/sbin
chown -v lfs $LFS/tools
chown -v lfs $LFS/etc
chown -v lfs $LFS/var


#           CONFIGURANDO AMBIENTE DO USUÁRIO 


# Muda para usuário lfs
su - lfs

# Cria arquivo de perfil bash para ambiente limpo
cat > /home/lfs/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

# Configura variáveis de ambiente específicas para LFS
cat > ~/.bashrc << "EOF"
set +h  # Desabilita cache de comandos
umask 022  # Define máscara de permissões padrão
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu  # Define target para cross-compilation
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH  # Adiciona ferramentas LFS ao PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOF

exit  # Volta para root


#           PREPARANDO AMBIENTE DE BUILD LIMPO


# Renomeia bash.bashrc do sistema para evitar interferências
sudo mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE

# Verifica se a renomeação foi bem sucedida
ls -la /etc/bash.bashrc*