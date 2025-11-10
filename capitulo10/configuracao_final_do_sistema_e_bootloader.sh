
#                   Tornando o Sistema LFS Inicializável




#           Configuração do Fstab


# Configura o arquivo de sistemas de arquivos para montagem automática
cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point    type     options             dump  fsck
#                                                                order

/dev/sda3      /              ext4     defaults            1     1
/dev/sda4      swap           swap     pri=1               0     0
proc           /proc          proc     nosuid,noexec,nodev 0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs          /run           tmpfs    defaults            0     0
devtmpfs       /dev           devtmpfs mode=0755,nosuid    0     0
tmpfs          /dev/shm       tmpfs    nosuid,nodev        0     0
cgroup2        /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0     0

# End /etc/fstab
EOF


#           Compilação do Kernel Linux


cd sources
# Extrai o código fonte do kernel
tar xvf linux-6.16.1.tar.xz 
cd linux-6.16.1/

# Limpa o código fonte
make mrproper

# Configuração interativa do kernel
make menuconfig     # ocorreram 2 erros aqui por causa do tamanho do terminal, é necessário ter pelo menos 19 linhas e 80 colunas

# Verificando o tamanho atual do terminal
stty size

# Foi feito o redimensionamento da tela para tela cheia
# Aqui foram feitas algumas configurações importantes, é necessário olhar o livro
make menuconfig     

# Compila o kernel (usando 1 job para evitar problemas)
make -j1

# Instala os módulos do kernel
make modules_install


#           Instalação do Kernel


# Copia o kernel compilado para o diretório /boot
cp -iv arch/x86_64/boot/bzImage /boot/vmlinuz-6.16.1-lfs-12.4

# Copia o System.map e configuração do kernel
cp -iv System.map /boot/System.map-6.16.1
cp -iv .config /boot/config-6.16.1

# Instala a documentação do kernel
cp -r Documentation -T /usr/share/doc/linux-6.16.1


#           Configuração de Módulos do Kernel


# Cria diretório para configurações de módulos
install -v -m755 -d /etc/modprobe.d

# Configura módulos USB para compatibilidade
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF


#            Configuração do GRUB (Primeira Tentativa)


cd ../..    # voltando para o diretório raiz

# Cria diretório do GRUB
mkdir -p /boot/grub

# Configuração inicial do GRUB
cat > /boot/grub/grub.cfg << "EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod part_gpt
insmod ext2
set root=(hd0,3)
set gfxpayload=1024x768x32

menuentry "GNU/Linux, Linux 6.16.1-lfs-12.4" {
        linux   /boot/vmlinuz-6.16.1-lfs-12.4 root=/dev/sda3 ro
}
EOF       # FÉ 🍀

# Verifica a configuração do GRUB
ls -la /boot/grub/grub.cfg
cat /boot/grub/grub.cfg


#           Problemas com a Instalação do GRUB e Solução


# Tentativa inicial de instalar o GRUB (não funcionou)
grub-install /dev/sda

# EXPLICAÇÃO DO PROBLEMA:
# O sistema tem UEFI, mas o LFS foi compilado para BIOS (i386-pc)
# O GRUB padrão tenta instalar para x86_64-efi (UEFI)
# Mas os arquivos do GRUB são para i386-pc (BIOS legacy)

# Segunda tentativa com target específico
grub-install --target i386-pc /dev/sda

# OUTRO PROBLEMA IDENTIFICADO:
# Problema identificado! O disco está com GPT e precisa de uma BIOS Boot Partition para o GRUB BIOS.

# SOLUÇÃO: Configurar o GRUB do sistema host (Ubuntu) para detectar o LFS
exit    # Saindo do chroot do LFS para voltar ao sistema host


#            Configuração no Sistema Host (Ubuntu)


# Edita a configuração padrão do GRUB no sistema host
sudo nano /etc/default/grub

# Alterações feitas:
# GRUB_DISABLE_OS_PROBER=false (foi alterado de comentado para ativo)
GRUB_DISABLE_OS_PROBER=false
GRUB_TIMEOUT=10
GRUB_TIMEOUT_STYLE=menu

# Atualiza o GRUB com as novas configurações
sudo update-grub

# Cria entrada customizada para o LFS
sudo nano /etc/grub.d/40_custom

# Conteúdo adicionado:
#!/bin/sh
exec tail -n +3 $0

menuentry "LFS Pitbulls 12.4" {
    set root='hd0,gpt3'
    linux /boot/vmlinuz-6.16.1-lfs-12.4 root=/dev/sda3 ro
}

# Torna o script executável
sudo chmod +x /etc/grub.d/40_custom

# Atualiza o GRUB novamente para incluir a entrada do LFS
sudo update-grub

# Verifica se o LFS foi detectado no menu do GRUB
sudo grep -i "lfs" /boot/grub/grub.cfg

# Verificação adicional da configuração do GRUB
sudo nano /etc/default/grub

# Reinicia o sistema para testar o boot do LFS
sudo reboot