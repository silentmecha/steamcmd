FROM ubuntu:latest

LABEL maintainer="silent@silentmecha.co.za"
ARG PUID=1000

ENV USER steam
ENV HOME "/home/${USER}"
ENV BACKUP_DAILY_LIM 5
ENV BACKUP_HOURLY_LIM 5

ARG DEBIAN_FRONTEND=noninteractive

# Insert Steam prompt answers
# Install, update & upgrade packages
# Create user for the server
# This also creates the home directory we later need
# Update the repository and install SteamCMD
# Clean TMP, apt-get cache and other stuff to make the image smaller
# Add unicode support
# Update SteamCMD and verify latest version

RUN echo steam steam/question select "I AGREE" | debconf-set-selections \
	&& echo steam steam/license note '' | debconf-set-selections

RUN set -x \
	&& useradd -u "${PUID}" -m "${USER}" \
	&& dpkg --add-architecture i386 \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		locales \
		libc6 \
		libstdc++6 \
		ca-certificates \
		nano \
		curl \
		wget \
        steamcmd \
		jq \
		tzdata \
	&& apt-get autoremove -y \
	&& rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG 'en_US.UTF-8'
ENV LANGUAGE 'en_US:en'

RUN ln -s /usr/games/steamcmd /usr/bin/steamcmd

WORKDIR ${HOME}

RUN su "${USER}" -c \
    "steamcmd +quit"

COPY ./src/ssq ${HOME}/ssq

COPY ./src/healthcheck.sh ${HOME}/healthcheck.sh

USER ${USER}
