# SteamCMD in Docker optimized for Unraid
This Docker will download and install SteamCMD. It will also install Survive The Nights and run it. Update Notice: Simply restart the container if a newer version of the game is available.

## Run example
```
docker run -d --restart always -p 7950-7951:7950-7951/udp -e 'GAME_ID=1502300' -e 'UID=99' -e 'GID=100' -v /path/to/steamcmd:/serverdata/steamcmd -v /path/to/survivethenights/serverfiles/:/serverdata/serverfiles --name survivethenights ich777/steamcmd:stn
```
### Variables
* **[--restart](https://docs.docker.com/engine/reference/run/#restart-policies---restart)** always | unless-stopped | on-failure[:max-retries] | no

* **[-p](https://docs.docker.com/engine/reference/commandline/run/#publish-or-expose-port--p---expose)** Maps Host Port(s) to Container Port(s) [HostPorts:ContainerPorts] Don't recommend changing this value unless you know what you're doing.

* **[-e 'GAME_ID=#######'](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file)** Set the [AppID](https://developer.valvesoftware.com/wiki/Dedicated_Servers_List) that Steamcmd will use to install/update/validate the server files. The correct AppID for Survive The Nights is 1502300.

* **[-e 'UID=#######'](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file)** Changes the User used inside container. Unless you are planning to change a majority of the way things work inside the scripts, do not change this value from the default of 99.

* **[-e 'GID=#######'](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file)** Changes the Group used inside container. Unless you are planning to change a majority of the way things work inside the scripts, do not change this value from the default of 100.

* **[-v /path/to/host/steamcmd:/serverdata/steamcmd](https://docs.docker.com/engine/reference/commandline/run/#mount-volume--v---read-only)** Can be excluded. Maps Steamcmd itself to a real folder on the host filesystem. The benefit of doing this is that if you run multiple containers from this image, or others built from different branches in the repository, you can map them all to this folder and only have one copy of Steamcmd rather than tens, hundreds, or even thousands of copies, between all of your containers, needlessly wasting space.

* **[-v /path/to/host/survivethenights/serverfiles/:/serverdata/serverfiles](https://docs.docker.com/engine/reference/commandline/run/#mount-volume--v---read-only)** Should **not** be excluded, but can be. This maps the server files that store your server information. If your container is removed, the server files will be preserved to whatever path you /path/to/host/ on the host machine so you don't lose your world. __If you restart your container, and your world is gone because you excluded this, no one here can help you recover your data.__

* **[--name survivethenights](https://docs.docker.com/engine/reference/commandline/run/#assign-name-and-allocate-pseudo-tty---name--it)** Should **not** be excluded, but can be. Assigns the given name to the container. A random name will be assigned by docker if this is not provided.

---

This Docker was mainly edited for better use with Unraid, if you don't use Unraid you should definitely try it! This specific branch for Survive The Nights has also been tested successfully in an Archlinux environment.

This Docker is forked from mattieserver, thank you for this wonderfull Docker.