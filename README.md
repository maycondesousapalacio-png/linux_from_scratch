#  Linux From Scratch (LFS)

Este projeto documenta a construção de um sistema Linux completamente do zero, seguindo o livro **[Linux From Scratch (LFS)](https://www.linuxfromscratch.org/)**.  
O objetivo é compreender em profundidade como um sistema Linux funciona, desde a compilação do kernel até a criação de ferramentas básicas do sistema.

---

##  Objetivo do Projeto

O **Linux From Scratch** (LFS) é um projeto educacional que ensina como construir um sistema Linux completamente funcional a partir do código-fonte.  
Ao invés de usar uma distribuição pronta como Ubuntu ou Fedora, o usuário compila e configura **cada componente** — incluindo o compilador, o kernel e as bibliotecas fundamentais.

---

##  Estrutura do Projeto

O projeto está dividido em várias fases conforme o livro LFS:

| Etapa | Descrição |
|-------|------------|
| **1. Preparação do ambiente** | Criação de partições, montagem dos sistemas de arquivos e instalação dos pacotes necessários no sistema host. |
| **2. Construção das ferramentas temporárias** | Compilação de um toolchain independente (binutils, gcc, glibc, etc). |
| **3. Construção do sistema base** | Compilação dos pacotes principais dentro do ambiente chroot. |
| **4. Instalação do Kernel Linux** | Configuração e compilação do kernel personalizado. |
| **5. Configuração do Sistema** | Criação de scripts de inicialização, configuração de rede, timezone, e usuários. |
| **6. Finalização e boot** | Instalação do GRUB e teste do sistema finalizado. |

---

##  Especificações da Máquina Utilizada

A compilação do LFS foi feita em um computador com recursos bastante limitados, o que tornou o processo desafiador e educativo.  
As especificações do hardware são as seguintes:

| Componente | Especificação |
|-------------|----------------|
| **Processador** | AMD C C-60 Dual Core, 1 GHz |
| **Núcleos de CPU** | 2 |
| **Memória RAM** | 4 GB DDR3-SDRAM |
| **Armazenamento** | HDD 500 GB |
| **Placa Gráfica** | AMD Radeon HD 6290 |
| **Tela** | 14" (1366x768) LED, 16:9 |
| **Rede** | Ethernet LAN 10/100 Mbit/s |
| **Drive óptico** | DVD-RW |

---

##  Sistema Host

- **Distribuição base:** Lubuntu (última versão estável no momento da instalação)  
- **Motivo da escolha:** O Lubuntu foi escolhido por ser uma distribuição **leve e eficiente**, ideal para hardware com capacidade de processamento limitada.  
- **Ambiente gráfico:** LXQt  
- **Kernel do host:** Versão incluída na release estável do Lubuntu  

---

##  Ferramentas e Tecnologias Utilizadas

- **Sistema Host:** Lubuntu 24.04 LTS Released
- **Kernel compilado:** Linux 6.16.1
- **Toolchain:** Binutils, GCC, Glibc
- **Gerenciamento de Pacotes:** Manual (sem apt ou yum)
- **Filesystem:** ext4
- **Editor:** Vim / Nano
- **Ambiente:** Chroot isolado

---

##  Decisões Técnicas Importantes

- Para a compilação, foi utilizado o comando:

  ```bash
  make -j1
  ```
Essa configuração limitou o processo de compilação a apenas um núcleo do processador, priorizando estabilidade e reduzindo o risco de falhas em um sistema com pouca capacidade de processamento.

A partir do Capítulo 8 (na instalação do GCC), os testes de compilação descritos no livro não foram executados, devido ao tempo excessivo que eles demandavam na máquina utilizada.

O restante do processo (compilação, instalação e configuração) foi seguido conforme as instruções oficiais do livro LFS, com pequenas pausas para evitar superaquecimento do processador.

---

##  Pré-requisitos

Antes de começar:

- Conhecimentos básicos de **Linux e linha de comando**
- No mínimo **8 GB de RAM** e **50 GB de espaço livre**
- Um sistema Linux funcionando (para servir de host)
- A versão do livro LFS (recomenda-se a mais recente, ex: 12.4)

---

##  Como Reproduzir

1. **Baixe o livro oficial LFS:**
   ```bash
   wget https://www.linuxfromscratch.org/lfs/downloads/stable/LFS-BOOK.html

---

##  Resultado Final

O LFS Pitbulls 12.4 foi compilado e inicializado com sucesso através do GRUB do Lubuntu.
Durante o boot, o kernel 6.16.1 carrega corretamente, monta as partições conforme o fstab e inicia o sistema base sem erros críticos.
Este resultado confirma o sucesso do processo de compilação e configuração manual de um sistema Linux completamente funcional, construído do zero.

Data de finalização do projeto 08/11/2025

---

##  Aprendizados e Desafios

- Compreensão detalhada do funcionamento interno de um sistema Linux.
- Experiência com compilação manual de pacotes e gerenciamento de dependências.
- Otimização de recursos em hardware limitado.
- Identificação de gargalos de performance durante a construção.
- Solução de problemas reais com bootloaders (GRUB) e tabelas GPT/BIOS.
- Prática com chroot, toolchain cross-compilation, e configuração de kernel.

---

##  Referências

-  Linux From Scratch – Livro Oficial
-  Beyond Linux From Scratch (BLFS)
-  LFS Hints
-  Fórum da Comunidade LFS

---

## Licença

Este projeto segue a licença MIT — sinta-se livre para usar, modificar e compartilhar, desde que mantenha os créditos.

---

Autores

Maycon de Sousa Palácio
Afonso Rafael Evangelista da Silva
Ruan Lopes Dourado
Filipe Augusto Izidro de Melo
André Luidhy Menezes Barbosa
Estudantes de Ciências da Computação
📧 Contato: maycondesousapalacio@gmail.com