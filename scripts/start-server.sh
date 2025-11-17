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
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir ${SERVER_DIR} \
        +login anonymous \
        +app_update ${GAME_ID} validate \
        +quit
    else
        ${STEAMCMD_DIR}/steamcmd.sh \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir ${SERVER_DIR} \
        +login anonymous \
        +app_update ${GAME_ID} \
        +quit
    fi
else
    if [ "${VALIDATE}" == "true" ]; then
    	echo "---Validating installation---"
        ${STEAMCMD_DIR}/steamcmd.sh \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir ${SERVER_DIR} \
        +login ${USERNAME} ${PASSWRD} \
        +app_update ${GAME_ID} validate \
        +quit
    else
        ${STEAMCMD_DIR}/steamcmd.sh \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir ${SERVER_DIR} \
        +login ${USERNAME} ${PASSWRD} \
        +app_update ${GAME_ID} \
        +quit
    fi
fi

echo "---Prepare Server---"
export WINEARCH=win64
export WINEPREFIX=/serverdata/serverfiles/WINE64
echo "---Checking if WINE workdirectory is present---"
if [ ! -d ${SERVER_DIR}/WINE64 ]; then
    echo "---WINE workdirectory not found, creating please wait...---"
    mkdir ${SERVER_DIR}/WINE64
else
    echo "---WINE workdirectory found---"
fi
echo "---Checking if WINE is properly installed---"
if [ ! -d ${SERVER_DIR}/WINE64/drive_c/windows ]; then
    echo "---Setting up WINE---"
    cd ${SERVER_DIR}
    winecfg > /dev/null 2>&1
    sleep 15
else
    echo "---WINE properly set up---"
fi

echo "---Checking for 'dedicatedserver.cfg'---"
if [ ! -f ${SERVER_DIR}/userdata/dedicatedserver.cfg ]; then
  echo "---'dedicatedserver.cfg' not found downloading---"
  if [ ! -d ${SERVER_DIR}/userdata ]; then
    mkdir -p ${SERVER_DIR}/userdata
  fi
  cd ${SERVER_DIR}/userdata
  if wget -q -nc --show-progress --progress=bar:force:noscroll https://raw.githubusercontent.com/ich777/docker-steamcmd-server/sonsoftheforest/config/dedicatedserver.cfg ; then
    echo "---Successfully downloaded 'dedicatedserver.cfg'---"
  else
    echo "---Something went wrong, can't download 'dedicatedserver.cfg', putting server in sleep mode---"
    sleep infinity
  fi
fi
if [ ! -f ${SERVER_DIR}/userdata/ownerswhitelist.txt ]; then
    touch ${SERVER_DIR}/userdata/ownerswhitelist.txt
fi
echo "1326470" > ${SERVER_DIR}/steam_appid.txt

echo "---Checking for old display lock files---"
find /tmp -name ".X99*" -exec rm -f {} \; > /dev/null 2>&1
chmod -R ${DATA_PERM} ${DATA_DIR}
echo "---Server ready---"

echo "---Start Server---"
cd ${SERVER_DIR}
xvfb-run --auto-servernum --server-args='-screen 0 640x480x24:32' wine64 ${SERVER_DIR}/SonsOfTheForestDS.exe -userdatapath ${SERVER_DIR}/userdata ${GAME_PARAMS}