#!/bin/bash
if [ ! -f ${STEAMCMD_DIR}/steamcmd.sh ]; then
    echo "SteamCMD not found!"
    wget -q -O ${STEAMCMD_DIR}/steamcmd_linux.tar.gz http://media.steampowered.com/client/steamcmd_linux.tar.gz 
    tar --directory ${STEAMCMD_DIR} -xvzf /serverdata/steamcmd/steamcmd_linux.tar.gz
    rm ${STEAMCMD_DIR}/steamcmd_linux.tar.gz
fi

echo "---Update SteamCMD---"
if [ "${USERNAME}" == "" ]; then
    ${STEAMCMD_DIR}/steamcmd.sh \
    +login anonymous \
    +quit
else
    ${STEAMCMD_DIR}/steamcmd.sh \
    +login ${USERNAME} ${PASSWRD} \
    +quit
fi

echo "---Update Server---"
if [ "${USERNAME}" == "" ]; then
    if [ "${VALIDATE}" == "true" ]; then
    	echo "---Validating installation---"
        ${STEAMCMD_DIR}/steamcmd.sh \
        +force_install_dir ${SERVER_DIR} \
        +login anonymous \
        +app_update ${GAME_ID} validate \
        +quit
    else
        ${STEAMCMD_DIR}/steamcmd.sh \
        +force_install_dir ${SERVER_DIR} \
        +login anonymous \
        +app_update ${GAME_ID} \
        +quit
    fi
else
    if [ "${VALIDATE}" == "true" ]; then
    	echo "---Validating installation---"
        ${STEAMCMD_DIR}/steamcmd.sh \
        +force_install_dir ${SERVER_DIR} \
        +login ${USERNAME} ${PASSWRD} \
        +app_update ${GAME_ID} validate \
        +quit
    else
        ${STEAMCMD_DIR}/steamcmd.sh \
        +force_install_dir ${SERVER_DIR} \
        +login ${USERNAME} ${PASSWRD} \
        +app_update ${GAME_ID} \
        +quit
    fi
fi

echo "---Prepare Server---"
if [ ! -f ${DATA_DIR}/.steam/sdk32/steamclient.so ]; then
	if [ ! -d ${DATA_DIR}/.steam ]; then
    	mkdir ${DATA_DIR}/.steam
    fi
	if [ ! -d ${DATA_DIR}/.steam/sdk32 ]; then
    	mkdir ${DATA_DIR}/.steam/sdk32
    fi
    cp -R ${STEAMCMD_DIR}/linux32/* ${DATA_DIR}/.steam/sdk32/
fi

if [ ! -f ${SERVER_DIR}/RSDragonwilds/Saved/Config/LinuxServer/DedicatedServer.ini ]; then
    if [ ! -d ${SERVER_DIR}/RSDragonwilds/Saved/Config/LinuxServer ]; then
        mkdir -p ${SERVER_DIR}/RSDragonwilds/Saved/Config/LinuxServer
    fi
    if [ ! -d ${SERVER_DIR}/RSDragonwilds/Saved/SaveGames ]; then
        mkdir -p ${SERVER_DIR}/RSDragonwilds/Saved/SavedGames
    fi
    touch ${SERVER_DIR}/RSDragonwilds/Saved/Config/LinuxServer/DedicatedServer.ini
    echo -e ";METADATA=(Diff=true, UseCommands=true)
[/Script/Dominion.DedicatedServerSettings]
OwnerID=\"${OwnerID}\"
ServerName=\"${SERVERNAME}\"
DefaultWorldName=\"${DEFAULTWORLDNAME}\"
AdminPassword=\"${ADMINPASSWORD}\"
WorldPassword=\"${WORLDPASSWORD}\"" >> ${SERVER_DIR}/RSDragonwilds/Saved/Config/LinuxServer/DedicatedServer.ini
    fi

chmod -R ${DATA_PERM} ${DATA_DIR}
echo "---Server ready---"

echo "---Start Server---"
cd ${SERVER_DIR}
${SERVER_DIR}/RSDragonwildsServer.sh ${GAME_PARAMS} -console +port ${GAME_PORT}