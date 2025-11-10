
#                   Configuração do Sistema




#           Instalação dos Bootscripts do LFS


cd sources
tar xvf lfs-bootscripts-20250827.tar.xz 
cd lfs-bootscripts-20250827
# Instala os scripts de inicialização do sistema
make install


#           Configuração de Rede


cd ../..
# Gera regras persistentes para dispositivos de rede
bash /usr/lib/udev/init-net-rules.sh
# Verifica as regras geradas para a interface de rede
cat /etc/udev/rules.d/70-persistent-net.rules

# Configura política de nomes alternativos para dispositivos de rede
sed -e '/^AlternativeNamesPolicy/s/=.*$/=/'  \
       /usr/lib/udev/network/99-default.link \
     > /etc/udev/network/99-default.link


#           Configuração de Dispositivos (Troubleshooting)


# Testa a configuração udev para um dispositivo de bloco (teve uma falha, mas parece que não é tão importante assim)
udevadm test /sys/block/hdd

# Corrige regras para dispositivos CD-ROM
sed -e 's/"write_cd_rules"/"write_cd_rules mode"/' \
-i /etc/udev/rules.d/83-cdrom-symlinks.rules

# Testa novamente após a correção (tentei de novo com a alteração mas não funcionou)
udevadm test /sys/block/hdd

# Obtém informações detalhadas sobre um dispositivo de vídeo
udevadm info -a -p /sys/class/video4linux/video0

# Cria regras persistentes para webcam e sintonizador TV
cat > /etc/udev/rules.d/83-duplicate_devs.rules << "EOF"

# Persistent symlinks for webcam and tuner
KERNEL=="video*", ATTRS{idProduct}=="1910", ATTRS{idVendor}=="0d81", SYMLINK+="webcam"
KERNEL=="video*", ATTRS{device}=="0x036f",  ATTRS{vendor}=="0x109e", SYMLINK+="tvtuner"

EOF


#           Configuração Básica do Sistema


# No diretório raiz...
# Define o nome do host
echo "lfs" > /etc/hostname

# Configura arquivo de hosts local
cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost.localdomain localhost
127.0.1.1 lfs.localdomain lfs

# End /etc/hosts
EOF

# Configura servidores DNS
cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf

nameserver 8.8.8.8
nameserver 8.8.4.4

# End /etc/resolv.conf
EOF

# Configuração da interface de rede eth0 para DHCP
mkdir -p /etc/sysconfig
cat > /etc/sysconfig/ifconfig.eth0 << "EOF"
ONBOOT=yes
IFACE=eth0
SERVICE=dhcp
EOF

# Verificando se os arquivos foram criados corretamente
ls -la /etc/hostname
ls -la /etc/hosts
ls -la /etc/resolv.conf
ls -la /etc/sysconfig/ifconfig.eth0


#           Configuração do Sistema de Inicialização (init)


# Configura o arquivo inittab para o SysV init
cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S06:once:/sbin/sulogin
s1:1:respawn:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

# End /etc/inittab
EOF


#           Configuração do Relógio do Sistema


# Configuração do fuso horário do hardware clock
cat > /etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock

UTC=1

# Set this to any options you might need to give to hwclock,
# such as machine hardware clock type for Alphas.
CLOCKPARAMS=

# End /etc/sysconfig/clock
EOF

# Verifica o horário atual do hardware clock
/usr/sbin/hwclock --localtime --show

# Ajusta para o fuso horário local (Brasil UTC-3)
vim /etc/sysconfig/clock        # UTC alterado para -3

# Garante que o diretório de zoneinfo existe
mkdir -p /usr/share/zoneinfo

# Configura o fuso horário do sistema
ln -sf /usr/share/zoneinfo/posix/UTC /etc/localtime 2>/dev/null || ln -sf /usr/share/zoneinfo/UTC /etc/localtime 2>/dev/null || echo "Usando fallback"


#           Configuração do Console e Teclado


# Adicionando o teclado brasileiro ABNT2
cat > /etc/sysconfig/console << "EOF"
# Begin /etc/sysconfig/console

KEYMAP="br-abnt2"
FONT="lat1-16 -m 8859-1"

# End /etc/sysconfig/console
EOF

# Parâmetros opcionais para o sysklogd (pode ser deixado vazio)
SYSKLOGD_PARMS=


#           Configuração do Site RC (Opcional)


# Configurações opcionais do sistema - foram feitas algumas configurações mas isso é opcional
vi /etc/sysconfig/rc.site


#           Configuração de Localização (Locale)


# Lista as localidades disponíveis
locale -a

# Define a localização padrão para português do Brasil
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf

# Configura o perfil do sistema para todos os usuários
cat > /etc/profile << "EOF"
# Begin /etc/profile

for i in $(locale); do
  unset ${i%=*}
done

if [[ "$TERM" = linux ]]; then
  export LANG=C.UTF-8
else
  export LANG=pt_BR.UTF-8
fi

# End /etc/profile
EOF


#           Configuração do Inputrc (Comportamento do Teclado)


# Configura o comportamento do teclado no terminal
cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8-bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF


#           Configuração dos Shells Válidos


# Define os shells válidos no sistema
cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF