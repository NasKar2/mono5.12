# mono5.12

Script to create an iocage jail on Freenas 11.1U4 from scratch with Mono 5.12. Update an existing jail and install sonarr, radarr, lidarr and sabnzbd.  

Thanks to chippy in freenas forums for getting mono 5.12 working https://forums.freenas.org/index.php?threads/problem-with-updating-radarr.62447/#post-461427

### Prerequisites
Create file mono-config

Edit mono-config file with your network information and directory data name you want to use
```
JAIL_IP="192.168.5.55"
DEFAULT_GW_IP="192.168.5.1"
INTERFACE="igb0"
VNET="off"
POOL_PATH="/mnt/v1"
JAIL_NAME="mono"
SONARR_DATA="sonarrdata"
RADARR_DATA="radarrdata"
LIDARR_DATA="lidarrdata"
SABNZBD_DATA="sabnzbddata"
MEDIA_LOCATION="media"
TORRENT_LOCATION="torrents"
```
## Install Mono 5.12 in fresh Jail

Create an iocage jail with Mono 5.12, nano, mediainfo, sqlite3, ca_root_nss, and curl. These are the dependencies need to install sonarr, radarr, and lidarr.

Then run these commands
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

## Update Jail

### Update an existing iocage jail to Mono 5.12

```
./update.sh
```
