
#                   COMPILANDO CRUZADAMENTE FERRAMENTAS TEMPORÁRIAS




#           M4


cd ../..
tar xvf m4-1.4.20.tar.xz
cd m4-1.4.20/
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make -j1
echo $?  # Verificação crítica - deve ser 0
make DESTDIR=$LFS install


#           NCURSES


cd /mnt/lfs/sources
tar -xf ncurses-6.5-20250809.tgz
cd ncurses-6.5-20250809

# Build temporário para tic
mkdir build
pushd build
../configure --prefix=$LFS/tools AWK=gawk
make -C include
make -C progs tic
install progs/tic $LFS/tools/bin
popd

# Build principal
./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
            AWK=gawk

make
echo $?
make DESTDIR=$LFS install

# Cria links de compatibilidade
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so

# Corrige header curses
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h


#           BASH


cd ../..
tar xvf bash-5.3.tar.gz 
cd bash-5.3/

./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc

echo $?
make -j1
echo $?
make DESTDIR=$LFS install
echo $?

# Cria link sh -> bash
ln -sv bash $LFS/bin/sh

# Verifica link
ls --color -l $LFS/bin/sh  # deve apontar para bash


#           COREUTILS


cd ..
tar xvf coreutils-9.7.tar.xz
cd coreutils-9.7/

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime

echo $?
make -j1
echo $?
make DESTDIR=$LFS install
echo $?

# Move chroot para sbin e atualiza man page
mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8


#      DIFFUTILS


cd ..
tar xvf diffutils-3.12.tar.xz 
cd diffutils-3.12/
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            gl_cv_func_strcasecmp_works=y \
            --build=$(./build-aux/config.guess)
echo $?
make -j1
echo $?
make DESTDIR=$LFS install
echo $?


#           FINDUTILS


cd ../
tar xvf findutils-4.10.0.tar.xz 
cd findutils-4.10.0/
./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)
echo $?
make -j1
echo $?
make DESTDIR=$LFS install


#           GAWK


cd ../
tar xvf gawk-5.3.2.tar.xz
cd gawk-5.3.2/
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
echo $?
make -j1
echo $?
make DESTDIR=$LFS install
echo $?


#           GREP


cd ../
tar xvf grep-3.12.tar.xz 
cd grep-3.12/
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
echo $?
make -j1
echo $?
make DESTDIR=$LFS install
echo $?


#           GZIP


cd ../
tar xvf gzip-1.14.tar.xz 
cd gzip-1.14/
./configure --prefix=/usr --host=$LFS_TGT
echo $?
make -j1
echo $?
make DESTDIR=$LFS install
echo $?


#           MAKE


cd ../
tar xvf make-4.4.1.tar.gz 
cd make-4.4.1/
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
echo $?
make -j1
echo $?
make DESTDIR=$LFS install
echo $?


#           PATCH


cd ../
tar xvf patch-2.8.tar.xz 
cd patch-2.8/
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
echo $?
make -j1
echo $?
make DESTDIR=$LFS install
echo $?


#           SED


cd ../
tar xvf sed-4.9.tar.xz 
cd sed-4.9/
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
echo $?
make -j1
echo $?
make DESTDIR=$LFS install
echo $?


#           TAR


cd ../
tar xvf tar-1.35.tar.xz 
cd tar-1.35/
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
echo $?
make -j1
echo $?
make DESTDIR=$LFS install


#           XZ


cd ../ 
tar xvf xz-5.8.1.tar.xz 
cd xz-5.8.1/
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.8.1
echo $?
make -j1
echo $?
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/liblzma.la


#           SEGUNDA PASSAGEM - BINUTILS


cd ../
rm -r binutils-2.45
tar xvf binutils-2.45.tar.xz 
cd binutils-2.45/
sed '6031s/$add_dir//' -i ltmain.sh
mkdir -v build 
cd build
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-new-dtags         \
    --enable-default-hash-style=gnu
echo $?
make -j1
echo $?
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}


#           SEGUNDA PASSAGEM - GCC


cd ../..
rm -r gcc-15.2.0
tar xvf gcc-15.2.0.tar.xz
cd gcc-15.2.0/

tar -xf ../mpfr-4.2.2.tar.xz
mv -v mpfr-4.2.2 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in
mkdir -v build
cd build

../configure                   \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --target=$LFS_TGT          \
    --prefix=/usr              \
    --with-build-sysroot=$LFS  \
    --enable-default-pie       \
    --enable-default-ssp       \
    --disable-nls              \
    --disable-multilib         \
    --disable-libatomic        \
    --disable-libgomp          \
    --disable-libquadmath      \
    --disable-libsanitizer     \
    --disable-libssp           \
    --disable-libvtv           \
    --enable-languages=c,c++   \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc
echo $?
make -j1
echo $?
make DESTDIR=$LFS install
echo $?
ln -sv gcc $LFS/usr/bin/cc