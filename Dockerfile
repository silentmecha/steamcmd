FROM steamcmd/steamcmd:ubuntu-24

LABEL maintainer="silent@silentmecha.co.za"
ARG PUID=1001

# Set environment variables
ENV USER=steam
ENV BACKUP_DAILY_LIM=5
ENV BACKUP_HOURLY_LIM=5
ENV AUTO_UPDATE=False

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

RUN set -x \
	&& chown ${USER}:${USER} "${HOME}/ssq" "${HOME}/healthcheck.sh" \
	&& chmod +x "${HOME}/ssq" "${HOME}/healthcheck.sh"

USER ${USER}

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