# 🐧 Instalação e Manutenção do Ubuntu e Linux Mint

Script Bash para automatizar a instalação de aplicativos, configurar repositórios, habilitar Flatpak e Snap, instalar extensões GNOME e executar tarefas de reparação e limpeza no Ubuntu e Linux Mint.

O objetivo é facilitar a preparação de um ambiente Linux completo, reunindo diversas tarefas de instalação e manutenção em um único script.

## 🚀 Funcionalidades

- **Atualização do sistema:** atualiza os índices do APT e executa a atualização dos pacotes instalados.
- **Instalação de aplicativos:** instala ferramentas, navegadores, utilitários e programas multimídia.
- **Suporte ao Flatpak:** configura o repositório Flathub e tenta instalar aplicativos disponíveis.
- **Suporte ao Snap:** habilita o serviço Snap quando necessário.
- **Navegadores:** configura os repositórios do Brave e do Google Chrome.
- **Acesso remoto:** tenta instalar o RustDesk em sistemas com arquitetura AMD64.
- **Extensões GNOME:** instala extensões disponíveis nos repositórios da distribuição.
- **Reparação de pacotes:** tenta corrigir dependências e concluir configurações pendentes do DPKG.
- **Limpeza do sistema:** remove pacotes considerados desnecessários e limpa caches do APT.
- **Limpeza do Flatpak e Snap:** remove runtimes Flatpak sem uso e revisões desativadas do Snap.
- **Limpeza de arquivos temporários:** limpa caches do usuário, arquivos da lixeira e registros antigos do sistema.
- **Verificação final:** executa verificações de pacotes e informa os próximos passos.

## 📦 Aplicativos contemplados

O script tenta instalar aplicativos e ferramentas como:

| Categoria | Aplicativos |
|---|---|
| Navegadores | Brave, Google Chrome |
| Multimídia | VLC, Clapper, Spotify |
| Edição de vídeo | Kdenlive |
| Imagens e design | GIMP, Inkscape, Upscaler |
| Comunicação | Telegram, Discord |
| Segurança | Bitwarden, GUFW |
| Acesso remoto | RustDesk |
| Produtividade | CopyQ, Shortwave |
| Virtualização | GNOME Boxes |
| Jogos | Steam, Sober |
| Administração | Synaptic, GDebi |
| Personalização | GNOME Tweaks, Extension Manager, Dconf Editor |
| Manutenção | BleachBit e ferramentas do sistema |

**Observação:** a disponibilidade dos aplicativos depende dos repositórios, da versão do sistema e do método de instalação. Alguns pacotes podem não estar disponíveis, e o script informa ou ignora determinadas falhas para continuar a execução.

## 💻 Requisitos

- Ubuntu ou Linux Mint.
- Conta de usuário com privilégios administrativos via `sudo`.
- Conexão com a internet.
- Espaço em disco suficiente para os aplicativos e atualizações.
- Sessão gráfica GNOME recomendada, especialmente para as extensões.
- Arquitetura AMD64 para a tentativa de instalação do pacote RustDesk incluída no script.

## 📥 Instalação

Clone o repositório:

```bash
git clone https://github.com/SEU-USUARIO/instalacao-ubuntu-mint.git
```

Entre na pasta do projeto:

```bash
cd instalacao-ubuntu-mint
```

Dê permissão de execução ao script:

```bash
chmod +x instalacao-ubuntu-mint.sh
```

## ▶️ Como executar

Execute o script com seu usuário normal:

```bash
./instalacao-ubuntu-mint.sh
```

Digite sua senha quando o `sudo` solicitar autorização administrativa.

**Importante:** não execute o script como `root` e não utilize `sudo` antes do nome do arquivo. O próprio script solicita a autorização administrativa no início e tenta manter a sessão autorizada durante a execução.

## ⚠️ Avisos importantes

Antes de executar, leia estas recomendações:

1. **Faça backup:** mantenha uma cópia dos seus arquivos importantes.
2. **Revise as alterações:** o script executa atualizações do sistema, instala aplicativos, configura repositórios e remove pacotes considerados desnecessários.
3. **Atenção à limpeza:** a rotina apaga o conteúdo da lixeira e limpa caches temporários. Isso pode remover arquivos que você ainda desejava recuperar ou dados temporários de aplicativos.
4. **Repositórios externos:** são configuradas fontes de software de terceiros, incluindo Brave e Google Chrome.
5. **Compatibilidade:** o script foi projetado para Ubuntu e Linux Mint. O funcionamento de pacotes e extensões varia conforme a versão instalada.
6. **GDM3:** o script não solicita a instalação do GDM3, mas isso não representa uma garantia absoluta contra alterações indiretas de dependências ou de outros componentes do sistema.
7. **Execução por sua conta:** revise o código antes de executá-lo em computadores de produção.

## 🔧 Manutenção executada

Além de instalar aplicativos, o script realiza tarefas de manutenção, incluindo:

- Atualização e limpeza do APT.
- Tentativa de reparação de pacotes e dependências.
- Remoção de pacotes não utilizados.
- Limpeza de caches do navegador sem apagar deliberadamente senhas, favoritos ou perfis completos.
- Remoção de revisões desativadas do Snap.
- Remoção de runtimes Flatpak sem uso.
- Limpeza de registros antigos do sistema.

Essas operações não substituem backups nem uma análise individual de problemas de desempenho.

## 🔄 Após a execução

O script recomenda reiniciar o computador para aplicar as atualizações:

```bash
sudo reboot
```

Salve seus arquivos e feche os programas antes de reiniciar.

## 🛠️ Tecnologias utilizadas

- Bash Shell Script
- APT / DPKG
- Flatpak / Flathub
- Snap
- Systemd
- GNOME Shell

## 🤝 Contribuições

Sugestões, correções e melhorias são bem-vindas.

Para contribuir:

1. Faça um fork do projeto.
2. Crie uma branch para sua alteração.
3. Teste as modificações em um ambiente adequado.
4. Envie um Pull Request com a descrição das mudanças.

## 📄 Licença

Este projeto ainda não declara uma licença específica. Antes de redistribuí-lo, escolha e adicione um arquivo `LICENSE` com os termos de uso e distribuição desejados.

---

**Projeto de automação Linux:** instalação de aplicativos e manutenção do Ubuntu e Linux Mint em um único script Bash.
