# 🐧 Linux From Scratch (LFS)

Este projeto documenta a construção de um sistema Linux completamente do zero, seguindo o livro **[Linux From Scratch (LFS)](https://www.linuxfromscratch.org/)**.  
O objetivo é compreender em profundidade como um sistema Linux funciona, desde a compilação do kernel até a criação de ferramentas básicas do sistema.

---

## 📘 Objetivo do Projeto

O **Linux From Scratch** (LFS) é um projeto educacional que ensina como construir um sistema Linux completamente funcional a partir do código-fonte.  
Ao invés de usar uma distribuição pronta como Ubuntu ou Fedora, o usuário compila e configura **cada componente** — incluindo o compilador, o kernel e as bibliotecas fundamentais.

---

## ⚙️ Estrutura do Projeto

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

## 🧰 Ferramentas e Tecnologias Utilizadas

- **Sistema Host:** Ubuntu 24.04 LTS (ou similar)
- **Kernel:** Linux 6.x
- **Toolchain:** Binutils, GCC, Glibc
- **Gerenciamento de Pacotes:** Manual (sem apt ou yum)
- **Filesystem:** ext4
- **Editor:** Vim / Nano
- **Ambiente:** Chroot isolado

---

## 💡 Pré-requisitos

Antes de começar:

- Conhecimentos básicos de **Linux e linha de comando**
- No mínimo **8 GB de RAM** e **50 GB de espaço livre**
- Um sistema Linux funcionando (para servir de host)
- A versão do livro LFS (recomenda-se a mais recente, ex: 12.2)

---

## 🚀 Como Reproduzir

1. **Baixe o livro oficial LFS:**
   ```bash
   wget https://www.linuxfromscratch.org/lfs/downloads/stable/LFS-BOOK.html
