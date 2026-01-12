FROM steamcmd/steamcmd:ubuntu-24

LABEL maintainer="silent@silentmecha.co.za"
ARG PUID=1001

# Set environment variables
ENV USER=steam
ENV AUTO_UPDATE=False
ENV SHARED_DATA="/srv/silentmecha"
ENV EVENTS_FIFO="${SHARED_DATA}/events.out"
ENV CONTROL_FIFO="${SHARED_DATA}/control.out"
ENV LOG_FILE="${SHARED_DATA}/server.log"
ENV HEARTBEAT_INTERVAL=5
ENV HEARTBEAT_TIMEOUT=7

# Create user for the server
# This also creates the home directory we later need
RUN set -x \
	&& useradd -u "${PUID}" -m "${USER}"

# Update the repository and install SteamCMD along with needed packages then
# Clean TMP, apt-get cache and other stuff to make the image smaller
ARG DEBIAN_FRONTEND=noninteractive
RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		nano \
		curl \
		wget \
		jq \
		tzdata \
		rename \
	&& apt-get autoremove -y \
	&& rm -rf /var/lib/apt/lists/*

# Change home directory later to fix symbolic link issues
ENV HOME="/home/${USER}"

# Set working directory
WORKDIR ${HOME}

COPY ./src/ssq ${HOME}/ssq

COPY ./src/healthcheck.sh ${HOME}/healthcheck.sh

# Create shared data directory, FIFO for events and log file
# Set ownerships and permissions
# Adjust permissions on home directory items
RUN set -x \
	&& mkdir -p "${SHARED_DATA}" \
	&& mkfifo "${EVENTS_FIFO}" \
	&& touch "${LOG_FILE}" \
	&& chown ${USER}:${USER} "${HOME}/ssq" "${HOME}/healthcheck.sh" "${SHARED_DATA}" "${EVENTS_FIFO}" "${LOG_FILE}" \
	&& chmod 700 -R "${SHARED_DATA}" \
	&& chmod +x "${HOME}/ssq" "${HOME}/healthcheck.sh"

USER ${USER}

# Expose shared data as volume
VOLUME ["${SHARED_DATA}"]

# Update SteamCMD and verify latest version
RUN steamcmd +quit

# Fix missing directories and libraries
RUN mkdir -p $HOME/.steam \
	&& ln -s $HOME/.local/share/Steam/steamcmd/linux32 $HOME/.steam/sdk32 \
	&& ln -s $HOME/.local/share/Steam/steamcmd/linux64 $HOME/.steam/sdk64 \
	&& ln -s $HOME/.steam/sdk32/steamclient.so $HOME/.steam/sdk32/steamservice.so \
	&& ln -s $HOME/.steam/sdk64/steamclient.so $HOME/.steam/sdk64/steamservice.so

ENTRYPOINT []

CMD ["/bin/bash"]