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

echo "---Checking if configuration is in place---"
if [ ! -f ${SERVER_DIR}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini ]; then
  if [ ! -d ${SERVER_DIR}/Pal/Saved/Config/LinuxServer ]; then
    mkdir -p ${SERVER_DIR}/Pal/Saved/Config/LinuxServer
  fi
  echo "---Configuration not found, downloading...---"
  wget -qO ${SERVER_DIR}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini https://github.com/ich777/docker-steamcmd-server/raw/palworld/config/PalWorldSettings.ini
else
  echo "---Configuration found, continuing...---"
fi

echo "---Checking if PublicIP is in place---"
PUBLIC_IP="$(grep -o 'PublicIP="[^"]*"' ${SERVER_DIR}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini | cut -d '"' -f2)"
if [ -z "${PUBLIC_IP}" ]; then
  echo "---No PublicIP found in PalWorldSettings.ini, trying to obtain it...---"
  PUBLIC_IP="$(wget -qO - ipv4.icanhazip.com)"
  if [ -z "${PUBLIC_IP}" ]; then
    echo "---Can't get PublicIP, please set it manually in your PalWorldSettings.ini!---"
  else
    echo "---Sucessfully obtained PublicIP: ${PUBLIC_IP}, adding to PalWorldSettings.ini"
    /opt/scripts/ini-updater.sh "PublicIP" "${PUBLIC_IP}"
  fi
else
  if [ "${UPDATE_PUBLIC_IP}" == "true" ]; then
    NEW_PUBLIC_IP="$(wget -qO - ipv4.icanhazip.com)"
    if [ -z "${NEW_PUBLIC_IP}" ]; then
      echo "---Can't get PublicIP, please set it manually in your PalWorldSettings.ini!---"
    else
      if [ "${PUBLIC_IP}" != "${NEW_PUBLIC_IP}" ]; then
        echo "---Changing PublicIP in PalWorldSettings.ini to: ${NEW_PUBLIC_IP}!---"
        /opt/scripts/ini-updater.sh "PublicIP" "${NEW_PUBLIC_IP}"
      else
        echo "---Nothing to do, PublicIP: ${PUBLIC_IP} still up-to-date!---"
      fi
    fi
  else
    echo "---PublicIP in PalWorldSettings.ini found: ${PUBLIC_IP}"
  fi
fi

echo "---Prepare Server---"
if [ ! -f ${SERVER_DIR}/Engine/Binaries/Linux/steamclient.so ]; then
  ln -s ${SERVER_DIR}/linux64/steamclient.so ${SERVER_DIR}/Engine/Binaries/Linux/steamclient.so
fi
if [ ! -d ${DATA_DIR}/.steam/sdk64 ]; then
  mkdir -p ${DATA_DIR}/.steam/sdk64
  cp -R ${SERVER_DIR}/linux64/* ${DATA_DIR}/.steam/sdk64/
fi

chmod -R ${DATA_PERM} ${DATA_DIR}
echo "---Server ready---"

if [ "${BACKUP}" == "true" ]; then
  echo "---Starting Backup daemon---"
  if [ ! -d ${SERVER_DIR}/Backups ]; then
    mkdir -p ${SERVER_DIR}/Backups
  fi
  /opt/scripts/start-backup.sh &
fi

echo "---Start Server---"
if [ ! -f ${SERVER_DIR}/Pal/Binaries/Linux/PalServer-Linux-Test ]; then
  echo "---Something went wrong, can't find the executable, putting container into sleep mode!---"
  sleep infinity
else
  cd ${SERVER_DIR}
  ${SERVER_DIR}/Pal/Binaries/Linux/PalServer-Linux-Test Pal -nocore ${GAME_PARAMS} ${GAME_PARAMS_EXTRA}
fi