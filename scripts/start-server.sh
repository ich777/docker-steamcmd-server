#!/bin/bash
if [ "$GAME_NAME" == "tf" ] ; then 
    echo "Fetching required files for TeamFortress2"
    apt-get -y lib32gcc1 ia32-libs
fi

exec su - steam -c "$*"

if [ ! -f ${STEAMCMD_DIR}/steamcmd.sh ]; then
    echo "Steamcmd not found!"
    wget -q -O ${STEAMCMD_DIR}/steamcmd_linux.tar.gz http://media.steampowered.com/client/steamcmd_linux.tar.gz 
    tar --directory ${STEAMCMD_DIR} -xvzf /serverdata/steamcmd/steamcmd_linux.tar.gz
    rm ${STEAMCMD_DIR}/steamcmd_linux.tar.gz
fi

echo "---Update steamcmd---"
${STEAMCMD_DIR}/steamcmd.sh \
    +login anonymous \
    +quit
    
echo "---Update server---"
${STEAMCMD_DIR}/steamcmd.sh \
    +login anonymous \
    +force_install_dir $SERVER_DIR \
    +app_update $GAME_ID \
    +quit

echo "---Prepare Server---"
mkdir ${DATA_DIR}/.steam/sdk32
cp -R ${SERVER_DIR}/bin/* ${DATA_DIR}/.steam/sdk32/
   
echo "---Start Server---"
${SERVER_DIR}/srcds_run -game $GAME_NAME $GAME_PARAMS -console +port $GAME_PORT
