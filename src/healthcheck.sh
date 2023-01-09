#!/bin/bash
variable_file="${STEAM_BACKUPDIR}/store.json"
json_tmp='{"daily":{"last_bak_ts":0,"bak_list":[]},"hourly":{"last_bak_ts":0,"bak_list":[]},"players":{"last_count":0}}'

## Get json values function
function get_json {
  echo "$(jq "${1}" "${variable_file}")"
}

## Set json values function
function set_json {
  echo "$(jq "${1} = ${2}" "${variable_file}")" > "${variable_file}"
}

## Add to json array
function array_add {
  echo "$(jq "${1} += [\"${2}\"]" "${variable_file}")" > "${variable_file}"
}

## Remove last element of json array
function rm_array_last {
  echo "$(jq "del(${1} | last)" "${variable_file}")" > "${variable_file}"
}

## Remove first element of array json
function rm_array_first {
  echo "$(jq "del(${1} | first)" "${variable_file}")" > "${variable_file}"
}

## Get first element of array json
function array_first {
  echo "$(jq -r "${1} | first" "${variable_file}")"
}

## Get last element of array json
function array_last {
  echo "$(jq -r "${1} | last" "${variable_file}")"
}

## Get json array size
function array_size {
  echo "$(jq -r "${1} | length" "${variable_file}")"
}

## Check if file exists else create it
if [ ! -s "${variable_file}" ]; then
  echo "File does not exist"
  echo "$(echo "${json_tmp}" | jq '' )" > "${variable_file}"
fi

## Define script variables from store.json
last_hourly_backup=$(get_json '.hourly.last_bak_ts')
last_daily_backup=$(get_json '.daily.last_bak_ts')
players_last_count=$(get_json '.players.last_count')

## Hourly backup function
function hourly_backup {
  echo "Running hourly backup"
  # Check if an hour has passed since last backup
  if [ $(( $(date +'%s') - $last_hourly_backup )) -gt 3600 ]; then
    echo "Hour has passed"
    # Call backup script and save timestamp
    ts=$(date +'%s')
	fname="backup_$(date -d @${ts} +'%Y-%m-%d_%H:%M:%S').tar.gz"
    echo "Calling backup script with filename of ${fname}"
	/bin/bash "${HOME}/backup.sh" "${STEAM_BACKUPDIR}/${fname}"
	if [ $? -eq 0 ]; then
		set_json ".hourly.last_bak_ts" "${ts}"
		# If backup count larger than setting remove oldest backup
		if [ $(array_size ".hourly.bak_list") -ge ${BACKUP_HOURLY_LIM} ]; then
		  echo "deleting backup $(array_first ".hourly.bak_list")"
		  rm -rf "${STEAM_BACKUPDIR}/$(array_first ".hourly.bak_list")"
		  rm_array_first ".hourly.bak_list"
		fi
		echo "Adding to backup list with value \"${fname}\""
		array_add ".hourly.bak_list" "${fname}"
	fi
  else
    echo "Less than an hour ago"
  fi
  update_exit
}

## Daily backup function
function daily_backup {
  echo "Running daily backup"
  # Check if last player count is more than 0
  if [ $players_last_count -gt 0 ]; then
    echo "Last Player count greater than 0"
    # If date for last backup is same as current date delete old backup and remove from list
    if [ "$(date +'%Y%m%d')" -le "$(date -d @${last_daily_backup} +'%Y%m%d')" ]; then
      echo "Same day delete old backup"
      echo "deleting backup $(array_last ".daily.bak_list")"
	  rm -rf "${STEAM_BACKUPDIR}/$(array_last ".daily.bak_list")"
      rm_array_last ".daily.bak_list"
    fi
  
    # Call backup script and save timestamp
    ts=$(date +'%s')
	fname="backup_$(date -d @${ts} +'%Y-%m-%d_%H:%M:%S').tar.gz"
    echo "Calling backup script with filename of ${fname}"
	/bin/bash "${HOME}/backup.sh" "${STEAM_BACKUPDIR}/${fname}"
	if [ $? -eq 0 ]; then
		set_json ".daily.last_bak_ts" "${ts}"
	  
		# If backup count larger than setting remove oldest backup
		if [ $(array_size ".daily.bak_list") -ge ${BACKUP_DAILY_LIM} ]; then
		  echo "deleting backup $(array_first ".daily.bak_list")"
		  rm -rf "${STEAM_BACKUPDIR}/$(array_first ".daily.bak_list")"
		  rm_array_first ".daily.bak_list"
		fi
		echo "Adding to backup list with value \"${fname}\""
		array_add ".daily.bak_list" "${fname}"
	fi
  else
    echo "Last Player count is 0"
  fi
  update_exit
}

## Function to update json and exit
function update_exit {
  set_json ".players.last_count" "${online_players}"
  exit 0
}

## Test if server is offline or online
if output=$("${PWD}/ssq" 127.0.0.1 ${QUERY_PORT} 2> /dev/null); then
#if output=$(cat ssq.txt); then
  ## If server is online
  online_players=$(echo "$output" | \
                  grep Players........: | \
                  sed 's/^.*:\(\s.*\)\/.*$/\1/')
  if [ $online_players -gt 0 ]; then
    # Run hourly backup
    hourly_backup
  else
    # Run daily backup 
    daily_backup
  fi
else
  ## If server is offline
  echo "Server is offline"
  exit 1
fi