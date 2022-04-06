#!/bin/bash

UIDMode="false"
if [ "$EUID" -eq 0 ]
  UIDMode="true"
  echo "---Checking if UID: ${UID} matches user---"
  usermod -u ${UID} ${USER}
  echo "---Checking if GID: ${GID} matches user---"
  groupmod -g ${GID} ${GROUP} 
  usermod -g ${GID} ${USER}
fi

echo "---Setting umask to ${UMASK}---"
umask ${UMASK}

echo "---Checking for optional scripts---"
if [ -f /opt/scripts/user.sh ]; then
	echo "---Found optional script, executing---"
    chmod +x /opt/scripts/user.sh
    /opt/scripts/user.sh
else
	echo "---No optional script found, continuing---"
fi

echo "---Taking Ownership...---"
if [ "$UIDMode" == "true" ]
  chown -R root:${GID} /opt/scripts
  chmod -R 750 /opt/scripts
  chown -R ${UID}:${GID} ${DATA_DIR}
fi

echo "---Starting...---"
term_handler() {
	kill -SIGTERM "$killpid"
	wait "$killpid" -f 2>/dev/null
	exit 143;
}

trap 'kill ${!}; term_handler' SIGTERM

if [ "$UIDMode" == "true" ]
  su ${USER} -c "/opt/scripts/start-server.sh" &
else
  /opt/scripts/run/start-server.sh &
fi
killpid="$!"
while true
do
	wait $killpid
	exit 0;
done
