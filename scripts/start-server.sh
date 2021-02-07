#!/bin/bash
if [ ! -f ${STEAMCMD_DIR}/steamcmd.sh ]; then
    echo "SteamCMD not found!"
    wget -q -O ${STEAMCMD_DIR}/steamcmd_linux.tar.gz http://media.steampowered.com/client/steamcmd_linux.tar.gz 
    tar --directory ${STEAMCMD_DIR} -xvzf /serverdata/steamcmd/steamcmd_linux.tar.gz
    rm ${STEAMCMD_DIR}/steamcmd_linux.tar.gz
fi

echo "---Update SteamCMD---"
if [ "${USERNAME}" == "" ]; then
    echo "Please enter a valid username and password and restart the container. ATTENTION: Steam Guard must be DISABLED!!!"
    sleep infinity
else
    ${STEAMCMD_DIR}/steamcmd.sh \
    +login ${USERNAME} ${PASSWRD} \
    +quit
fi

echo "---Update Server---"
if [ "${VALIDATE}" == "true" ]; then
	echo "---Validating installation---"
    ${STEAMCMD_DIR}/steamcmd.sh \
    +login ${USERNAME} ${PASSWRD} \
    +force_install_dir ${SERVER_DIR} \
    +app_update ${GAME_ID} validate \
    +quit
else
    ${STEAMCMD_DIR}/steamcmd.sh \
    +login ${USERNAME} ${PASSWRD} \
    +force_install_dir ${SERVER_DIR} \
    +app_update ${GAME_ID} \
    +quit
fi

echo "---Prepare Server---"
if [ ! -f ${SERVER_DIR}/server.cfg ]; then
    echo "---No 'server.cfg' found, downloading...---"
    cd ${SERVER_DIR}
    if wget -q -nc --show-progress --progress=bar:force:noscroll https://raw.githubusercontent.com/ich777/docker-steamcmd-server/arma3/config/server.cfg ; then
    	echo "---Sucessfully downloaded 'server.cfg'---"
	else
    	echo "---Can't download 'server.cfg', putting server into sleep mode---"
        sleep infinity
	fi
else
    echo "---server.cfg found..."
fi

cp ${DATA_DIR}/steamcmd/linux32/* ${SERVER_DIR}
chmod -R ${DATA_PERM} ${DATA_DIR}

echo "---Start Server---"
cd ${SERVER_DIR}
./arma3server_x64 ${GAME_PARAMS}
