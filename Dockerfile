###########################################################
# Dockerfile that builds a Core Keeper Gameserver
###########################################################
FROM steamcmd/steamcmd:latest

ENV SCRIPTSDIR "/opt/scripts"
ENV DATADIR "/data"

RUN mkdir "${SCRIPTSDIR}"

COPY ./startup.sh ${SCRIPTSDIR}/startup.sh

RUN dpkg --add-architecture i386

# Install Core Keeper server dependencies and clean up
# libx32gcc-s1 lib32gcc-s1 build-essential <- fixes tile generation bug (obsidian wall around spawn) without graphic cards mounted to server
# need all 3 + dpkg i do not know why but every other combination would run the server at an extreme speed - that combination worked for me.
# Thanks to https://www.reddit.com/r/CoreKeeperGame/comments/uym86p/comment/iays04w/?utm_source=share&utm_medium=web2x&context=3
RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
	xvfb mesa-utils libx32gcc-s1 lib32gcc-s1 build-essential libxi6 x11-utils \
	&& mkdir -p "${DATADIR}" \
	&& chmod +x "${SCRIPTSDIR}/startup.sh" \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir /tmp/.X11-unix

ENV WORLD_INDEX=0 \
	WORLD_NAME="Core Keeper Server" \
	WORLD_SEED=0 \
	WORLD_MODE=0 \
	GAME_ID="" \
	MAX_PLAYERS=10 \
	SEASON=-1 \
	SERVER_IP="" \
    SERVER_PORT=""

CMD ["bash", "${SCRIPTSDIR}/startup.sh"]
