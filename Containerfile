# DoxIA 2: Fedora Atomic (bootc) image with the mango session, the DoxIA
# shell and apps. Built by .github/workflows/build.yml and `just build`.
#
#   podman build -t doxia .
#
# Machines follow the published image with `bootc upgrade` (the Atualizar
# window): the new image is staged and boots on the next restart, and the
# previous one stays in the boot menu as the rollback.

ARG FEDORA=44

# The Rust + GTK 4 apps (rs/): doxia-shell, doxia-greeter, doxia-atualizar,
# doxia-painel, doxia-freeze. Built here instead of downloaded, so the image
# always carries the shell from the same commit.
FROM registry.fedoraproject.org/fedora:${FEDORA} AS rs
RUN dnf install -y --setopt=install_weak_deps=False \
      cargo rust gcc pkgconf-pkg-config jq \
      gtk4-devel gtk4-layer-shell-devel pango-devel cairo-devel glib2-devel pam-devel \
    && dnf clean all
COPY rs /src
WORKDIR /src
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/src/target \
    cargo build --release --locked \
    && mkdir /out \
    && cargo metadata --no-deps --format-version 1 \
       | jq -r '.packages[].targets[] | select(.kind | index("bin")) | .name' \
       | xargs -I{} install -m755 target/release/{} /out/{}

FROM ghcr.io/ublue-os/base-main:${FEDORA}

# The DoxIA 2 release (semver; -alpha/-beta/-rc until 1.0.0). The one place it
# is set: the image label (bootc status), os-release (build/steps/40-doxia.sh),
# the installer ISO (iso/build.sh) and the workflow's version tag read it here.
ARG DOXIA_VERSION=0.1.0-alpha
LABEL org.opencontainers.image.title="DoxIA" \
      org.opencontainers.image.version="${DOXIA_VERSION}"

COPY build /tmp/build
COPY system /
COPY doxia /usr/share/doxia
COPY --from=rs /out/ /usr/bin/

RUN --mount=type=cache,target=/var/cache/libdnf5 \
    bash /tmp/build/build.sh && \
    rm -rf /tmp/build && \
    bootc container lint
