
#                   COMPILANDO FERRAMENTAS TEMPORÁRIAS


#           BINUTILS


# Muda para usuário lfs
su - lfs

# Navega para diretório de fontes
cd $LFS/sources

# Extrai código fonte do binutils
tar xvf binutils-2.45.tar.xz

# Entra no diretório extraído
cd binutils-2.45

# Cria diretório de build separado
mkdir build 
cd build

# Configura binutils para cross-compilation
../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-new-dtags  \
             --enable-default-hash-style=gnu

# Compila binutils
make

# Instala no diretório de ferramentas LFS
make install


#           GCC


# Volta para o diretório sources
cd ../..

# Extrai GCC
tar xvf gcc-15.2.0.tar.xz
cd gcc-15.2.0/

# Instala bibliotecas matemáticas necessárias para o GCC
tar xvf ../mpfr-4.2.2.tar.xz 
mv -v mpfr-4.2.2/ mpfr

tar xvf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0/ gmp

tar xvf ../mpc-1.3.1.tar.gz 
mv -v mpc-1.3.1/ mpc

# Corrige configuração para arquitetura x86_64
sed -e '/m64=/s/lib64/lib/' \
      -i.orig gcc/config/i386/t-linux64

# Prepara build
mkdir -v build
cd build

# Configura GCC para cross-compilation
../configure                  \
    --target=$LFS_TGT         \
    --prefix=$LFS/tools       \
    --with-glibc-version=2.42 \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++

# Verifica se configuração foi bem sucedida (deve retornar 0)
echo $?

# Compila GCC (pode levar bastante tempo)
make
echo $?

# Instala no diretório de ferramentas
make install

# Verifica configuração do ambiente
cat /home/lfs/.bashrc

# Prepara headers de limites
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h


#           LINUX API HEADERS


cd ..
tar xvf linux-6.16.1.tar.xz
cd linux-6.16.1

# Limpa sources
make mrproper

# Compila headers
make headers

# Limpa headers não essenciais
find usr/include -type f ! -name '*.h' -delete

# Copia headers para sistema LFS
cp -rv usr/include $LFS/usr


#           GLIBC (BIBLIOTECA C)


cd ../  # Volta para sources
tar xvf glibc-2.42.tar.xz

# Cria links simbólicos para compatibilidade
ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3

cd glibc-2.42

# Aplica patch FHS
patch -Np1 -i ../glibc-2.42-fhs-1.patch

mkdir -v build
cd build

# Configura parâmetros de build
echo "rootsbindir=/usr/sbin" > configparms

# Configura glibc
../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --disable-nscd                     \
      libc_cv_slibdir=/usr/lib           \
      --enable-kernel=5.4

# Compila glibc (usando apenas 1 job para evitar erros)
make -j1
echo $?

# Instala no sistema LFS
make DESTDIR=$LFS install

# Corrige caminhos no ldd
sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd


#           VERIFICAÇÕES DA TOOLCHAIN


# Testa a toolchain
echo 'int main(){}' | $LFS_TGT-gcc -x c - -v -Wl,--verbose &> dummy.log

# Verifica interpretador de programa (deve retornar a linha abaixo)
readelf -l a.out | grep ': /lib'
# [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]

# Verificações adicionais da toolchain
grep -E -o "$LFS/lib.*/S?crt[1in].*succeeded" dummy.log
grep -B3 "^ $LFS/usr/include" dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log

# Limpa arquivos temporários
rm -v a.out dummy.log

# Instala headers adicionais
$LFS/tools/libexec/gcc/$LFS_TGT/15.2.0/install-tools/mkheaders

# Verifica instalação
ls $LFS/tools/libexec/gcc/$LFS_TGT/15.2.0/install-tools/mkheaders


#           LIBSTDC++ (PARTE DO GCC)


cd ../..
rm -rf gcc-15.2.0/

# Reextrai GCC para libstdc++
tar xvf gcc-15.2.0.tar.xz
cd gcc-15.2.0
mkdir -v build 
cd build 

# Configura libstdc++
../libstdc++-v3/configure      \
    --host=$LFS_TGT            \
    --build=$(../config.guess) \
    --prefix=/usr              \
    --disable-multilib         \
    --disable-nls              \
    --disable-libstdcxx-pch    \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/15.2.0

echo $?
make -j 1
echo $?
make DESTDIR=$LFS install
echo $?

# Remove arquivos .la desnecessários
rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la
