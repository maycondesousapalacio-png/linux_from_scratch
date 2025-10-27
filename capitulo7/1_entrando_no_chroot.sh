
#                   ENTRANDO NO CHROOT




#           PREPARAÇÃO PARA CHROOT


# Sai do usuário lfs e volta para root
exit

# Verifica variável LFS
echo $LFS

# Muda propriedade dos diretórios para root
chown --from lfs -R root:root $LFS/{usr,var,etc,tools}
case $(uname -m) in
  x86_64) chown --from lfs -R root:root $LFS/lib64 ;;
esac


#           MONTAGEM DE SISTEMAS DE ARQUIVOS VIRTUAIS


# Cria diretórios para filesystems virtuais
mkdir -pv $LFS/{dev,proc,sys,run}

# Monta filesystems virtuais
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

# Configura /dev/shm
if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi


#           ENTRANDO NO CHROOT


# 🎉 PARABÉNS! Entrando no ambiente chroot
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login