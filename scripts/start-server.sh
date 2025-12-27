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
echo "---Looking for config files---"
if [ ! -d ${SERVER_DIR}/Astro/Saved/Config/WindowsServer ]; then
  mkdir -p ${SERVER_DIR}/Astro/Saved/Config/WindowsServer
fi
if [ ! -f ${SERVER_DIR}/Astro/Saved/Config/WindowsServer/AstroServerSettings.ini ]; then
  echo "[/Script/Astro.AstroServerSettings]
bLoadAutoSave=True
MaxServerFramerate=30.000000
MaxServerIdleFramerate=3.000000
bWaitForPlayersBeforeShutdown=False
ConsolePassword=adminDocker
PublicIP=
ServerName=AstroneerDocker
ServerGuid=
OwnerName=
OwnerGuid=0
PlayerActivityTimeout=0
ServerPassword=Docker
bDisableServerTravel=False
DenyUnlistedPlayers=False
VerbosePlayerProperties=False
AutoSaveGameInterval=900
BackupSaveGamesInterval=7200
ActiveSaveFileDescriptiveName=SAVE_1
ServerAdvertisedName=" > ${SERVER_DIR}/Astro/Saved/Config/WindowsServer/AstroServerSettings.ini
else
  echo "---'AstroServerSettings.ini' found---"
fi
if [ ! -f ${SERVER_DIR}/Astro/Saved/Config/WindowsServer/Engine.ini ]; then
  echo "[URL]
Port=8777

[SystemSettings]
net.AllowEncryption=False" > ${SERVER_DIR}/Astro/Saved/Config/WindowsServer/Engine.ini
else
  echo "---'Engine.ini' found---"
  sed -i '/^HeartbeatInterval=0/d' ${SERVER_DIR}/Astro/Saved/Config/WindowsServer/AstroServerSettings.ini
fi

echo "---Checking if PublicIP is in place---"
PUBLIC_IP="$(cat ${SERVER_DIR}/Astro/Saved/Config/WindowsServer/AstroServerSettings.ini | grep "PublicIP=" | cut -d '=' -f2)"
if [ -z "${PUBLIC_IP}" ]; then
  echo "---No PublicIP found in AstroServerSettings.ini, trying to obtain it...---"
  PUBLIC_IP="$(wget -qO - icanhazip.com)"
  if [ -z "${PUBLIC_IP}" ]; then
    echo "---Can't get PublicIP, please set it manually in your AstroServerSettings.ini!---"
  else
    echo "---Sucessfully obtained PublicIP: ${PUBLIC_IP}, adding to AstroServerSettings.ini"
    sed -i "s/PublicIP=.*/PublicIP=${PUBLIC_IP}/g" ${SERVER_DIR}/Astro/Saved/Config/WindowsServer/AstroServerSettings.ini
  fi
else
  if [ "${UPDATE_PUBLIC_IP}" == "true" ]; then
    NEW_PUBLIC_IP="$(wget -qO - icanhazip.com)"
    if [ -z "${NEW_PUBLIC_IP}" ]; then
      echo "---Can't get PublicIP, please set it manually in your AstroServerSettings.ini!---"
    else
      if [ "${PUBLIC_IP}" != "${NEW_PUBLIC_IP}" ]; then
        echo "---Changing PublicIP in AstroServerSettings.ini to: ${NEW_PUBLIC_IP}!---"
        sed -i "s/PublicIP=.*/PublicIP=${NEW_PUBLIC_IP}/g" ${SERVER_DIR}/Astro/Saved/Config/WindowsServer/AstroServerSettings.ini
      else
        echo "---Nothing to do, PublicIP: ${PUBLIC_IP} still up-to-date!---"
      fi
    fi
  else
    echo "---PublicIP in AstroServerSettings.ini found: ${PUBLIC_IP}"
  fi
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
echo "---Checking if UE4 Prerequisites are installed---"
if [ ! -f ${SERVER_DIR}/WINE64/drive_c/users/steam/UE4_installed ]; then
  echo "---Installing UE4 Prerequisites, this will take a bit, please wait...---"
  if [ -f ${SERVER_DIR}/Engine/Extras/Redist/en-us/UE4PrereqSetup_x64.exe ]; then
    xvfb-run --auto-servernum --server-args='-screen 0 640x480x24:32' wine64 ${SERVER_DIR}/Engine/Extras/Redist/en-us/UE4PrereqSetup_x64.exe /quiet /norestart
  else
    echo "---Can't find UE4 Prerequisites, putting container into sleep mode...---"
    sleep infinity
  fi
  touch ${SERVER_DIR}/WINE64/drive_c/users/steam/UE4_installed
else
  echo "--UE4 Prerequisites are installed---"
fi
echo "---Checking for old display lock files---"
find /tmp -name ".X99*" -exec rm -f {} \; > /dev/null 2>&1
chmod -R ${DATA_PERM} ${DATA_DIR}
echo "---Server ready---"
echo
echo "+--------------------------------------------------------------------------"
echo "| Please don't forget to add this entry to your Engine.ini on your Clients:"
echo "+--------------------------------------------------------------------------"
echo
echo "[SystemSettings]"
echo "net.AllowEncryption=False"
echo
echo "+-------------------------------------------------------------------------------"
echo "| ATTENTION: If a client tries to connect without that in Engine.ini, the server"
echo "| will be left in a semi bricked state and you have to restart the container!"
echo "|"
echo "| You can find the file on your local Windows machine at:"
echo "| %localappdata%\Astro\Saved\Config\WindowsNoEditor"
echo "+-------------------------------------------------------------------------------"
echo

if [ "${BACKUP}" == "true" ]; then
  echo "---Starting Backup daemon---"
  if [ ! -d ${SERVER_DIR}/Backups ]; then
    mkdir -p ${SERVER_DIR}/Backups
  fi
  /opt/scripts/start-backup.sh &
fi

echo "---Start Server---"
cd ${SERVER_DIR}
xvfb-run --auto-servernum --server-args='-screen 0 640x480x24:32' wine64 AstroServer.exe ${GAME_PARAMS}