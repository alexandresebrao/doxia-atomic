# DoxIA 2

DoxIA on Fedora Atomic: a bootc image built on Universal Blue's `base-main`,
with the mango compositor, the DoxIA shell and apps in Rust + GTK 4, and
nothing left of Omarchy but its history. DoxIA 1 (the `fedora` branch of
alexandresebrao/DoxIA, a script install on a regular Fedora) was imported at
the commit in `build/v1/IMPORTED_FROM`.

## How it fits together

| Path | Becomes | What |
| --- | --- | --- |
| `Containerfile` | the image | Rust stage (`rs/`), then `base-main` + `build/` + `system/` + `doxia/` |
| `doxia/` | `/usr/share/doxia` (`$DOXIA_PATH`) | commands (`bin/`, linked into `/usr/bin`), defaults, configs, themes, `lib/` (DoxIA's own scripts, plugins, assets) |
| `rs/` | `/usr/bin/doxia-*` | doxia-shell, doxia-greeter, doxia-atualizar, doxia-painel, doxia-freeze |
| `system/` | `/` | files the image owns outright: units, udev, tmpfiles, D-Bus |
| `build/steps/` | (build only) | what `install-system.sh` did: RPMs (`build/rpms.lock`), packages, Chrome, branding, services |
| `packages/` | release assets | specs of the RPMs DoxIA patches (mango, scenefx, wlroots, uwsm, gpu-screen-recorder) |
| `iso/` | installer ISO | the DoxIA wizard in front of Anaconda, which deploys the image (`ostreecontainer`) |

Per account, `doxia/lib/setup-user` (DoxIA 1's `install-user.sh`) seeds
`~/.config`, the theme, fonts, zsh, Chrome, Claude Code and Voxtype. The
installer runs it for the account it creates; any other account gets it on
its first login, behind a "Preparando sua conta" screen with the steps and a
progress bar (`doxia-setup-user.service`, `lib/setup-screen`, `doxia-greeter
--setup`). Downloads that failed are retried once the session is up
(`doxia-setup-retry.service`).

## Updates

The Atualizar window and `doxia-update` run `bootc upgrade`: the new image
is downloaded and staged, and it starts on the next restart. The previous
one stays in the boot menu. Flatpak apps and mise tools update right away.
`doxia-update-check` compares the booted image with the registry.

Nothing is installed into the system at runtime: apps come from Flatpak,
development tools from SDKMAN!, nvm and mise in `$HOME`, and anything else
from a toolbox. What every machine needs goes into the image.

## Build

```bash
just build        # podman build -t localhost/doxia .
just qcow2        # a VM disk from the local image (bootc-image-builder)
just iso          # the installer ISO (needs lorax, root)
```

CI (`.github/workflows/build.yml`) builds every push to `main` and daily,
publishes `ghcr.io/alexandresebrao/doxia-atomic:latest` and signs it when the
`SIGNING_SECRET` secret holds a cosign key.

To move a test machine onto a local build: `sudo bootc switch --transport
containers-storage localhost/doxia`.
