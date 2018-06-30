# mono5.12

Script to create an iocage jail on Freenas 11.1U4 from scratch with Mono 5.12.  
### Prerequisites
Edit mono-config file with your network information.  Then run these commands
Create file mono-config
```
-JAIL_IP="192.168.5.55"
-DEFAULT_GW_IP="192.168.5.1"
-INTERFACE="igb0"
-VNET="off"
-POOL_PATH="/mnt/v1"
-JAIL_NAME="mono"
-SONARR_DATA="sonarrgit"
-RADARR_DATA="radarrgit"
-LIDARR_DATA="lidarrgit"
-SABNZBD_DATA="sabnzbdgit"
```

```
./install.sh
```
to create an iocage jail with mono 5.12

## Install Apps
Install Sonarr, Radarr, Lidarr and Sabnzbd to the same jail by running
```
./appinstall.sh
```
### Prerequisites
Set the name of the directory for the apps data in the mono-config file.
