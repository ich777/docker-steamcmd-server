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

if [ -d /serverdata/serverfiles/WINE64 ]; then
  echo "+-----------------------------------------------------------------------------"
  echo "| UPDATE NOTICE"
  echo "+-----------------------------------------------------------------------------"
  echo "| Since Conan Exiles was updated to Unreal Engine 5 you have to transition"
  echo "| your files over manually:"
  echo "| 1. Stop the container"
  echo "| 2. Manually backup your save/config files (eg to your local PC)"
  echo "|    Location: ../ConanSandbox/Saved (make sure to backup the whole folder)"
  echo "| 3. In the backed up folder rename \"WindowsServer\" to \"LinuxServer\""
  echo "|    Location: ../Saved/Config"
  echo "| 4. Delete all files/folders from the conanexiles directory"
  echo "| 5. Start the container and wait for it to pull the new gamefiles"
  echo "|    (open the logs and wait for it to fully start)"
  echo "| 6. Stop the container again"
  echo "| 7. Delete the newly created Saved folder and copy over your backed up"
  echo "|    Saved folder from Step 2"
  echo "|    Location: ../ConanSandbox/Saved"
  echo "| 8. Start the container"
  echo "|"
  echo "| This container was also converted from running Conan Exiles through WINE"
  echo "| to native Linux environment."
  echo "|"
  echo "|         CONTAINER PUT TO SLEEP MODE - CONTAINER PUT TO SLEEP MODE"
  echo "+-----------------------------------------------------------------------------"
  sleep infinity
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

if [ ! -z "${WS_CONTENT}" ]; then
	echo "---Installing Workshop Content with ID('s): ${WS_CONTENT}---"
	${STEAMCMD_DIR}/steamcmd.sh \
	+force_install_dir ${SERVER_DIR} \
	+login anonymous \
	+workshop_download_item 440900 ${WS_CONTENT// / +workshop_download_item 440900  } \
	+quit
	if [ ! -d ${SERVER_DIR}/ConanSandbox/Mods ]; then
		if [ ! -d ${SERVER_DIR}/ConanSandbox ]; then
			echo "-----------------------------------"
			echo "------Something went wrong can't find folder-"
			echo "---'ConanSandbox' putting server into sleep mode---"
			echo "-"
			sleep infinity
		fi
		echo "---Folder 'Mods' not found, creating...---"
		mkdir ${SERVER_DIR}/ConanSandbox/Mods
	fi
	if [ ! -f ${SERVER_DIR}/ConanSandbox/Mods/modlist.txt ]; then
		echo "---File 'modlist.txt' not found, creating...---"
		touch ${SERVER_DIR}/ConanSandbox/Mods/modlist.txt
	fi
	echo "---Putting workshop content into modlist---"
	#install mods in order
	> ${SERVER_DIR}/ConanSandbox/Mods/modlist.txt
	for WS_ITEM in ${WS_CONTENT}; do
		find ${SERVER_DIR}/steamapps/workshop/content/440900/${WS_ITEM}/ -name *.pak >> ${SERVER_DIR}/ConanSandbox/Mods/modlist.txt
	done
fi

echo "---Prepare Server---"
echo "---Looking for config files---"
if [ ! -d ${SERVER_DIR}/ConanSandbox/Saved/Config/LinuxServer ]; then
	if [ ! -d ${SERVER_DIR}/ConanSandbox ]; then
    	echo "-----------------------------------------------------------"
    	echo "---Something went wrong can't find folder 'ConanSandbox'---"
    	echo "--------------Putting Server into sleep mode---------------"
    	sleep infinity
    	fi
    if [ ! -d ${SERVER_DIR}/ConanSandbox/Saved ]; then
		mkdir ${SERVER_DIR}/ConanSandbox/Saved
    fi
	if [ ! -d ${SERVER_DIR}/ConanSandbox/Saved/Config ]; then
		mkdir ${SERVER_DIR}/ConanSandbox/Saved/Config
    fi
    if [ ! -d ${SERVER_DIR}/ConanSandbox/Saved/Config/LinuxServer ]; then
		mkdir ${SERVER_DIR}/ConanSandbox/Saved/Config/LinuxServer
    fi
fi
if [ ! -f ${SERVER_DIR}/ConanSandbox/Saved/Config/LinuxServer/Engine.ini ]; then
	echo "---'Engine.ini' not found, downloading template---"
    cd ${SERVER_DIR}/ConanSandbox/Saved/Config/LinuxServer
	if wget -q -nc --show-progress --progress=bar:force:noscroll https://raw.githubusercontent.com/ich777/docker-steamcmd-server/conanexiles/config/Engine.ini ; then
		echo "---Sucessfully downloaded 'Engine.ini'---"
	else
		echo "---Something went wrong, can't download 'Engine.ini', putting server in sleep mode---"
		sleep infinity
	fi
else
	echo "---'Engine.ini' found---"
fi
if [ ! -f ${SERVER_DIR}/ConanSandbox/Saved/Config/LinuxServer/ServerSettings.ini ]; then
	echo "---'ServerSettings.ini' not found, downloading template---"
    cd ${SERVER_DIR}/ConanSandbox/Saved/Config/LinuxServer
	if wget -q -nc --show-progress --progress=bar:force:noscroll https://raw.githubusercontent.com/ich777/docker-steamcmd-server/conanexiles/config/ServerSettings.ini ; then
		echo "---Sucessfully downloaded 'ServerSettings.ini'---"
	else
		echo "---Something went wrong, can't download 'ServerSettings.ini', putting server in sleep mode---"
		sleep infinity
	fi
else
	echo "---'ServerSettings.ini' found---"
fi
echo "---Server ready---"

echo "---Start Server---"
cd ${SERVER_DIR}
if [ -f "$SERVER_DIR/ConanSandbox/Binaries/Linux/ConanSandboxServer-Linux-Shipping" ]; then
  $SERVER_DIR/ConanSandbox/Binaries/Linux/ConanSandboxServer-Linux-Shipping ConanSandbox -log ${GAME_PARAMS}
else
  echo "---ERROR: Server executable not found!---"
  sleep infinity
fi