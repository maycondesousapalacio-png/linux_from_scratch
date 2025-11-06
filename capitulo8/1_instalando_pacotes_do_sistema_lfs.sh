
#                   INSTALANDO APLICATIVOS BÁSICOS DO SISTEMA




#           1. Preparação do Ambiente Chroot


# Montar sistemas virtuais (PARA VOLTAR AO CHROOT QUANDO O BACKUP TERMINAR)
export LFS=/mnt/lfs

mount -v --bind /dev $LFS/dev
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys  
mount -vt tmpfs tmpfs $LFS/run

# Só execute este comando se o diretório $LFS/dev/pts não existir
mkdir -pv $LFS/dev/pts

# Entrar no chroot
chroot "$LFS" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    /bin/bash --login


#           2. Man-pages


cd sources
tar xvf man-pages-6.15.tar.xz 
cd man-pages-6.15/
# Remove páginas de manual para crypt (obsoletas)
rm -v man3/crypt*
# Instala as páginas de manual
make -R GIT=false prefix=/usr install
echo $?


#           3. Iana-etc


cd ../
tar xvf iana-etc-20250807.tar.gz 
cd iana-etc-20250807/
# Copia os arquivos de serviços e protocolos para /etc
cp services protocols /etc


#           4. Glibc (Segunda Passagem)


cd ../
rm -r glibc-2.42/
tar xvf glibc-2.42.tar.xz 
cd glibc-2.42/
# Aplica patch para conformidade com FHS
patch -Np1 -i ../glibc-2.42-fhs-1.patch

# Corrige includes e inicialização de lock no abort
sed -e '/unistd.h/i #include <string.h>' \
    -e '/libc_rwlock_init/c\
  __libc_rwlock_define_initialized (, reset_lock);\
  memcpy (&lock, &reset_lock, sizeof (lock));' \
    -i stdlib/abort.c

mkdir -v build
cd build

echo "rootsbindir=/usr/sbin" > configparms
../configure --prefix=/usr                   \
             --disable-werror                \
             --disable-nscd                  \
             libc_cv_slibdir=/usr/lib        \
             --enable-stack-protector=strong \
             --enable-kernel=5.4
echo $?
make -j1
echo $?  # AQUI HOUVE UM ERRO QUE VAI SER DOCUMENTADO

make -j1 check
echo $?  # HOUVERAM DOIS ERROS RELACIONADOS AO MAKEFILE

# Corrige a instalação
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
echo $?

# Corrige o caminho no ldd
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd


#           5. Configuração de Localidades


# Gera várias localidades
localedef -i C -f UTF-8 C.UTF-8
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f ISO-8859-1 en_GB
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_ES -f ISO-8859-15 es_ES@euro
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i is_IS -f ISO-8859-1 is_IS
localedef -i is_IS -f UTF-8 is_IS.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f ISO-8859-15 it_IT@euro
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i se_NO -f UTF-8 se_NO.UTF-8
localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
localedef -i zh_TW -f UTF-8 zh_TW.UTF-8

# Adiciona localidade para português do Brasil
localedef -i pt_BR -f UTF-8 pt_BR.UTF-8

# Lista as localidades instaladas
locale -a    # ver os instalados


#           6. Configuração do nsswitch.conf


cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF


#           7. Configuração do Fuso Horário


# Extrai e instala dados de fuso horário
tar -xf ../../tzdata2025b.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO tz

# Seleciona o fuso horário interativamente
tzselect

# Cria link para o fuso horário do Brasil
ln -sfv /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime


#           8. Configuração do ld.so.conf


cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF

mkdir -pv /etc/ld.so.conf.d


#           9. Zlib


cd ../..
tar xvf zlib-1.3.1.tar.gz 
cd zlib-1.3.1/
./configure --prefix=/usr
echo $?
make
echo $?
make check
echo $?
make install
rm -fv /usr/lib/libz.a


#           10. Bzip2


cd ../
tar xvf bzip2-1.0.8.tar.gz
cd bzip2-1.0.8/
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make -j1
echo $?
make PREFIX=/usr install
echo $?
cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so

cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done
rm -fv /usr/lib/libbz2.a


#           11. Xz (Segunda Passagem)


cd ../
tar xvf xz-5.8.1.tar.xz 
cd xz-5.8.1/
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.8.1
echo $?
make -j1
echo $?
make -j1 check
echo $?
make install


#           12. Lz4


cd ../
tar xvf lz4-1.10.0.tar.gz 
cd lz4-1.10.0/ 
make BUILD_STATIC=no PREFIX=/usr
echo $?
make -j1 check
echo $?
make BUILD_STATIC=no PREFIX=/usr install


#           13. Zstd


cd ../
tar xvf zstd-1.5.7.tar.gz 
cd zstd-1.5.7/
make prefix=/usr
echo $?
make -j1 check
echo $? 
make prefix=/usr install
rm -v /usr/lib/libzstd.a


#           14. File (Segunda Passagem)


cd ../
rm -rf file-5.46/
tar xvf file-5.46.tar.gz 
cd file-5.46/
./configure --prefix=/usr
echo $?
make -j1 
echo $?
make -j1 check
echo $?
make install 


#           15. Readline


cd ../
tar xvf readline-8.3.tar.gz 
cd readline-8.3/
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf
./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.3
echo $?
make SHLIB_LIBS="-lncursesw"
echo $?
make install
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.3


#           16. M4 (Segunda Passagem)


cd ../
rm -rf m4-1.4.20/
tar xvf m4-1.4.20.tar.xz 
cd m4-1.4.20/
./configure --prefix=/usr
echo $?
make -j1
echo $?
make -j1 check
echo $?
make install


#           17. Bc


cd ../
tar xvf bc-7.0.3.tar.xz 
cd bc-7.0.3/
CC='gcc -std=c99' ./configure --prefix=/usr -G -O3 -r
echo $?
make -j1
echo $?
make test
make install
echo $?


#           18. Flex


cd ../
tar xvf flex-2.6.4.tar.gz
cd flex-2.6.4/
./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static
echo $?
make -j1
echo $?
make -j1 check
echo $?
make install

# Cria links para lex
ln -sv flex   /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1


#           19. Tcl


cd ../
tar xvf tcl8.6.16-src.tar.gz 
cd tcl8.6.16/
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --disable-rpath
echo $?
make

# Corrige os caminhos nos scripts de configuração
sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.10|/usr/lib/tdbc1.1.10|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10/generic|/usr/include|"     \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10/library|/usr/lib/tcl8.6|"  \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10|/usr/include|"             \
    -i pkgs/tdbc1.1.10/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.3.2|/usr/lib/itcl4.3.2|" \
    -e "s|$SRCDIR/pkgs/itcl4.3.2/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.3.2|/usr/include|"            \
    -i pkgs/itcl4.3.2/itclConfig.sh

unset SRCDIR
make test

make install
chmod 644 /usr/lib/libtclstub8.6.a

chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sfv tclsh8.6 /usr/bin/tclsh
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3

cd ..
tar -xf ../tcl8.6.16-html.tar.gz --strip-components=1
mkdir -v -p /usr/share/doc/tcl-8.6.16
cp -v -r  ./html* /usr/share/doc/tcl-8.6.16


#           20. Expect


cd ../
tar xvf expect5.45.4.tar.gz 
cd expect5.45.4/
# Testa a funcionalidade pty (HOUVE UM ERRO AQUI, VEJA O LIVRO PARA CONTINUAR)
# FOI NECESSÁRIO SAIR DO CHROOT E ENTRAR DE NOVO COM OS MOUNT CORRETOS E O PATH CERTO
python3 -c 'from pty import spawn; spawn(["echo", "ok"])'
# Aplica patch para compatibilidade com GCC 15
patch -Np1 -i ../expect-5.45.4-gcc15-1.patch
./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --disable-rpath         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include
echo $?
make -j1
echo $?
make test

make install
# PARA ESSE COMANDO O PROFESSOR RESOLVEU SUBIR UM DIRETÓRIO cd .. PORÉM O LIVRO NÃO FAZ ISSO, ESCOLHI O LIVRO
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib


#           21. DejaGnu


cd ../
tar xvf dejagnu-1.6.3.tar.gz 
cd dejagnu-1.6.3/
mkdir -v build
cd build
../configure --prefix=/usr
echo $?
# Gera documentação
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi
echo $?
make -j1 check
make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3


#           22. Pkgconf


cd ../..
tar xvf pkgconf-2.5.1.tar.xz 
cd pkgconf-2.5.1/
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/pkgconf-2.5.1
echo $?
make -j1
echo $?
make install
# Cria links para pkg-config
ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1


#           23. Binutils (Segunda Passagem)


cd ../
rm -rf binutils-2.45/
tar xvf binutils-2.45.tar.xz 
cd binutils-2.45/
mkdir -v build
cd build
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --enable-new-dtags  \
             --with-system-zlib  \
             --enable-default-hash-style=gnu
echo $?
make tooldir=/usr
echo $?
make -k check
# Verifica falhas nos testes
grep '^FAIL:' $(find -name '*.log')
make tooldir=/usr install
echo $?
# Remove arquivos estáticos desnecessários
rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a \
        /usr/share/doc/gprofng/


#           24. GMP


cd ../..
tar xvf gmp-6.3.0.tar.xz 
cd gmp-6.3.0/
sed -i '/long long t1;/,+1s/()/(...)/' configure
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0
echo $?
make -j1
make html
make check 2>&1 | tee gmp-check-log   # aguardando esse
# Verifica o número de testes passados (deve ser 197 ou 199)
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log


#           25. MPFR


cd ../
tar xvf mpfr-4.2.2.tar.xz 
cd mpfr-4.2.2/
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.2
echo $?
make -j1
echo $?
make html  
make -j1 check
make install
make install-html


#           26. MPC


cd ../
tar xvf mpc-1.3.1.tar.gz 
cd mpc-1.3.1/
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.3.1
echo $?
make -j1
echo $?
make html
make -j1 check
make install
make install-html


#           27. Attr


cd ../
tar xvf attr-2.5.2.tar.gz 
cd attr-2.5.2/
./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.2
echo $?
make -j1
echo $?
make install


#           28. Acl


cd ../
tar xvf acl-2.3.2.tar.xz 
cd acl-2.3.2/
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/acl-2.3.2
echo $?
make -j1
echo $?
make install


#               29. Libcap


cd ../
tar xvf libcap-2.76.tar.xz 
cd libcap-2.76/
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib
make prefix=/usr lib=lib install


#           30. Libxcrypt


cd ../
tar xvf libxcrypt-4.4.38.tar.xz 
cd libxcrypt-4.4.38/
./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no     \
            --disable-static             \
            --disable-failure-tokens
echo $?
make -j1
make install


#           31. Shadow


cd ../
tar xvf shadow-4.18.0.tar.xz 
cd shadow-4.18.0/
# Remove a compilação do programa groups e suas páginas de manual
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

# Configurações de login
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs

touch /usr/bin/passwd

./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --with-group-name-max-length=32
echo $?
make -j1
echo $?
make exec_prefix=/usr install
make -C man install-man

# Configuração do shadow
export PATH=/tools/bin:/bin:/usr/bin:/usr/sbin
pwconv
grpconv
export PATH=/tools/bin:/bin:/usr/bin

mkdir -p /etc/default
/usr/sbin/useradd -D --gid 999
sed -i '/MAIL/s/yes/no/' /etc/default/useradd
# Define senha para root
passwd root       # Pitbulls


#           32. GCC (Segunda Passagem)


cd ../
rm -rf gcc-15.2.0/
tar xvf gcc-15.2.0.tar.xz 
cd gcc-15.2.0/
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
mkdir -v build
cd build
../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --enable-host-pie        \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib
echo $?
make -j1
echo $?
# Aumenta o limite de stack para os testes
ulimit -s -H unlimited
# Remove um teste problemático
sed -e '/cpython/d' -i ../gcc/testsuite/gcc.dg/plugin/plugin.exp
chown -R tester .

# Executa testes como usuário tester
su tester -c "PATH=$PATH make -k check"

echo $?

# Gera um sumário dos testes
../contrib/test_summary    # esse comando extrai um sumário dos testes, pega os resultados, joga na IA dizendo que está no capítulo 8 na compilação do gcc e pergunta se está tudo ok, se não estiver me chama

make install

# Corrige propriedades dos headers
chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/15.2.0/include{,-fixed}

# Cria links
ln -svr /usr/bin/cpp /usr/lib
ln -sv gcc.1 /usr/share/man/man1/cc.1
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/15.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/

# Testa a toolchain
echo 'int main(){}' | cc -x c - -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

# [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2] - O RESULTADO DO TESTE DE CIMA TEM QUE SER ESSE

# Verificações adicionais
grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log      # RESULTADO DO TESTE NO LIVRO
grep -B4 '^ /usr/include' dummy.log      # RESULTADO DO TESTE NO LIVRO
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'    # RESULTADO DO TESTE NO LIVRO
grep "/lib.*/libc.so.6 " dummy.log    # RESULTADO DO TESTE NO LIVRO
grep found dummy.log

rm -v a.out dummy.log

# Configuração do GDB
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib


#           33. Ncurses (Segunda Passagem)


cd ../..
tar xvf ncurses-6.5-20250809.tgz 
cd ncurses-6.5-20250809/
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --with-pkg-config-libdir=/usr/lib/pkgconfig
echo $?
make -j1
echo $?
make DESTDIR=$PWD/dest install
echo $?
install -vm755 dest/usr/lib/libncursesw.so.6.5 /usr/lib
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i dest/usr/include/curses.h
cp -av dest/* /

for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
done

ln -sfv libncursesw.so /usr/lib/libcurses.so
cp -v -R doc -T /usr/share/doc/ncurses-6.5-20250809


#           34. Sed (Segunda Passagem)


cd ../
rm -r sed-4.9/
tar xvf sed-4.9.tar.xz 
cd sed-4.9/
./configure --prefix=/usr
echo $?
make -j1
echo $?
make html
echo $?

chown -R tester .
su tester -c "PATH=$PATH make check"

make install
install -d -m755           /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9


#           35. Psmisc


cd ../
tar xvf psmisc-23.7.tar.xz 
cd psmisc-23.7/
./configure --prefix=/usr
echo $?
make -j1
echo $?
make install
echo $?


#           36. Gettext (Segunda Passagem)


cd ../
rm -r gettext-0.26/
tar xvf gettext-0.26.tar.xz 
cd gettext-0.26/
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.26
echo $?
make -j1
echo $?
make install
echo $?


#           37. Bison (Segunda Passagem)


cd ../
rm -r bison-3.8.2/
tar xvf bison-3.8.2.tar.xz 
cd bison-3.8.2/
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
echo $?
make -j1
echo $?
make install


#               38. Grep (Segunda Passagem)


cd ../
rm -r grep-3.12/
tar xvf grep-3.12.tar.xz 
cd grep-3.12/
sed -i "s/echo/#echo/" src/egrep.sh
./configure --prefix=/usr
echo $?
make -j1
echo $?
make install
echo $?


#           39. Bash (Segunda Passagem)


cd ../
tar xvf bash-5.3.tar.gz 
cd bash-5.3/
./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            --docdir=/usr/share/doc/bash-5.3
echo $?
make -j1  # aguardando esse
echo $?
# Executa testes com expect
LC_ALL=C.UTF-8 su -s /usr/bin/expect tester << "EOF"
set timeout -1
spawn make tests
expect eof
lassign [wait] _ _ _ value
exit $value
EOF

make install
echo $?
# Reinicia o bash
exec /usr/bin/bash --login


#           40. Libtool


cd ../
tar xvf libtool-2.5.4.tar.xz 
cd libtool-2.5.4/
./configure --prefix=/usr
echo $?
make -j1
echo $?
make install
echo $?
rm -fv /usr/lib/libltdl.a


#           41. Gdbm


cd ../
tar xvf gdbm-1.26.tar.gz 
cd gdbm-1.26/
./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat
echo $?
make -j1
echo $?
make install
echo $?


#           42. Gperf


cd ../
tar xvf gperf-3.3.tar.gz 
cd gperf-3.3/
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.3
echo $?
make -j1


#           43. Expat


cd ../
tar xvf expat-2.7.1.tar.xz 
cd expat-2.7.1/
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.7.1
echo $?
make -j1
echo $?
make install
echo $?
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.7.1


#           44. Inetutils


cd ../
tar xvf inetutils-2.6.tar.xz 
cd inetutils-2.6/
sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c
./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers
echo $?
make -j1 
echo $?
make install
echo $?
mv -v /usr/{,s}bin/ifconfig


#           45. Less


cd ../
tar xvf less-679.tar.gz 
cd less-679/
./configure --prefix=/usr --sysconfdir=/etc
echo $?
make -j1 
echo $?
make install


#           46. Perl (Segunda Passagem)


cd ../
rm -r perl-5.42.0/
tar xvf perl-5.42.0.tar.xz 
cd perl-5.42.0/
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des                                          \
             -D prefix=/usr                                \
             -D vendorprefix=/usr                          \
             -D privlib=/usr/lib/perl5/5.42/core_perl      \
             -D archlib=/usr/lib/perl5/5.42/core_perl      \
             -D sitelib=/usr/lib/perl5/5.42/site_perl      \
             -D sitearch=/usr/lib/perl5/5.42/site_perl     \
             -D vendorlib=/usr/lib/perl5/5.42/vendor_perl  \
             -D vendorarch=/usr/lib/perl5/5.42/vendor_perl \
             -D man1dir=/usr/share/man/man1                \
             -D man3dir=/usr/share/man/man3                \
             -D pager="/usr/bin/less -isR"                 \
             -D useshrplib                                 \
             -D usethreads
echo $?
make -j1 
echo $?
make install
echo $?
unset BUILD_ZLIB BUILD_BZIP2


#           47. XML-Parser


cd ../
tar xvf XML-Parser-2.47.tar.gz 
cd XML-Parser-2.47/
perl Makefile.PL
echo $?
make -j1
echo $?
make install
echo $?


#           48. Intltool


cd ../
tar xvf intltool-0.51.0.tar.gz 
cd intltool-0.51.0/
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
echo $?
make -j1
echo $?
make install
echo $?
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO


#           49. Autoconf


cd ../
tar xvf autoconf-2.72.tar.xz 
cd autoconf-2.72/
./configure --prefix=/usr
echo $?
make -j1
echo $?
make install


#           50. Automake


cd ../
tar xvf automake-1.18.1.tar.xz 
cd automake-1.18.1/
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.18.1
echo $?
make -j1
echo $?
make install
echo $?


#           51. Openssl


cd ../
tar xvf openssl-3.5.2.tar.gz 
cd openssl-3.5.2/
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
echo $?
make -j1
echo $?

sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install

mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.5.2
cp -vfr doc/* /usr/share/doc/openssl-3.5.2


#           52. Elfutils


cd ../
tar xvf elfutils-0.193.tar.bz2 
cd elfutils-0.193/
./configure --prefix=/usr        \
            --disable-debuginfod \
            --enable-libdebuginfod=dummy
echo $?
make -j1
echo $?
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a


#           53. Libffi


cd ../
tar xvf libffi-3.5.2.tar.gz 
cd libffi-3.5.2/
./configure --prefix=/usr    \
            --disable-static \
            --with-gcc-arch=native
echo $?
make -j1
echo $?
make install
echo $?


#           54. Python (Segunda Passagem)


cd ../
rm -r Python-3.13.7/
tar xvf Python-3.13.7.tar.xz 
cd Python-3.13.7/
./configure --prefix=/usr          \
            --enable-shared        \
            --with-system-expat    \
            --enable-optimizations \
            --without-static-libpython
echo $?
make -j1
echo $?
make install
echo $?

# Configura o pip
cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF

# Instala documentação
install -v -dm755 /usr/share/doc/python-3.13.7/html

tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.13.7/html \
    -xvf ../python-3.13.7-docs-html.tar.bz2


#           55. Flit_core


cd ../
tar xvf flit_core-3.12.0.tar.gz 
cd flit_core-3.12.0/
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD


#           56. Packaging


cd ../
tar xvf packaging-25.0.tar.gz 
cd packaging-25.0/
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist packaging


#           57. Wheel


cd ../
tar xvf wheel-0.46.1.tar.gz 
cd wheel-0.46.1/
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist wheel


#           58. Setuptools


cd ../
tar xvf setuptools-80.9.0.tar.gz 
cd setuptools-80.9.0/
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist setuptools


#           59. Ninja


cd ../
tar xvf ninja-1.13.1.tar.gz 
cd ninja-1.13.1/
export NINJAJOBS=1     # foi utilizada a abordagem mais conservadora

# Modifica o código para usar a variável NINJAJOBS
sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc

python3 configure.py --bootstrap --verbose

install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja


#           60. Meson


cd ../
tar xvf meson-1.8.3.tar.gz 
cd meson-1.8.3/
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
echo $?
pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson


#           61. Kmod


cd ../
tar xvf kmod-34.2.tar.xz 
cd kmod-34.2/
mkdir -p build
cd build
meson setup --prefix=/usr ..    \
            --buildtype=release \
            -D manpages=false
echo $?
ninja
echo $?
ninja install
echo $?


#           62. Coreutils (Segunda Passagem)


cd ../..
rm -r coreutils-9.7/
tar xvf coreutils-9.7.tar.xz 
cd coreutils-9.7/
patch -Np1 -i ../coreutils-9.7-upstream_fix-1.patch
patch -Np1 -i ../coreutils-9.7-i18n-1.patch

autoreconf -fv
automake -af
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime
echo $?
make -j1     # aguardando esse
echo $?
make install
echo $?

mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8


#           63. Diffutils (Segunda Passagem)


cd ../
rm -r diffutils-3.12/
tar xvf diffutils-3.12.tar.xz 
cd diffutils-3.12/
./configure --prefix=/usr
echo $?
make -j1
echo $?
make install
echo $?


#           64. Gawk (Segunda Passagem)


cd ../
rm -r gawk-5.3.2/
tar xvf gawk-5.3.2.tar.xz 
cd gawk-5.3.2/
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr
echo $?
make -j1
echo $?

rm -f /usr/bin/gawk-5.3.2
make install

echo ?
ln -sv gawk.1 /usr/share/man/man1/awk.1
install -vDm644 doc/{awkforai.txt,*.{eps,pdf,jpg}} -t /usr/share/doc/gawk-5.3.2


#           65. Findutils (Segunda Passagem)


cd ../
rm -r findutils-4.10.0/
tar xvf findutils-4.10.0.tar.xz 
cd findutils-4.10.0/
./configure --prefix=/usr --localstatedir=/var/lib/locate      # aguardando esse
echo $?
make -j1
echo $?
make install
echo $


#           66. Groff


cd ../
tar xvf groff-1.23.0.tar.gz 
cd groff-1.23.0/
PAGE=A4 ./configure --prefix=/usr
make -j1
echo $?
make install
echo $?


#           67. Grub


cd ../
tar xvf grub-2.12.tar.xz 
cd grub-2.12/
unset {C,CPP,CXX,LD}FLAGS
echo depends bli part_gpt > grub-core/extra_deps.lst
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-efiemu  \
            --disable-werror
echo $?
make -j1    # aguardando esse
echo $?
make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions


#           68. Gzip (Segunda Passagem)


cd ../
rm -r gzip-1.14/
tar xvf gzip-1.14.tar.xz 
cd gzip-1.14/
./configure --prefix=/usr
echo $?
make -j1
echo $?
make install
echo $?


#           69. Iproute2


cd ../
tar xvf iproute2-6.16.0.tar.xz 
cd iproute2-6.16.0/
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
make NETNS_RUN_DIR=/run/netns
echo $?
make SBINDIR=/usr/sbin install
echo $?
install -vDm644 COPYING README* -t /usr/share/doc/iproute2-6.16.0


#           70. Kbd


cd ../
tar xvf kbd-2.8.0.tar.xz
cd kbd-2.8.0/
patch -Np1 -i ../kbd-2.8.0-backspace-1.patch
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
./configure --prefix=/usr --disable-vlock
echo $?
make -j1
echo $?
make install
echo $?
cp -R -v docs/doc -T /usr/share/doc/kbd-2.8.0


#           71. Libpipeline


cd ../
tar xvf libpipeline-1.5.8.tar.gz 
cd libpipeline-1.5.8/
./configure --prefix=/usr
echo $?
make -j1
echo $?
make install
echo $?


#           72. Make (Segunda Passagem)


cd ../
tar xvf make-4.4.1.tar.gz 
cd make-4.4.1/
./configure --prefix=/usr
echo $?
make -j1
echo $?
make install
echo $?


#           73. Patch (Segunda Passagem)


cd ../
tar xvf patch-2.8.tar.xz 
cd patch-2.8/
./configure --prefix=/usr
echo $?
make -j1
echo $?
make install
echo $?


#           74. Tar (Segunda Passagem)


cd ../
rm -r tar-1.35/
tar xvf tar-1.35.tar.xz 
cd tar-1.35/
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr
echo $?
make -j1
echo $?
make install
echo $?
make -C doc install-html docdir=/usr/share/doc/tar-1.35


#           75. Texinfo (Segunda Passagem)


cd ../
rm -r texinfo-7.2/
tar xvf texinfo-7.2.tar.xz 
cd texinfo-7.2/
sed 's/! $output_file eq/$output_file ne/' -i tp/Texinfo/Convert/*.pm
./configure --prefix=/usr
echo $?
make -j1
echo $?
make install
echo $?
make TEXMF=/usr/share/texmf install-tex

pushd /usr/share/info
  rm -v dir
  for f in *
    do install-info $f dir 2>/dev/null
  done
popd


#           76. Vim


cd ../
tar xvf vim-9.1.1629.tar.gz 
cd vim-9.1.1629/
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
echo $?
make -j1
echo $?
make install
echo $?
ln -sv vim /usr/bin/vi

for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done

ln -sv ../vim/vim91/doc /usr/share/doc/vim-9.1.1629

# Configuração do vim
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF

# Abre vim para verificar configuração
vim -c ':options'


#           77. Markupsafe


cd ../
tar xvf markupsafe-3.0.2.tar.gz 
cd markupsafe-3.0.2/
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist Markupsafe


#           78. Jinja2


cd ../
tar xvf jinja2-3.1.6.tar.gz 
cd jinja2-3.1.6/
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist Jinja2


#           79. Systemd


cd ../
xvf systemd-257.8.tar.gz 
cd systemd-257.8/
sed -e 's/GROUP="render"/GROUP="video"/' \
    -e 's/GROUP="sgx", //'               \
    -i rules.d/50-udev-default.rules.in

sed -i '/systemd-sysctl/s/^/#/' rules.d/99-systemd.rules.in

sed -e '/NETWORK_DIRS/s/systemd/udev/' \
    -i src/libsystemd/sd-network/network-util.h

mkdir -p build
cd build
meson setup ..                  \
      --prefix=/usr             \
      --buildtype=release       \
      -D mode=release           \
      -D dev-kvm-mode=0660      \
      -D link-udev-shared=false \
      -D logind=false           \
      -D vconsole=false
echo $?

export udev_helpers=$(grep "'name' :" ../src/udev/meson.build | \
                      awk '{print $3}' | tr -d ",'" | grep -v 'udevadm')

ninja udevadm systemd-hwdb                                           \
      $(ninja -n | grep -Eo '(src/(lib)?udev|rules.d|hwdb.d)/[^ ]*') \
      $(realpath libudev.so --relative-to .)                         \
      $udev_helpers
echo $?

install -vm755 -d {/usr/lib,/etc}/udev/{hwdb.d,rules.d,network}
install -vm755 -d /usr/{lib,share}/pkgconfig
install -vm755 udevadm                             /usr/bin/
install -vm755 systemd-hwdb                        /usr/bin/udev-hwdb
ln      -svfn  ../bin/udevadm                      /usr/sbin/udevd
cp      -av    libudev.so{,*[0-9]}                 /usr/lib/
install -vm644 ../src/libudev/libudev.h            /usr/include/
install -vm644 src/libudev/*.pc                    /usr/lib/pkgconfig/
install -vm644 src/udev/*.pc                       /usr/share/pkgconfig/
install -vm644 ../src/udev/udev.conf               /etc/udev/
install -vm644 rules.d/* ../rules.d/README         /usr/lib/udev/rules.d/
install -vm644 $(find ../rules.d/*.rules \
                      -not -name '*power-switch*') /usr/lib/udev/rules.d/
install -vm644 hwdb.d/*  ../hwdb.d/{*.hwdb,README} /usr/lib/udev/hwdb.d/
install -vm755 $udev_helpers                       /usr/lib/udev
install -vm644 ../network/99-default.link          /usr/lib/udev/network

echo $?

# Instala regras LFS
tar -xvf ../../udev-lfs-20230818.tar.xz
make -f udev-lfs-20230818/Makefile.lfs install

# Instala páginas de manual
tar -xf ../../systemd-man-pages-257.8.tar.xz                            \
    --no-same-owner --strip-components=1                              \
    -C /usr/share/man --wildcards '*/udev*' '*/libudev*'              \
                                  '*/systemd.link.5'                  \
                                  '*/systemd-'{hwdb,udevd.service}.8

sed 's|systemd/network|udev/network|'                                 \
    /usr/share/man/man5/systemd.link.5                                \
  > /usr/share/man/man5/udev.link.5

sed 's/systemd\(\\\?-\)/udev\1/' /usr/share/man/man8/systemd-hwdb.8   \
                               > /usr/share/man/man8/udev-hwdb.8

sed 's|lib.*udevd|sbin/udevd|'                                        \
    /usr/share/man/man8/systemd-udevd.service.8                       \
  > /usr/share/man/man8/udevd.8

rm /usr/share/man/man*/systemd*

unset udev_helpers

# Atualiza hwdb
udev-hwdb update


#           80. Man-db


cd ../..
tar xvf man-db-2.13.1.tar.xz 
cd man-db-2.13.1/
./configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.13.1 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap             \
            --with-systemdtmpfilesdir=            \
            --with-systemdsystemunitdir=
echo $?
make -j1
echo $?
make install
echo $?


#           81. Procps-ng


cd ../
tar xvf procps-ng-4.0.5.tar.xz 
cd procps-ng-4.0.5/
./configure --prefix=/usr                           \
            --docdir=/usr/share/doc/procps-ng-4.0.5 \
            --disable-static                        \
            --disable-kill                          \
            --enable-watch8bit
echo $?
make -j1
echo $?
make install
echo $?


#           82. Util-linux (Segunda Passagem)


cd ../
tar xvf util-linux-2.41.1.tar.xz 
cd util-linux-2.41.1/
./configure --bindir=/usr/bin     \
            --libdir=/usr/lib     \
            --runstatedir=/run    \
            --sbindir=/usr/sbin   \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-liblastlog2 \
            --disable-static      \
            --without-python      \
            --without-systemd     \
            --without-systemdsystemunitdir        \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.41.1
echo $?
make -j1
echo $?
make install 
echo $?


#           83. E2fsprogs


cd ../
tar xvf e2fsprogs-1.47.3.tar.gz 
cd e2fsprogs-1.47.3/
mkdir -v build 
cd build
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-elf-shlibs \
             --disable-libblkid  \
             --disable-libuuid   \
             --disable-uuidd     \
             --disable-fsck
echo $?
make -j1
echo #?
make install
echo $?
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a

gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info

makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf


#           84. Sysklogd


cd ../..
tar xvf sysklogd-2.7.2.tar.gz 
cd sysklogd-2.7.2/
./configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --runstatedir=/run \
            --without-logger   \
            --disable-static   \
            --docdir=/usr/share/doc/sysklogd-2.7.2
echo $?
make -j1
echo $?
make install
echo $?

# Configuração do syslog
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# Do not open any internet ports.
secure_mode 2

# End /etc/syslog.conf
EOF


#           85. Sysvinit


cd ../
tar xvf sysvinit-3.14.tar.xz 
cd sysvinit-3.14/
patch -Np1 -i ../sysvinit-3.14-consolidated-1.patch
make -j1 
echo $?
make install
echo $?

