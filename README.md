# SteamCMD in Docker optimized for Unraid
This Docker will download and install SteamCMD. It will also install Palworld and run it.

Initial Servername: 'Palworld Docker' Password: '54321'

**Update Notice:** Simply restart the container if a newer version of the game is available.

## Example Env params for CS:Source
| Name | Value | Example |
| --- | --- | --- |
| STEAMCMD_DIR | Folder for SteamCMD | /serverdata/steamcmd |
| SERVER_DIR | Folder for gamefile | /serverdata/serverfiles |
| GAME_ID | The GAME_ID that the container downloads at startup. If you want to install a static or beta version of the game change the value to: '1670340 -beta YOURBRANCH' (without quotes, replace YOURBRANCH with the branch or version you want to install). | 1670340 |
| GAME_PARAMS | Extra parameters to start the server | empty |
| UID | User Identifier | 99 |
| GID | Group Identifier | 100 |
| VALIDATE | Validates the game data | true |
| USERNAME | Leave blank for anonymous login | empty |
| PASSWRD | Leave blank for anonymous login | empty |

## Run example
```
docker run --name Palworld -d \
	-p 8787:8787 -p 8787:8787/udp \
	--env 'GAME_ID=1670340' \
	--env 'UID=99' \
	--env 'GID=100' \
	--volume /path/to/steamcmd:/serverdata/steamcmd \
	--volume /path/to/craftopia:/serverdata/serverfiles \
	xcyrex/steamcmd:palworld
```

This Docker was mainly edited for better use with Unraid, if you don't use Unraid you should definitely try it!


This Docker is forked from mattieserver, thank you for this wonderfull Docker.
