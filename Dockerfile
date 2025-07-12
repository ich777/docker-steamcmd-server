FROM ich777/debian-baseimage

LABEL org.opencontainers.image.authors="admin@minenet.at"
LABEL org.opencontainers.image.source="https://github.com/ich777/docker-steamcmd-server"

RUN apt-get update && \
    apt-get -y install --no-install-recommends lib32gcc-s1 libsqlite3-0 libgdiplus unzip && \
    rm -rf /var/lib/apt/lists/*

# Base directories
ENV DATA_DIR="/serverdata"
ENV STEAMCMD_DIR="${DATA_DIR}/steamcmd"
ENV SERVER_DIR="${DATA_DIR}/serverfiles"

# SteamCMD settings
ENV GAME_ID="template"
ENV GAME_NAME="template"
ENV VALIDATE=""
ENV USERNAME=""
ENV PASSWRD=""

# Server ports
ENV GAME_PORT=28015
ENV QUERY_PORT=28016
ENV RCON_PORT=28017
ENV APP_PORT=28018

# Rust server configuration
ENV SERVER_NAME="RustDocker"
ENV SERVER_DESCRIPTION="Simple Unraid Rust Docker"
ENV SERVER_LEVEL="Procedural Map"
ENV SERVER_SEED=""
ENV SERVER_WORLDSIZE=3000
ENV SERVER_MAXPLAYERS=50
ENV SERVER_URL=""
ENV SERVER_HEADERIMAGE=""
ENV SERVER_IDENTITY="rustserver"
ENV RCON_PASSWORD=""
ENV RCON_WEB=1
ENV LOG_FILE=""

# Mod settings
ENV OXIDE_MOD="false"
ENV CARBON_MOD="false"
ENV FORCE_OXIDE_INSTALLATION="true"

# Legacy support - kept for backward compatibility
ENV GAME_PARAMS=""

# System settings
ENV UMASK=000
ENV UID=99
ENV GID=100
ENV USER="steam"
ENV DATA_PERM=770

RUN mkdir $DATA_DIR && \
    mkdir $STEAMCMD_DIR && \
    mkdir $SERVER_DIR && \
    useradd -d $DATA_DIR -s /bin/bash $USER && \
    chown -R $USER $DATA_DIR && \
    ulimit -n 2048

ADD /scripts/ /opt/scripts/
RUN chmod -R 770 /opt/scripts/

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]