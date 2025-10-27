
#                   CONFIGURANDO O SISTEMA




#           CRIAÇÃO DA ESTRUTURA DE DIRETÓRIOS DO SISTEMA


# Cria diretórios essenciais do Filesystem Hierarchy Standard
mkdir -pv /{boot,home,mnt,opt,srv}

mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/lib/locale
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

# Cria links simbólicos
ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

# Define permissões de diretórios especiais
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

# Remove lib64 se existir (decisão consciente)
rm -rf /usr/lib64

# Cria link para mtab
ln -sv /proc/self/mounts /etc/mtab


#           CONFIGURAÇÃO DE ARQUIVOS BÁSICOS DO SISTEMA


# Configura hosts
cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

# Configura passwd
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

# Configura groups
cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

# Adiciona usuário tester para testes
echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester

# Reinicia shell para aplicar configurações
exec /usr/bin/bash --login

# Configura arquivos de log
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp


#           INSTALAÇÃO DE PACOTES ADICIONAIS NO CHROOT


cd sources

# Gettext
tar xvf gettext-0.26.tar.xz 
cd gettext-0.26/
./configure --disable-shared
echo $?
make -j1 
echo $?
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

# Bison
cd ../
tar xvf bison-3.8.2.tar.xz 
cd bison-3.8.2/
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
echo $?
make -j1
echo $?
make install

# Perl
cd ../
tar xvf perl-5.42.0.tar.xz 
cd perl-5.42.0/
sh Configure -des                                         \
             -D prefix=/usr                               \
             -D vendorprefix=/usr                         \
             -D useshrplib                                \
             -D privlib=/usr/lib/perl5/5.42/core_perl     \
             -D archlib=/usr/lib/perl5/5.42/core_perl     \
             -D sitelib=/usr/lib/perl5/5.42/site_perl     \
             -D sitearch=/usr/lib/perl5/5.42/site_perl    \
             -D vendorlib=/usr/lib/perl5/5.42/vendor_perl \
             -D vendorarch=/usr/lib/perl5/5.42/vendor_perl
echo $?
make -j1
echo $?
make install

# Python (com P maiúsculo)
cd ../
tar xvf Python-3.13.7.tar.xz
cd Python-3.13.7/
./configure --prefix=/usr       \
            --enable-shared     \
            --without-ensurepip \
            --without-static-libpython
echo $?
make -j1  # Pode dar fatal error, mas o importante é echo $? ser 0
echo $?
make install
echo $?

# Texinfo
cd ../
tar xvf texinfo-7.2.tar.xz 
cd texinfo-7.2/
./configure --prefix=/usr
echo $?
make -j1
echo $?
make install
echo $?

# Util-linux
cd ../
tar xvf util-linux-2.41.1.tar.xz 
cd util-linux-2.41.1/
mkdir -pv /var/lib/hwclock
./configure --libdir=/usr/lib     \
            --runstatedir=/run    \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-static      \
            --disable-liblastlog2 \
            --without-python      \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.41.1
echo $?
make -j1
echo $?
make install
echo $?


#           LIMPEZA FINAL DO SISTEMA


cd ../..

# Remove documentação temporária
rm -rf /usr/share/{info,man,doc}/*

# Remove arquivos .la
find /usr/{lib,libexec} -name \*.la -delete

# Remove ferramentas temporárias
rm -rf /tools

# Sai do chroot
exit


#           FINALIZAÇÃO NO SISTEMA HOST COM A CRIAÇÃO DO BACKUP


# Desmonta filesystems virtuais (AGORA COMO ROOT DO SISTEMA HOST)
mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
umount $LFS/dev/pts
umount $LFS/{sys,proc,run,dev}

# Cria backup temporário do sistema LFS
cd $LFS
tar -cJpf $HOME/lfs-temp-tools-12.4.tar.xz .