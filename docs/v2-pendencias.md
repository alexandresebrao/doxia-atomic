# DoxIA 2: o que falta

Estado em 2026-10-23, logo depois de importar a v1 (`build/v1/IMPORTED_FROM`).

## Nunca testado

- Boot da imagem: greetd + doxia-greeter (rótulos SELinux de
  `/usr/libexec/doxia-greeter-session`), sessão mango via uwsm, doxia-shell
  como unit global, `doxia-setup-user.service` antes da sessão.
- ISO: o kickstart com `ostreecontainer`, o `%post` rodando
  `lib/setup-user` dentro da implantação, o caminho do log que o assistente
  lê (`/mnt/sysroot/ostree/deploy/default/var/log/doxia-install.log`) e a
  barra do download (bytes recebidos pela rede contra o tamanho das camadas
  no registry, porque o `ostree container image deploy` não informa
  progresso ao Anaconda).
- Atualizar com bootc: os campos de `rpm-ostree status --json`
  (`container-image-reference`, `-digest`, `staged`), o formato da saída de
  `bootc upgrade` para a barra de progresso e o texto de `rpm-ostree db diff`.
- Chrome em `/usr/lib/google` com o link de `/var/opt/google` (tmpfiles).

## Reescrever (curadoria: "reescrever")

- `doxia-debug`: envia o log para logs.doxia.org, que não existe.
- `doxia-system-factory-reset` e `-finish`: são do Arch (limine,
  `install/provisioning`); o equivalente no bootc é reinstalar a imagem
  e limpar `/etc` e `/var`.
- `doxia-plymouth-set`, `doxia-hibernation-setup` e `-available`: escrevem
  em `/usr` ou no initramfs, que agora vêm da imagem (kargs com
  `bootc kargs`/`kargs.d`).
- `doxia-setup-security-fingerprint`, `doxia-default-agent`,
  `doxia-version` e `-pkgs`: usam `dnf`/`rpm` para instalar ou listar.

## Ainda usam dnf

`doxia-pkg-*` (add, drop, install, remove, present, missing, aur-add),
`doxia-voxtype-install`, `doxia-migrate`, `lib/greeting.sh`. No sistema
imutável, um app vira Flatpak, uma ferramenta vai para toolbox ou mise, e
um pacote que todo mundo precisa entra em `build/steps/20-packages.sh`.

## Outros

- Tema do GRUB: o bootupd gerencia o GRUB e o tema da v1
  (`build/v1/install-grub-theme`) não se aplica como era.
- `doxia/etc`: sobra do Arch (limine, mkinitcpio, docker, pacman). Só
  `xdg/kitty` e `sudoers.d` são usados.
- `rs/README.md` e o código de convivência com o Quickshell
  (`rs/shell/src/quickshell.rs`).
- `test/`: a suíte ainda supõe o checkout da v1.
- `docs/`: a documentação ainda descreve a v1.
- Migrações por usuário depois de uma imagem nova: `doxia-migrate` procura
  `$DOXIA_PATH/migrations`, que a v2 ainda não tem.
- Publicação: o pacote no ghcr.io público e
  a chave do cosign (`SIGNING_SECRET`).
