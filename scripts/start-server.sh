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

echo "---Checking the maximum map count per process...---"
CUR_MAX_MAP_COUNT=$(cat /proc/sys/vm/max_map_count)
if [[ $CUR_MAX_MAP_COUNT -ge 256000 ]]; then
  echo "---Maximum map count per process OK...---"
  echo "---Current map count per process: $CUR_MAX_MAP_COUNT---"
else
  echo
  echo "+---ATTENTION---ATTENTION---ATTENTION---ATTENTION---ATTENTION---"
  echo "| Maximum map count per process too low, currently: $CUR_MAX_MAP_COUNT"
  echo "| Please set the value to at least '256000' on the host and"
  echo "| restart the container afterwards."
  echo "|"
  echo "| You can change the value by executing this command on the host"
  echo "| as root:"
  echo
  echo "echo 265000 > /proc/sys/vm/max_map_count"
  echo
  echo "| You can make that persistent by using a User Script that runs"
  echo "| on startup or putting this line in your go file."
  echo "+---ATTENTION---ATTENTION---ATTENTION---ATTENTION---ATTENTION---"
  echo
  echo "---Putting container into sleep mode!---"
  sleep infinity
fi

export WINEARCH=win64
export WINEPREFIX=/serverdata/serverfiles/WINE64
export WINEDEBUG=-all
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
echo "---Prepare Server---"
chmod -R ${DATA_PERM} ${DATA_DIR}
echo "---Server ready---"

echo "---Start Server---"
if [ ! -f ${SERVER_DIR}/ShooterGame/Binaries/Win64/ArkAscendedServer.exe ]; then
  echo "---Something went wrong, can't find the executable, putting container into sleep mode!---"
  sleep infinity
else
  cd ${SERVER_DIR}/ShooterGame/Binaries/Win64
  wine64 ArkAscendedServer.exe ${MAP}?listen?SessionName="${SERVER_NAME}"?ServerPassword="${SRV_PWD}"${GAME_PARAMS}?ServerAdminPassword="${SRV_ADMIN_PWD}" ${GAME_PARAMS_EXTRA} &
  echo "Waiting for logs..."
  ATTEMPT=0
  sleep 2
  while [ ! -f "${SERVER_DIR}/ShooterGame/Saved/Logs/ShooterGame.log" ]; do
    ((ATTEMPT++))
    if [ $ATTEMPT -eq 10 ]; then
      echo "No log files found after 20 seconds, putting container into sleep mode!"
      sleep infinity
    else
      sleep 2
      echo "Waiting for logs..."
    fi
  done
  ATTEMPT=0
  SERVER_READY=1
  while [ $SERVER_READY -eq 1 ]; do
    ((ATTEMPT++))
    if [ $ATTEMPT -eq 16 ]; then
      echo "Server failed to start within the allocated time!"
      exit 1
    fi
    if [ $ATTEMPT -eq 15 ]; then
      echo "Server not started after 30 seconds, sleeping for 60 seconds to check again..."
      sleep 60
      pidof -q ArkAscendedServer.exe
      SERVER_READY=$?
    else
      echo "Waiting for Ark process to start..."
      pidof -q ArkAscendedServer.exe
      SERVER_READY=$?
      sleep 2
    fi
  done
  /opt/scripts/start-watchdog.sh &
  tail -n 9999 -f ${SERVER_DIR}/ShooterGame/Saved/Logs/ShooterGame.log
fi
