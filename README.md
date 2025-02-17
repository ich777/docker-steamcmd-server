# SteamCMD in Docker optimized for Unraid
This Docker will download and install SteamCMD. It will also install LOTR:Return to Moria and run it.

Initial server configuration:  
**Servername:** Docker Return to Moria **Password:** Docker

**Configuration:** You'll find the configuration file in the main directory for the container: MoriaServerConfig.ini

**Save Path:** The path for your game saves is: .../returntomoria/Moria/Saved

**ATTENTION:** First startup can take very long since it downloads the gameserver files and it also installs the runtimes which can take quite some time! 

Update Notice: Simply restart the container if a newer version of the game is available.

## Example Env params
| Name | Value | Example |
| --- | --- | --- |
| STEAMCMD_DIR | Folder for SteamCMD | /serverdata/steamcmd |
| SERVER_DIR | Folder for gamefile | /serverdata/serverfiles |
| GAME_ID | The GAME_ID that the container downloads at startup. If you want to install a static or beta version of the game change the value to: '3349480 -beta YOURBRANCH' (without quotes, replace YOURBRANCH with the branch or version you want to install). | 3349480 |
| GAME_PARAMS | Values to start the server | *empty* |
| UID | User Identifier | 99 |
| GID | Group Identifier | 100 |
| GAME_PORT | Port the server will be running on | 7777 |
| VALIDATE | Validates the game data | false |
| USERNAME | Leave blank for anonymous login | blank |
| PASSWRD | Leave blank for anonymous login | blank |

## Run example
```
docker run --name ReturnToMoria -d \
	-p 7777:7777/udp \
	--env 'GAME_ID=3349480' \
	--env 'UID=99' \
	--env 'GID=100' \
	--volume /path/to/steamcmd:/serverdata/steamcmd \
	--volume /path/to/returntomoria:/serverdata/serverfiles \
	ich777/steamcmd:lotr-returntomoria
```

This Docker was mainly edited for better use with Unraid, if you don't use Unraid you should definitely try it!

This Docker is forked from mattieserver, thank you for this wonderfull Docker.

#### Support Thread: https://forums.unraid.net/topic/79530-support-ich777-gameserver-dockers/