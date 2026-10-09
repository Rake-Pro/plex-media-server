# syntax=docker/dockerfile:1

FROM docker.io/library/ubuntu:26.04

# Defaults for local builds; you can override with --build-arg
ARG TARGETARCH=amd64
ARG VENDOR="rakepro"
# renovate: datasource=custom.plex depName=plex versioning=loose
# https://downloads.plex.tv/plex-media-server-new/1.43.5.11029-6bf8af3f0/debian/plexmediaserver_1.43.5.11029-6bf8af3f0_amd64.deb
ARG VERSION="1.43.5.11029-6bf8af3f0"


# NVIDIA & Plex environment
ENV DEBIAN_FRONTEND="noninteractive" \
    TZ="Etc/UTC" \
    NVIDIA_VISIBLE_DEVICES="all" \
    NVIDIA_DRIVER_CAPABILITIES="compute,video,utility" \
    PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR="/config/Library/Application Support" \
    PLEX_MEDIA_SERVER_HOME="/usr/lib/plexmediaserver" \
    PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS="6" \
    PLEX_MEDIA_SERVER_INFO_VENDOR="Docker" \
    PLEX_MEDIA_SERVER_INFO_DEVICE="Docker Container (${VENDOR})"

LABEL org.opencontainers.image.source="https://github.com/Rake-Pro/plex-media-server"

USER root
WORKDIR /app

# Re-declare ARGs after FROM so they're available in RUN
ARG TARGETARCH=amd64

RUN \
    apt-get update && \
    # Pull distro security updates for the pinned ubuntu:26.04 layer (Trivy
    # rescan 2026-10-05: openssl 3.5.5-1ubuntu3.5 -> 3.5.5-1ubuntu3.6).
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        bash \
        ca-certificates \
        catatonit \
        coreutils \
        curl \
        jq \
        nano \
        tzdata \
        uuid-runtime \
        xmlstarlet \
        pciutils \
        vainfo \
        mesa-va-drivers && \
    # Intel VA driver is only available on amd64
    if [ "${TARGETARCH}" = "amd64" ]; then \
        apt-get install -y --no-install-recommends intel-media-va-driver-non-free; \
    fi && \
    curl -fsSL -o /tmp/plex.deb \
        "https://downloads.plex.tv/plex-media-server-new/${VERSION}/debian/plexmediaserver_${VERSION}_${TARGETARCH}.deb" && \
    dpkg -i /tmp/plex.deb && \
    chmod -R 755 "${PLEX_MEDIA_SERVER_HOME}" && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /etc/default/plexmediaserver /tmp/* /var/lib/apt/lists/* /var/tmp/ && \
    # pebble is an unpackaged Go binary baked into the ubuntu base image; unused here (catatonit is PID 1)
    rm -f /usr/bin/pebble

# Copy entrypoint with an explicit executable mode so the bit can never be
# lost in git/checkout (the old image shipped it 644 -> catatonit EACCES).
COPY --chmod=0755 entrypoint.sh /entrypoint.sh

# Plex runs as nobody:nogroup and stores config in /config
USER nobody:nogroup
WORKDIR /config
VOLUME ["/config"]

ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]
