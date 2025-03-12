#!/bin/bash
echo "+---------------------------------"
echo "|"
echo "| This container is deprecated!"
echo "|"
echo "+---------------------------------"
#sleep infinity

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

if [ "${ENA_REDIS}" == "yes" ]; then
	echo "---Starting Redis Server---"
	screen -S RedisServer -d -m /usr/bin/redis-server
	sleep 5
else
    echo "------------------------------------"
    echo "-----Internal Redis Server not------"
    echo "-----enabled, make sure you've------"
    echo "----configured your ATLAS server----"
    echo "--for an external REDIS connection--"
    echo "----otherwise it will not start!----"
    echo "------------------------------------"
    sleep 5
fi

echo "---Container under construction!---"
sleep infinity

echo "---Prepare Server---"
echo "---Searching for grid files...---"
if [ ! -f ${SERVER_DIR}/ShooterGame/ServerGrid.jpg ]; then
	echo "---'ServerGrid.jpg' not found, downloading---"
    cd ${SERVER_DIR}/ShooterGame
	if wget -q -nc --show-progress --progress=bar:force:noscroll https://raw.githubusercontent.com/CydFSA/docker-steamcmd-server/atlas/grid/ServerGrid.jpg ; then
    	echo "---Sucessfully downloaded 'ServerGrid.jpg'---"
	else
    	echo "---Can't download 'ServerGrid.jpg', putting server into sleep mode---"
        sleep infinity
	fi
else
	echo "---'ServerGrid.jpg' found!---"
fi
if [ ! -f ${SERVER_DIR}/ShooterGame/ServerGrid.json ]; then
	echo "---'ServerGrid.json' not found, downloading---"
    cd ${SERVER_DIR}/ShooterGame
	if wget -q -nc --show-progress --progress=bar:force:noscroll https://raw.githubusercontent.com/CydFSA/docker-steamcmd-server/atlas/grid/ServerGrid.json ; then
    	echo "---Sucessfully downloaded 'ServerGrid.json'---"
	else
    	echo "---Can't download 'ServerGrid.json', putting server into sleep mode---"
        sleep infinity
	fi
else
	echo "---'ServerGrid.json' found!---"
fi
if [ ! -f ${SERVER_DIR}/ShooterGame/ServerGrid.ServerOnly.json ]; then
	echo "---'ServerGrid.ServerOnly.json' not found, downloading---"
    cd ${SERVER_DIR}/ShooterGame
	if wget -q -nc --show-progress --progress=bar:force:noscroll https://raw.githubusercontent.com/CydFSA/docker-steamcmd-server/atlas/grid/ServerGrid.ServerOnly.json ; then
    	echo "---Sucessfully downloaded 'ServerGrid.ServerOnly.json'---"
	else
    	echo "---Can't download 'ServerGrid.ServerOnly.json', putting server into sleep mode---"
        sleep infinity
	fi
else
    if [ ! "$(grep '"Name": "TradeDB",' ${SERVER_DIR}/ShooterGame/ServerGrid.ServerOnly.json)" ]; then
        sed -i '/\"DatabaseConnections\": \[/a\    {\n      \"Name\": \"TradeDB\",\n      \"URL\": \"127.0.0.1\",\n      \"Port"\: 6379,\n      \"Password\": \"foobared\"\n    },' ${SERVER_DIR}/ShooterGame/ServerGrid.ServerOnly.json
    fi
	echo "---'ServerGrid.ServerOnly.json' found!---"
fi
if [ "${ENA_REDIS}" == "yes" ]; then
	echo "---Configuring Redis---"
    sleep 5
	echo "CONFIG SET dir ${SERVER_DIR}" | redis-cli
	echo "CONFIG SET dbfilename redis.rdb" | redis-cli
	echo "BGSAVE" | redis-cli
fi
sleep 3
chmod -R ${DATA_PERM} ${DATA_DIR}
echo "---Server ready---"

echo "---Start Server---"
cd ${SERVER_DIR}/ShooterGame/Binaries/Linux
./ShooterGameServer ${MAP_NAME}${GAME_PARAMS} ${GAME_PARAMS_EXTRA}
