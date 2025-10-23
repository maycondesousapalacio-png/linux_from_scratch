#           PREPARAÇÃO DA PARTIÇÃO

# Cria partição usando cfdisk (ferramenta gráfica de particionamento)
sudo cfdisk /dev/sda3

# Atualiza GRUB para reconhecer mudanças nas partições
sudo update-grub

# Formata a partição com sistema de arquivos ext4
sudo mkfs.ext4 -v /dev/sda3

#           CONFIGURANDO VARIÁVEIS DE AMBIENTE

# Define variável de ambiente LFS apontando para o diretório de montagem
export LFS=/mnt/lfs

# Adiciona variável LFS permanentemente ao .bashrc do root
sudo nano /root/.bashrc

# Verifica se a variável foi definida corretamente
echo $LFS  # deve mostrar /mnt/lfs

#           MONTANDO PARTIÇÃO LFS

# Cria diretório de montagem
sudo mkdir -pv $LFS

# Lista conteúdo do /mnt para verificar
ls /mnt/

# Monta a partição no diretório LFS
sudo mount -v /dev/sda3 $LFS

# Configura montagem automática no boot editando fstab
nano /etc/fstab
# Adicionar: /dev/sda3  /mnt/lfs  ext4  defaults  1 1