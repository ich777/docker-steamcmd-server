#!/bin/bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${SERVER_DIR}

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
#${SERVER_DIR}/User/Saves
#if [ ! -d ${SERVER_DIR}/Saves ]; then
#    mkdir ${SERVER_DIR}/Saves
#fi
#if grep -rq '<property name="SaveGameFolder"' ${SERVER_DIR}/${SERVERCONFIG}; then
#    if grep -rq '<!-- <property name="SaveGameFolder"' ${SERVER_DIR}/${SERVERCONFIG}; then
#        echo "---Moving SaveGameFolder location---"
#        sed -i '/<!-- <property name="SaveGameFolder"/c\\t<property name="SaveGameFolder"\t\t\t\t\tvalue="/serverdata/serverfiles/Saves" />' ${SERVER_DIR}/${SERVERCONFIG}
#    elif grep -rq 'value="/serverdata/serverfiles/Saves"' ${SERVER_DIR}/${SERVERCONFIG}; then
#        echo "---SaveGameFolder location correct---"
#    fi
#else
#    echo "---Creating SaveGameFolder config ---"
#    sed -i '4i\    <property name="SaveGameFolder" value="/serverdata/serverfiles/Saves" />\' ${SERVER_DIR}/${SERVERCONFIG}
#fi
#echo "---Savegame location found---"

# Remove EOS Cache
if [ -d ${DATA_DIR}/.local/share/.eos_sdk ] ; then
  rm -rf ${DATA_DIR}/.local/share/.eos_sdk
fi

if [ ! -d ${SERVER_DIR}/User ]; then
    mkdir ${SERVER_DIR}/User
fi
if grep -rq '<property name="UserDataFolder"' ${SERVER_DIR}/${SERVERCONFIG}; then
    if grep -rq '<!-- <property name="UserDataFolder"' ${SERVER_DIR}/${SERVERCONFIG}; then
        echo "---Moving UserDataFolder location---"
        sed -i '/<!-- <property name="UserDataFolder"/c\\t<property name="UserDataFolder"\t\t\t\t\tvalue="/serverdata/serverfiles/User" />' ${SERVER_DIR}/${SERVERCONFIG}
    elif grep -rq 'value="/serverdata/serverfiles/User"' ${SERVER_DIR}/${SERVERCONFIG}; then
        echo "---UserDataFolder location correct---"
    fi
else
    echo "---Creating UserDataFolder config ---"
    sed -i '4i\    <property name="UserDataFolder" value="/serverdata/serverfiles/User" />\' ${SERVER_DIR}/${SERVERCONFIG}
fi
echo "---UserDataFolder location found---"

if [ "${ENABLE_BEPINEX}" == "true" ]; then
    echo "---BepInEx enabled!---"
    CUR_V="$(find ${SERVER_DIR} -maxdepth 1 -name "BepInEx-*" | cut -d '-' -f2)"
    LAT_DL_URL="$(wget -qO- https://api.github.com/repos/BepInEx/BepInEx/releases/latest | jq -r '.assets[] | .browser_download_url | match("^.*BepInEx_linux_x64_.*") | .string')"
    LAT_V="$(echo "$LAT_DL_URL" | cut -d '/' -f8)"
    if [ -z "${LAT_V}" ]; then
      if [ -z "${CUR_V}" ]; then
        echo "---Can't get latest version of BepInEx and found no local installed version!---"
        echo "---Please try to run the Container without BepInEx, putting Container into sleep mode!---"
        sleep infinity
      else
        echo "---Can't get latest version of BepInEx!---"
        echo "---Falling back to current installed version: ${CUR_V}!---"
        LAT_V=$CUR_V
      fi
    fi

    if [ -f ${SERVER_DIR}/BepInEx.zip ]; then
	    rm -rf ${SERVER_DIR}/BepInEx.zip
    fi

    echo "---BepInEx Version Check---"
    echo
    echo "---https://github.com/BepInEx/BepInEx---"
    echo
    if [ -z "${CUR_V}" ]; then
        echo "---BepInEx for Valheim not found, downloading and installing v$LAT_V...---"
        cd ${SERVER_DIR}
        if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${SERVER_DIR}/BepInEx.zip "${LAT_DL_URL}" ; then
            echo "---Successfully downloaded BepInEx v$LAT_V---"
        else
            echo "---Something went wrong, can't download BepInEx v$LAT_V, putting container into sleep mode!---"
            sleep infinity
        fi
        unzip -o ${SERVER_DIR}/BepInEx.zip -d ${SERVER_DIR}
	    touch ${SERVER_DIR}/BepInEx-$LAT_V
        rm -rf ${SERVER_DIR}/BepInEx.zip
    elif [ "$CUR_V" != "$LAT_V" ]; then
        echo "---Version missmatch, BepInEx v$CUR_V installed, downloading and installing v$LAT_V...---"
        cd ${SERVER_DIR}
    	rm -rf ${SERVER_DIR}/BepInEx-$CUR_V
        mkdir /tmp/Backup
        cp -R ${SERVER_DIR}/BepInEx/config /tmp/Backup/ 2>/dev/null
        if wget -q -nc --show-progress --progress=bar:force:noscroll -O ${SERVER_DIR}/BepInEx.zip "${LAT_DL_URL}" ; then
            echo "---Successfully downloaded BepInEx v$LAT_V---"
        else
            echo "---Something went wrong, can't download BepInEx v$LAT_V, putting container into sleep mode!---"
            sleep infinity
        fi
        unzip -o ${SERVER_DIR}/BepInEx.zip -d ${SERVER_DIR}
	    touch ${SERVER_DIR}/BepInEx-$LAT_V
        cp -R /tmp/Backup/config ${SERVER_DIR}/BepInEx/ 2>/dev/null
        rm -rf ${SERVER_DIR}/BepInEx.zip /tmp/Backup
    elif [ "${CUR_V}" == "${LAT_V}" ]; then
        echo "---BepInEx v$CUR_V up-to-date---"
    fi
fi

chmod -R ${DATA_PERM} ${DATA_DIR}
screen -wipe 2&>/dev/null
echo "---Server ready---"

if [ "${BACKUP_FILES}" == "true" ]; then
    echo "---Starting Backup daemon---"
    if [ ! -d ${SERVER_DIR}/Backups ]; then
        mkdir -p ${SERVER_DIR}/Backups
    fi
    screen -S backup -d -m /opt/scripts/start-backup.sh
fi

echo "---Start Server---"

GAME_PARAMS=${GAME_PARAMS/-nographics/}
GAME_PARAMS=${GAME_PARAMS/-batchmode/}

cd ${SERVER_DIR}
if [ "${ENABLE_BEPINEX}" == "true" ]; then
    echo "---with BepInEx---"
    echo
    echo "---https://github.com/BepInEx/BepInEx---"
    echo
    export DOORSTOP_ENABLE=TRUE
    export DOORSTOP_INVOKE_DLL_PATH=${SERVER_DIR}/BepInEx/core/BepInEx.Preloader.dll
    if [ ! ${DOORSTOP_CORLIB_OVERRIDE_PATH+x} ]; then
      export DOORSTOP_CORLIB_OVERRIDE_PATH=${SERVER_DIR}/unstripped_corlib
    fi
    export LD_LIBRARY_PATH="${SERVER_DIR}/doorstop_libs":$LD_LIBRARY_PATH
    export LD_PRELOAD=libdoorstop_x64.so:$LD_PRELOAD
    export DYLD_LIBRARY_PATH="${SERVER_DIR}/doorstop_libs"
    export DYLD_INSERT_LIBRARIES="${SERVER_DIR}/libdoorstop_x64.so"
    export templdpath="$LD_LIBRARY_PATH"
    export LD_LIBRARY_PATH=${SERVER_DIR}/linux64:"$LD_LIBRARY_PATH"
    export SteamAppId=251570
    if [ "${LOG_TIMESTAMP}" != "true" ]; then
        ${SERVER_DIR}/7DaysToDieServer.x86_64 -configfile=${SERVERCONFIG} -nographics -batchmode ${GAME_PARAMS}
    else
        ${SERVER_DIR}/7DaysToDieServer.x86_64 -configfile=${SERVERCONFIG} -logfile 7DaysToDie_Data/output_log_$(date +"%F_%H.%M.%S").txt -nographics -batchmode ${GAME_PARAMS}
    fi
else
    if [ "${LOG_TIMESTAMP}" != "true" ]; then
        ${SERVER_DIR}/7DaysToDieServer.x86_64 -configfile=${SERVERCONFIG} -nographics -batchmode ${GAME_PARAMS}
    else
        ${SERVER_DIR}/7DaysToDieServer.x86_64 -configfile=${SERVERCONFIG} -logfile 7DaysToDie_Data/output_log_$(date +"%F_%H.%M.%S").txt -nographics -batchmode ${GAME_PARAMS}
    fi
fi