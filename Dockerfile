FROM steamcmd/steamcmd:ubuntu-24

LABEL maintainer="silent@silentmecha.co.za"

ARG PUID=1001
ARG DEBIAN_FRONTEND=noninteractive

# Runtime configuration
# These defaults are inherited by child images.
ENV USER=steam
ENV HOME="/home/${USER}"

ENV AUTO_UPDATE=False

# Shared runtime data used for IPC, health monitoring and logs.
ENV SHARED_DATA="/srv/silentmecha"
ENV EVENTS_FIFO="${SHARED_DATA}/events.out"
ENV CONTROL_FIFO="${SHARED_DATA}/control.out"
ENV LOG_FILE="${SHARED_DATA}/server.log"

# Global save-data location.
# Child images should map game-specific save locations into this directory.
ENV STEAM_SAVEDIR="${HOME}/save-data"

# Agent heartbeat configuration.
ENV HEARTBEAT_INTERVAL=5
ENV HEARTBEAT_TIMEOUT=7

# Create service user.
# Dedicated game servers should not run as root.
RUN set -x \
    && useradd -u "${PUID}" -m "${USER}"

# Install common utilities used by game server images.
# gettext-base provides envsubst for template rendering.
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        nano \
        curl \
        wget \
        jq \
        tzdata \
        rename \
        gettext-base \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Set working directory.
WORKDIR "${HOME}"

COPY ./src/ssq "${HOME}/ssq"
COPY ./src/healthcheck.sh "${HOME}/healthcheck.sh"

# Create persistent save-data directory.
RUN set -x \
    && mkdir -p "${STEAM_SAVEDIR}" \
    && chown "${USER}:${USER}" "${STEAM_SAVEDIR}" \
    && chmod 775 "${STEAM_SAVEDIR}"

# Create shared runtime directory and IPC resources.
RUN set -x \
    && mkdir -p "${SHARED_DATA}" \
    && mkfifo "${EVENTS_FIFO}" \
    && touch "${LOG_FILE}" \
    && chown "${USER}:${USER}" \
        "${HOME}/ssq" \
        "${HOME}/healthcheck.sh" \
        "${SHARED_DATA}" \
        "${EVENTS_FIFO}" \
        "${LOG_FILE}" \
    && chmod 700 -R "${SHARED_DATA}" \
    && chmod +x "${HOME}/ssq" "${HOME}/healthcheck.sh"

# Expose persistent storage locations.
VOLUME ["/srv/silentmecha"]
VOLUME ["/home/steam/save-data"]

USER "${USER}"

# Update SteamCMD and verify installation.
RUN steamcmd +quit

# Create compatibility symlinks expected by some dedicated servers.
RUN mkdir -p "${HOME}/.steam" \
    && ln -s "${HOME}/.local/share/Steam/steamcmd/linux32" "${HOME}/.steam/sdk32" \
    && ln -s "${HOME}/.local/share/Steam/steamcmd/linux64" "${HOME}/.steam/sdk64" \
    && ln -s "${HOME}/.steam/sdk32/steamclient.so" "${HOME}/.steam/sdk32/steamservice.so" \
    && ln -s "${HOME}/.steam/sdk64/steamclient.so" "${HOME}/.steam/sdk64/steamservice.so"

# Default container behaviour.
# Child images are expected to override these values.
ENTRYPOINT []

CMD ["/bin/bash"]
