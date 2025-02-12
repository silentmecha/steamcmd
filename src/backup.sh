#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
	exit 1
fi

#${STEAM_BACKUPDIR}

( printf "saveworld\nexit\n" ) | telnet 127.0.0.1 8081
sleep 5
tar -czvf "${STEAM_BACKUPDIR}/${1}" "${STEAM_SAVEDIR}/Saves"