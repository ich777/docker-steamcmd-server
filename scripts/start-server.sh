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
chmod -R ${DATA_PERM} ${DATA_DIR}
if [ ! -d ${SERVER_DIR}/saves ]; then
    mkdir -p ${SERVER_DIR}/saves
fi
if [ ! -f ${SERVER_DIR}/saves/serverDZ.cfg ]; then
    cp ${SERVER_DIR}/serverDZ.cfg ${SERVER_DIR}/saves/serverDZ.cfg
    sleep 1
    sed -i 's/\hostname = "EXAMPLE NAME";/hostname = "Docker DayZ";/g' ${SERVER_DIR}/saves/serverDZ.cfg
    sed -i 's/\password = "";/password = "Docker";/g' ${SERVER_DIR}/saves/serverDZ.cfg
    sed -i 's/\passwordAdmin = "";/passwordAdmin = "adminDocker";/g' ${SERVER_DIR}/saves/serverDZ.cfg
fi
echo "---Server ready---"

echo "---Start Server---"
cd ${SERVER_DIR}
${SERVER_DIR}/DayZServer -port=${GAME_PORT} -profiles=${SERVER_DIR}/saves -config=${SERVER_DIR}/saves/serverDZ.cfg ${GAME_PARAMS}
