#!/bin/bash
bash "/usr/bin/steamcmd +force_install_dir ${SERVERDIR} +login anonymous +app_update 1007 validate +app_update 1963720 validate +quit"

echo "x1"

# Switch to workdir
cd "${SERVERDIR}"

echo "x2"
echo "${SERVERDIR}"

xvfbpid=""
ckpid=""

function kill_corekeeperserver {
        if [[ ! -z "$ckpid" ]]; then
                kill $ckpid
                wait $ckpid
        fi
        if [[ ! -z "$xvfbpid" ]]; then
                kill $xvfbpid
                wait $xvfbpid
        fi
}

trap kill_corekeeperserver EXIT

set -m

rm -f /tmp/.X99-lock

echo "x3"

Xvfb :99 -screen 0 1x1x24 -nolisten tcp &
xvfbpid=$!

# Wait for xvfb ready.
# Thanks to https://hg.mozilla.org/mozilla-central/file/922e64883a5b4ebf6f2345dfb85f04b487a0e714/testing/docker/desktop-build/bin/build.sh
retry_count=0
max_retries=2
xvfb_test=0
until [ $retry_count -gt $max_retries ]; do
    xvinfo
    xvfb_test=$?
    if [ $xvfb_test != 255 ]; then
        retry_count=$(($max_retries + 1))
    else
        retry_count=$(($retry_count + 1))
        echo "Failed to start Xvfb, retry: $retry_count"
        sleep 2
    fi done
  if [ $xvfb_test == 255 ]; then exit 255; fi

echo "x4"

rm -f GameID.txt

chmod +x ./CoreKeeperServer

echo "x5"

#Build Parameters
declare -a params
params=(-batchmode -logfile "CoreKeeperServerLog.txt" -datapath "${DATADIR}")
if [ ! -z "${WORLD_INDEX}" ]; then params=( "${params[@]}" -world "${WORLD_INDEX}" ); fi
if [ ! -z "${WORLD_NAME}" ]; then params=( "${params[@]}" -worldname "${WORLD_NAME}" ); fi
if [ ! -z "${WORLD_SEED}" ]; then params=( "${params[@]}" -worldseed "${WORLD_SEED}" ); fi
if [ ! -z "${WORLD_MODE}" ]; then params=( "${params[@]}" -worldmode "${WORLD_MODE}" ); fi
if [ ! -z "${GAME_ID}" ]; then params=( "${params[@]}" -gameid "${GAME_ID}" ); fi
if [ ! -z "${MAX_PLAYERS}" ]; then params=( "${params[@]}" -maxplayers "${MAX_PLAYERS}" ); fi
if [ ! -z "${SEASON}" ]; then params=( "${params[@]}" -season "${SEASON}" ); fi
if [ ! -z "${SERVER_IP}" ]; then params=( "${params[@]}" -ip "${SERVER_IP}" ); fi
if [ ! -z "${SERVER_PORT}" ]; then params=( "${params[@]}" -port "${SERVER_PORT}" ); fi

echo "x6"
echo "${params[@]}"

DISPLAY=:99 LD_LIBRARY_PATH="$LD_LIBRARY_PATH:../Steamworks SDK Redist/linux64/" ./CoreKeeperServer "${params[@]}" &

ckpid=$!

echo "Started server process with pid $ckpid"

while [ ! -f GameID.txt ]; do
        sleep 0.1
done

gameid=$(cat GameID.txt)
echo "Game ID: ${gameid}"

if [ -z "$DISCORD" ]; then
	DISCORD=0
fi

if [ $DISCORD -eq 1 ]; then
    if [ -z "$DISCORD_HOOK" ]; then
	echo "Please set DISCORD_WEBHOOK url."
        else
        curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"${gameid}\"}" "${DISCORD_HOOK}"
    fi
fi

wait $ckpid
ckpid=""
