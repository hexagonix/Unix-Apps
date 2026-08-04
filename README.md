<p align="center">
<img src="https://raw.githubusercontent.com/hexagonix/Doc/refs/heads/main/Img/banner.png">
</p>

<div align="center">

![](https://img.shields.io/github/license/hexagonix/Unix-Apps.svg)
![](https://img.shields.io/github/stars/hexagonix/Unix-Apps.svg)
![](https://img.shields.io/github/issues/hexagonix/Unix-Apps.svg)
![](https://img.shields.io/github/issues-closed/hexagonix/Unix-Apps.svg)
![](https://img.shields.io/github/issues-pr/hexagonix/Unix-Apps.svg)
![](https://img.shields.io/github/issues-pr-closed/hexagonix/Unix-Apps.svg)
![](https://img.shields.io/github/downloads/hexagonix/Unix-Apps/total.svg)
![](https://img.shields.io/github/release/hexagonix/Unix-Apps.svg)
[![](https://img.shields.io/twitter/follow/hexagonixOS.svg?style=social&label=Follow%20%40HexagonixOS)](https://twitter.com/hexagonixOS)

</div>

<!-- Vai funcionar como <hr> -->

<img src="https://github.com/hexagonix/Doc/blob/main/Img/hr.png" width="100%" height="2px" />

# Apps Unix-like do Hexagonix/Hexagonix Unix-like apps

<details title="Português (Brasil)" align='left'>
<summary align='left'>🇧🇷 Português (Brasil)</summary>
<br>

# Aplicativos e utilitários do Hexagonix

<div align="justify">

Este repositório contém os aplicativos e utilitários padrão do Hexagonix.

</div>

## Utilitários incluidos

<div align="justify">

Diversos utilitários no padrão Unix estão incluídos até o momento.

</div>

### Utilitários no padrão Unix

<div align="justify">

#### adduser

Cria interativamente uma nova conta de usuário no sistema. Restrito ao usuário root, solicita o nome do novo usuário, a senha, o shell e o tema, e cria o registro correspondente.

#### arch

Exibe a arquitetura do sistema e dispositivo.

#### cat

Envia o conteúdo de um arquivo para o console.

#### clear

Limpa o conteúdo do console principal e dos consoles virtuais.

#### cowsay

Exibe uma mensagem ao usuário através de uma entidade (por padrão, uma vaca), que pode ser alterada antes da mensagem.

#### cp

Copia o conteúdo de um arquivo para outro, exigindo um nome de arquivo de entrada e um de saída.

#### date

Exibe a data e a hora do sistema.

#### deluser

Remove uma conta de usuário existente.

#### echo

Envia o conteúdo de uma mensagem para o console.

#### file

Obtêm informações sobre um arquivo e as envia para o console.

#### free

Exibe informações sobre o uso de memória do sistema.

#### hostname

Exibe o nome de rede definido para este dispositivo.

#### init

Primeiro processo iniciado pelo Hexagon (PID 1). Lê o arquivo de configuração `/rc`, prepara os consoles do sistema e inicia, monitora ou reinicia os processos nele descritos.

#### kill

Encerra o processo identificado pelo PID informado.

#### login

Autentica um usuário registrado e inicia sua sessão.

#### ls

Lista e exibe os arquivos presentes no volume atual, ordenados por tipo.

#### man

Exibe a ajuda detalhada dos utilitários Unix instalados.

#### mount

Monta um volume em um ponto de montagem do sistema de arquivos. Sem parâmetros, exibe os pontos de montagem existentes.

#### mv

Renomeia um arquivo.

#### passwd

Altera a senha do usuário atualmente logado. O usuário root também pode alterar a senha de outro usuário, sem precisar conhecer a senha atual dele.

#### ps

Exibe informações sobre os processos em execução, bem como o uso de memória e demais recursos do sistema.

#### rm

Solicita a remoção de um arquivo do volume atual.

#### sh

Inicia um shell Unix para o usuário atual, o shell padrão do Hexagonix.

#### shutdown

Desliga ou reinicia o computador.

#### su

Troca a sessão atual para outro usuário registrado.

#### syslogd

Envia mensagens de componentes e utilitários do Hexagonix para o log do sistema.

#### top

Exibe os processos carregados no sistema, filtrando os processos do próprio kernel.

#### uname

Exibe informações do sistema, como nome, versão e arquitetura.

#### whoami

Exibe o nome do usuário atualmente logado no sistema.

</div>

### Utilitários exclusivos do Hexagonix

<div align="justify">

#### clock

Exibe o horário atual no canto superior direito do console, atualizado a cada segundo. Pensado para ser executado em segundo plano, com `clock &`.

#### fnt

Altera a fonte gráfica utilizada pelo console.

#### hash

Shell alternativo ao sh, com funcionamento semelhante.

#### logind

Daemon responsável por administrar o ciclo de login em cada terminal virtual, chamando login e reabrindo a sessão quando o shell do usuário é encerrado.

#### lshapp

Obtêm e exibe informações de uma imagem HAPP.

#### lshmod

Obtêm informações de uma imagem ou módulo HBoot.

</div>

</details>

<details title="English" align='left'>
<summary align='left'>🇬🇧 English</summary>
<br>

# Hexagonix apps and utilities

<div align="justify">

This repository contains the standard Hexagonix applications and utilities.

</div>

## Utilities included

<div align="justify">

Several Unix-standard utilities are included so far.

</div>

### Unix-standard utilities

<div align="justify">

#### adduser

Interactively creates a new user account on the system. Restricted to the root user, it asks for the new username, password, shell and theme, and creates the corresponding record.

#### arch

Displays the architecture of this system and device.

#### cat

Sends the contents of a file to the console.

#### clear

Clears the contents of the main console and the virtual consoles.

#### cowsay

Displays a message to the user through an entity (a cow, by default), which can be changed before the message.

#### cp

Copies the contents of one file into another, requiring an input filename and an output filename.

#### date

Displays the system date and time.

#### deluser

Removes an existing user account.

#### echo

Sends the contents of a message to the console.

#### file

Retrieves information about a file and sends it to the console.

#### free

Displays information about system memory usage.

#### hostname

Displays the network name defined for this device.

#### init

The first process started by Hexagon (PID 1). It reads the `/rc` configuration file, sets up the system consoles, and starts, monitors or respawns the processes described in it.

#### kill

Terminates the process identified by the given PID.

#### login

Authenticates a registered user and starts their session.

#### ls

Lists and displays the files present on the current volume, sorted by type.

#### man

Displays detailed help for installed Unix utilities.

#### mount

Mounts a volume onto a file system mount point. With no parameters, displays the existing mount points.

#### mv

Renames a file.

#### passwd

Changes the currently logged in user's own password. The root user can also change another user's password without knowing their current one.

#### ps

Displays information about running processes, as well as memory and other system resource usage.

#### rm

Requests the removal of a file from the current volume.

#### sh

Starts a Unix shell for the current user, Hexagonix's default shell.

#### shutdown

Powers off or reboots the computer.

#### su

Switches the current session to another registered user.

#### syslogd

Sends messages from Hexagonix components and utilities to the system log.

#### top

Displays the processes loaded on the system, filtering out the kernel's own processes.

#### uname

Displays system information, such as name, version and architecture.

#### whoami

Displays the name of the user currently logged into the system.

</div>

### Hexagonix-exclusive utilities

<div align="justify">

#### clock

Shows the current time in the console's top-right corner, refreshed every second. Meant to be run in the background, with `clock &`.

#### fnt

Changes the graphic font used by the console.

#### hash

An alternate shell to sh, with similar behavior.

#### logind

Daemon responsible for managing the login cycle on each virtual terminal, calling login and reopening the session once the user's shell exits.

#### lshapp

Reads and displays information from a HAPP image.

#### lshmod

Reads information from an HBoot image or module.

</div>

</details>

<details title="Unix utilities License" align='left'>
<summary align='left'>Licença dos utilitários Unix/Unix Utilities License</summary>
<br>

<div align="justify">

Hexagonix Operating System

BSD 3-Clause License

Copyright (c) 2015-2026, Felipe Miguel Nery Lunkes<br>
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

</div>

</details>

<!--

Versão deste arquivo: 1.0

-->
