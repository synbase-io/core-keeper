###########################################################
# Dockerfile that builds a Core Keeper Gameserver
###########################################################
FROM cm2network/steamcmd:root

LABEL maintainer="leandro.martin@protonmail.com"

ENV MAINDIR "/opt"
ENV STEAMAPPID 1007
ENV STEAMAPPID_TOOL 1963720
ENV STEAMAPP core-keeper
ENV STEAMAPPDIR "${MAINDIR}/server"
ENV STEAMAPPDATADIR "${MAINDIR}/data"
ENV DLURL https://raw.githubusercontent.com/escapingnetwork/core-keeper-dedicated

COPY ./entry.sh ${MAINDIR}/entry.sh
COPY ./launch.sh ${MAINDIR}/launch.sh

RUN dpkg --add-architecture i386

# Install Core Keeper server dependencies and clean up
# libx32gcc-s1 lib32gcc-s1 build-essential <- fixes tile generation bug (obsidian wall around spawn) without graphic cards mounted to server
# need all 3 + dpkg i do not know why but every other combination would run the server at an extreme speed - that combination worked for me.
# Thanks to https://www.reddit.com/r/CoreKeeperGame/comments/uym86p/comment/iays04w/?utm_source=share&utm_medium=web2x&context=3
RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
	xvfb mesa-utils libx32gcc-s1 lib32gcc-s1 build-essential libxi6 x11-utils tini \
	&& mkdir -p "${STEAMAPPDIR}" \
	&& mkdir -p "${STEAMAPPDATADIR}" \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir /tmp/.X11-unix


ENV WORLD_INDEX=0 \
	WORLD_NAME="Core Keeper Server" \
	WORLD_SEED=0 \
	WORLD_MODE=0 \
	GAME_ID="" \
	DATA_PATH="${STEAMAPPDATADIR}" \
	MAX_PLAYERS=10 \
	SEASON=-1 \
	SERVER_IP="" \
    SERVER_PORT=""

# Switch to workdir
WORKDIR ${MAINDIR}

VOLUME ${STEAMAPPDIR}

# Use tini as the entrypoint for signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["bash", "entry.sh"]