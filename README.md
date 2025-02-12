[![Build Image](https://github.com/silentmecha/steamcmd/actions/workflows/build.yml/badge.svg)](https://github.com/silentmecha/steamcmd/actions/workflows/build.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/silentmecha/steamcmd.svg)](https://hub.docker.com/r/silentmecha/steamcmd)
[![Image Size](https://img.shields.io/docker/image-size/silentmecha/steamcmd/latest.svg)](https://hub.docker.com/r/silentmecha/steamcmd)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-donate-success?logo=buy-me-a-coffee&logoColor=white)](https://www.buymeacoffee.com/silent001)

# silentmecha/steamcmd

A base image of SteamCMD for downloading and running Steam game servers
and game server software. The image is built automatically every 6 hours with
[Github Actions](https://github.com/silentmecha/steamcmd/actions) and pushed to [Docker Hub](https://hub.docker.com/).

## Usage

### Pull latest image
```shell
docker pull silentmecha/steamcmd:latest
```
### Test interactively
```shell
docker run -it silentmecha/steamcmd:latest /bin/sh
```
### Download CSGO
```shell
docker run -it silentmecha/steamcmd:latest /bin/sh steamcmd +login anonymous +app_update 740 +quit
```
### Download CSGO to local mounted directory "data"
```shell
docker run -it -v $PWD:/data silentmecha/steamcmd:latest /bin/sh steamcmd +login anonymous +force_install_dir /data +app_update 740 +quit
```

## License

This project is licensed under the [MIT License](LICENSE).

If you enjoy this project and would like to support my work, consider [buying me a coffee](https://www.buymeacoffee.com/silent001). Your support is greatly appreciated!