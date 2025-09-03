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

echo "---Looking if 'server_config.xml' file is in place---"
if [ ! -f ${SERVER_DIR}/WINE64/drive_c/users/steam/AppData/Roaming/Stormworks/server_config.xml ]; then
  echo "---'ServerSettings.ini' not found, copying template...---"
  if [ ! -d ${SERVER_DIR}/WINE64/drive_c/users/steam/AppData/Roaming/Stormworks ]; then
    mkdir -p ${SERVER_DIR}/WINE64/drive_c/users/steam/AppData/Roaming/Stormworks
  fi
  cp /opt/server_config.xml ${SERVER_DIR}/WINE64/drive_c/users/steam/AppData/Roaming/Stormworks/server_config.xml
else
  echo "---'server_config.xml' found---"
fi

echo "---Checking for old display lock files---"
find /tmp -name ".X99*" -exec rm -f {} \; > /dev/null 2>&1
chmod -R ${DATA_PERM} ${DATA_DIR}
echo "---Server ready---"

echo "---Start Server---"
if [ ! -f ${SERVER_DIR}/server64.exe ]; then
  echo "---Something went wrong, can't find the executable, putting container into sleep mode!---"
  sleep infinity
else
  cd ${SERVER_DIR}
  wine64 server64.exe ${GAME_PARAMS}
fi
