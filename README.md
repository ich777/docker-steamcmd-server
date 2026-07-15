# SteamCMD in Docker optimized for Unraid
This Docker will download and install SteamCMD. It will also install Runescape: Dragonwilds and run it.

**Please see the different Tags/Branches which games are available.**

## Example Env params for Runescape: Dragonwilds
| Name | Value | Example |
| --- | --- | --- |
| STEAMCMD_DIR | Folder for SteamCMD | /serverdata/steamcmd |
| SERVER_DIR | Folder for gamefile | /serverdata/serverfiles |
| GAME_ID | The GAME_ID that the container downloads at startup. If you want to install a static or beta version of the game change the value to: '4019830 -beta YOURBRANCH' (without quotes, replace YOURBRANCH with the branch or version you want to install). | 4019830 |
| GAME_PARAMS | Values to start the server | -log -NewConsole |
| OWNERID | Change to your owner ID, which can be found in the Settings window | changeme |
| SERVERNAME | Name of your Server | DockerRunescape |
| DEFAULTWORLDNAME | Name of your .sav file | DockerRunescape |
| ADMINPASSWORD | Admin password | changeme |
| WORLDPASSWORD | World password (Optional) | changeme |
| UID | User Identifier | 99 |
| GID | Group Identifier | 100 |
| GAME_PORT | Port the server will be running on | 7777 |
| VALIDATE | Validates the game data | blank |
| USERNAME | Leave blank for anonymous login | blank |
| PASSWRD | Leave blank for anonymous login | blank |

## Run example for Runescape: Dragonwilds
```
docker run --name RSDragonwilds -d \
	-p 27015:27015 -p 27015:27015/udp \
	--env 'GAME_ID=4019830' \
	--env 'GAME_PORT=7777' \
	--env 'GAME_PARAMS=-log -NewConsole' \
	--env 'OWNERID="changeme"' \
	--env 'SERVERNAME="DockerRunescape"' \
	--env 'DEFAULTWORLDNAME="DockerRunescape"' \
	--env 'ADMINPASSWORD="changeme"' \
	--env 'WORLDPASSWORD="changeme"' \
	--env 'UID=99' \
	--env 'GID=100' \
	--volume /path/to/steamcmd:/serverdata/steamcmd \
	--volume /path/to/rsdragonwilds:/serverdata/serverfiles \
	ich777/steamcmd:rsdragonwilds
```

#### Note: (Please read)
You need to generate a .sav file by creating a world in a single player environment first
For some reason the linux server files do not generate a save file on first run, and you need to copy your .sav file into the folder below:
/path/to/rsdragonwilds/RSDragonwilds/Saved/SavedGames

This Docker was mainly edited for better use with Unraid, if you don't use Unraid you should definitely try it!

This Docker is forked from mattieserver, thank you for this wonderfull Docker.

#### Support Thread: https://forums.unraid.net/topic/79530-support-ich777-gameserver-dockers/
