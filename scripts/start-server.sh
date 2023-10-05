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
if [ -d ${SERVER_DIR}/.config/unity3d/IronGate/Valheim/worlds ]; then
    echo "---Found old save directory... Moving saves directory to new location...!---"
    mv ${SERVER_DIR}/.config/unity3d/IronGate/Valheim/worlds ${SERVER_DIR}/.config/unity3d/IronGate/Valheim/worlds_local
fi
if [ "${ENABLE_VALHEIMPLUS}" != "true" ]; then
    export LD_LIBRARY_PATH=${SERVER_DIR}/linux64:$LD_LIBRARY_PATH
    export templdpath=$LD_LIBRARY_PATH
    export SteamAppId=892970
fi
if [ "${LOG_OUTPUT}" == "true" ]; then
    if [ -z "${LOG_FILE}" ]; then
        echo "---Variable 'LOG_FILE' can't be empty, set it to 'valheim.log'!---"
        LOG_FILE="valheim.log"
    fi
    if [ "${DELETE_LOG}" == "true" ]; then
        rm ${SERVER_DIR}/${LOG_FILE}
    fi
fi
chmod -R ${DATA_PERM} ${DATA_DIR}
screen -wipe 2&>/dev/null

# Check if both ValheimPlus and BepInEx are enabled and throw error
if [ "${ENABLE_VALHEIMPLUS}" == "true" ] && [ "${ENABLE_BEPINEX}" == "true" ]; then
    echo
    echo "---ValheimPlus and BepInEx are both enabled, only one of the two can---"
    echo "---be enabled, please disable one of them and restart the container!---"
    echo
    echo "------------------Putting Container into sleep mode!-------------------"
    sleep infinity
fi

if [ "${ENABLE_VALHEIMPLUS}" == "true" ]; then
    echo "---ValheimPlus enabled!---"
    echo
    echo "-------------------------------------------"
    echo "Using following repository for ValheimPlus:"
    echo
    echo "Orga./User: ${VALHEIMPLUS_ORG_REPO%%/*}"
    echo "Repository: ${VALHEIMPLUS_ORG_REPO##*/}"
    echo "-------------------------------------------"
    echo
    CUR_V="$(find ${SERVER_DIR} -maxdepth 1 -name "ValheimPlus-*" | cut -d '-' -f2-)"
    LAT_V="$(wget -qO- https://api.github.com/repos/${VALHEIMPLUS_ORG_REPO}/releases/latest | grep tag_name | cut -d '"' -f4 | cut -d 'v' -f2)"
    if [ -z "${LAT_V}" ] && [ -z "${CUR_V}" ]; then
        echo "---Can't get latest version of Valheim Plus!---"
        echo "---Please try to run the Container without ValheimPlus, putting Container into sleep mode!---"
        sleep infinity
    fi

    if [ -f ${SERVER_DIR}/ValheimPlus.zip ]; then
	    rm -rf ${SERVER_DIR}/ValheimPlus.zip
    fi

    echo "---ValheimPlus Version Check---"
    if [ -z "${CUR_V}" ]; then
        echo "---ValheimPlus not found, downloading and installing v$LAT_V...---"
        cd ${SERVER_DIR}
        if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${SERVER_DIR}/ValheimPlus.zip "https://github.com/${VALHEIMPLUS_ORG_REPO}/releases/download/${LAT_V}/UnixServer.zip" ; then
            echo "---Successfully downloaded ValheimPlus v$LAT_V---"
        else
            echo "---Something went wrong, can't download ValheimPlus v$LAT_V, putting container into sleep mode!---"
            sleep infinity
        fi
        unzip -o ${SERVER_DIR}/ValheimPlus.zip
	    touch ${SERVER_DIR}/ValheimPlus-$LAT_V
        rm ${SERVER_DIR}/ValheimPlus.zip
    elif [ "${CUR_V}" != "${LAT_V}" ]; then
        echo "---Version missmatch, ValheimPlus v$CUR_V installed, downloading and installing v$LAT_V...---"
        cd ${SERVER_DIR}
    	rm -rf ${SERVER_DIR}/ValheimPlus-$CUR_V
        mkdir /tmp/Backup
        cp -R ${SERVER_DIR}/BepInEx/config /tmp/Backup/
        if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${SERVER_DIR}/ValheimPlus.zip "https://github.com/${VALHEIMPLUS_ORG_REPO}/releases/download/${LAT_V}/UnixServer.zip" ; then
            echo "---Successfully downloaded ValheimPlus v$LAT_V---"
        else
            echo "---Something went wrong, can't download ValheimPlus v$LAT_V, putting container into sleep mode!---"
            sleep infinity
        fi
        unzip -o ${SERVER_DIR}/ValheimPlus.zip
	    touch ${SERVER_DIR}/ValheimPlus-$LAT_V
        cp -R /tmp/Backup/config ${SERVER_DIR}/BepInEx/
        rm -rf ${SERVER_DIR}/ValheimPlus.zip /tmp/Backup
    elif [ "${CUR_V}" == "${LAT_V}" ]; then
        echo "---ValheimPlus v${CUR_V%%-*} up-to-date---"
    fi
fi

if [ "${ENABLE_BEPINEX}" == "true" ]; then
    echo "---BepInEx for Valheim enabled!---"
    CUR_V="$(find ${SERVER_DIR} -maxdepth 1 -name "BepInEx-*" | cut -d '-' -f2)"
    LAT_V="$(wget -qO- https://valheim.thunderstore.io/api/experimental/package/denikson/BepInExPack_Valheim/ | sed -n 's|.*"version_number":"\([^"]*\)".*|\1|p')"
    if [ -z "${LAT_V}" ] && [ -z "${CUR_V}" ]; then
        echo "---Can't get latest version of BepInEx for Valheim!---"
        echo "---Please try to run the Container without BepInEx for Valheim, putting Container into sleep mode!---"
        sleep infinity
    fi

    if [ -f ${SERVER_DIR}/BepInEx.zip ]; then
	    rm -rf ${SERVER_DIR}/BepInEx.zip
    fi

    echo "---BepInEx for Valheim Version Check---"
    echo
    echo "---https://valheim.thunderstore.io/package/denikson/BepInExPack_Valheim/---"
    echo
    if [ -z "${CUR_V}" ]; then
        echo "---BepInEx for Valheim not found, downloading and installing v$LAT_V...---"
        cd ${SERVER_DIR}
        if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${SERVER_DIR}/BepInEx.zip --user-agent=Mozilla --content-disposition -E -c "https://valheim.thunderstore.io/package/download/denikson/BepInExPack_Valheim/$LAT_V/" ; then
            echo "---Successfully downloaded BepInEx for Valheim v$LAT_V---"
        else
            echo "---Something went wrong, can't download BepInEx for Valheim v$LAT_V, putting container into sleep mode!---"
            sleep infinity
        fi
        mkdir -p /tmp/BepInEx
        unzip -o ${SERVER_DIR}/BepInEx.zip -d /tmp/BepInEx
        cp -rf /tmp/BepInEx/BepInEx*/* ${SERVER_DIR}/
        cp /tmp/BepInEx/README* ${SERVER_DIR}/README_BepInEx_for_Valheim
	    touch ${SERVER_DIR}/BepInEx-$LAT_V
        rm -rf ${SERVER_DIR}/BepInEx.zip /tmp/BepInEx
    elif [ "$CUR_V" != "$LAT_V" ]; then
        echo "---Version missmatch, BepInEx v$CUR_V installed, downloading and installing v$LAT_V...---"
        cd ${SERVER_DIR}
    	rm -rf ${SERVER_DIR}/BepInEx-$CUR_V
        mkdir /tmp/Backup
        cp -R ${SERVER_DIR}/BepInEx/config /tmp/Backup/
        if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${SERVER_DIR}/BepInEx.zip --user-agent=Mozilla --content-disposition -E -c "https://valheim.thunderstore.io/package/download/denikson/BepInExPack_Valheim/$LAT_V/" ; then
            echo "---Successfully downloaded BepInEx for Valheim v$LAT_V---"
        else
            echo "---Something went wrong, can't download BepInEx for Valheim v$LAT_V, putting container into sleep mode!---"
            sleep infinity
        fi
        unzip -o ${SERVER_DIR}/BepInEx.zip -d /tmp/BepInEx
        cp -rf /tmp/BepInEx/BepInEx*/* ${SERVER_DIR}/
        cp /tmp/BepInEx/README* ${SERVER_DIR}/README_BepInEx_for_Valheim
	    touch ${SERVER_DIR}/BepInEx-$LAT_V
        cp -R /tmp/Backup/config ${SERVER_DIR}/BepInEx/
        rm -rf ${SERVER_DIR}/BepInEx.zip /tmp/BepInEx /tmp/Backup
    elif [ "${CUR_V}" == "${LAT_V}" ]; then
        echo "---BepInEx v$CUR_V up-to-date---"
    fi
fi

echo "---Server ready---"

if [ "${BACKUP_FILES}" == "true" ]; then
    echo "---Starting Backup daemon---"
    if [ ! -d ${SERVER_DIR}/Backups ]; then
        mkdir -p ${SERVER_DIR}/Backups
    fi
    screen -S backup -d -m /opt/scripts/start-backup.sh
fi

if [ "${UPDATE_CHECK}" == "true" ]; then
    echo "---Update check deprecated!---"
#    /opt/scripts/start-updatecheck.sh &
fi

echo "---Start Server---"
cd ${SERVER_DIR}
if [ "${ENABLE_VALHEIMPLUS}" == "true" ]; then
    echo "---with Valheim Plus---"
    export DOORSTOP_ENABLE=TRUE
    export DOORSTOP_INVOKE_DLL_PATH=${SERVER_DIR}/BepInEx/core/BepInEx.Preloader.dll
    export DOORSTOP_CORLIB_OVERRIDE_PATH=${SERVER_DIR}/unstripped_corlib
    export LD_LIBRARY_PATH="${SERVER_DIR}/doorstop_libs":$LD_LIBRARY_PATH
    export LD_PRELOAD=libdoorstop_x64.so:$LD_PRELOAD
    export DYLD_LIBRARY_PATH="${SERVER_DIR}/doorstop_libs"
    export DYLD_INSERT_LIBRARIES="${SERVER_DIR}/libdoorstop_x64.so"
    export templdpath="$LD_LIBRARY_PATH"
    export LD_LIBRARY_PATH=${SERVER_DIR}/linux64:"$LD_LIBRARY_PATH"
    export SteamAppId=892970
    if [ "${LOG_OUTPUT}" == "true" ]; then
        ${SERVER_DIR}/valheim_server.x86_64 -name "${SRV_NAME}" -port ${GAME_PORT} -world "${WORLD_NAME}" -password "${SRV_PWD}" -public ${PUBLIC} ${GAME_PARAMS} | tee -a ${SERVER_DIR}/${LOG_FILE}
    elif [ "${DEBUG_OUTPUT}" == "true" ]; then
        ${SERVER_DIR}/valheim_server.x86_64 -name "${SRV_NAME}" -port ${GAME_PORT} -world "${WORLD_NAME}" -password "${SRV_PWD}" -public ${PUBLIC} ${GAME_PARAMS}
    else
        ${SERVER_DIR}/valheim_server.x86_64 -name "${SRV_NAME}" -port ${GAME_PORT} -world "${WORLD_NAME}" -password "${SRV_PWD}" -public ${PUBLIC} ${GAME_PARAMS} > /dev/null
    fi
elif [ "${ENABLE_BEPINEX}" == "true" ]; then
    echo "---with BepInEx for Valheim---"
    echo
    echo "---https://valheim.thunderstore.io/package/denikson/BepInExPack_Valheim/---"
    echo
    export DOORSTOP_ENABLE=TRUE
    export DOORSTOP_INVOKE_DLL_PATH=${SERVER_DIR}/BepInEx/core/BepInEx.Preloader.dll
    export DOORSTOP_CORLIB_OVERRIDE_PATH=${SERVER_DIR}/unstripped_corlib
    export LD_LIBRARY_PATH="${SERVER_DIR}/doorstop_libs":$LD_LIBRARY_PATH
    export LD_PRELOAD=libdoorstop_x64.so:$LD_PRELOAD
    export DYLD_LIBRARY_PATH="${SERVER_DIR}/doorstop_libs"
    export DYLD_INSERT_LIBRARIES="${SERVER_DIR}/libdoorstop_x64.so"
    export templdpath="$LD_LIBRARY_PATH"
    export LD_LIBRARY_PATH=${SERVER_DIR}/linux64:"$LD_LIBRARY_PATH"
    export SteamAppId=892970
    if [ "${LOG_OUTPUT}" == "true" ]; then
        ${SERVER_DIR}/valheim_server.x86_64 -name "${SRV_NAME}" -port ${GAME_PORT} -world "${WORLD_NAME}" -password "${SRV_PWD}" -public ${PUBLIC} ${GAME_PARAMS} | tee -a ${SERVER_DIR}/${LOG_FILE}
    elif [ "${DEBUG_OUTPUT}" == "true" ]; then
        ${SERVER_DIR}/valheim_server.x86_64 -name "${SRV_NAME}" -port ${GAME_PORT} -world "${WORLD_NAME}" -password "${SRV_PWD}" -public ${PUBLIC} ${GAME_PARAMS}
    else
        ${SERVER_DIR}/valheim_server.x86_64 -name "${SRV_NAME}" -port ${GAME_PORT} -world "${WORLD_NAME}" -password "${SRV_PWD}" -public ${PUBLIC} ${GAME_PARAMS} > /dev/null
    fi
else
    if [ "${LOG_OUTPUT}" == "true" ]; then
        ${SERVER_DIR}/valheim_server.x86_64 -name "${SRV_NAME}" -port ${GAME_PORT} -world "${WORLD_NAME}" -password "${SRV_PWD}" -public ${PUBLIC} ${GAME_PARAMS} | tee -a ${SERVER_DIR}/${LOG_FILE}
    elif [ "${DEBUG_OUTPUT}" == "true" ]; then
        ${SERVER_DIR}/valheim_server.x86_64 -name "${SRV_NAME}" -port ${GAME_PORT} -world "${WORLD_NAME}" -password "${SRV_PWD}" -public ${PUBLIC} ${GAME_PARAMS}
    else
        ${SERVER_DIR}/valheim_server.x86_64 -name "${SRV_NAME}" -port ${GAME_PORT} -world "${WORLD_NAME}" -password "${SRV_PWD}" -public ${PUBLIC} ${GAME_PARAMS} > /dev/null
    fi
fi