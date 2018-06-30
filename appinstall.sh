#!/bin/sh
# Build an iocage jail under FreeNAS 11.1 using the current release of mono 13
# https://github.com/danb35/freenas-iocage-mono

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Initialize defaults
JAIL_IP=""
DEFAULT_GW_IP=""
INTERFACE=""
VNET="off"
POOL_PATH=""
JAIL_NAME="mono"
PORTS_PATH=""
SONARR_DATA=""
RADARR_DATA=""
LIDARR_DATA=""
SABNZBD_DATA=""


SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
. $SCRIPTPATH/mono-config
CONFIGS_PATH=$SCRIPTPATH/configs

# Check for mono-config and set configuration
if ! [ -e $SCRIPTPATH/mono-config ]; then
  echo "$SCRIPTPATH/mono-config must exist."
  exit 1
fi

# Check that necessary variables were set by mono-config
if [ -z $JAIL_IP ]; then
  echo 'Configuration error: JAIL_IP must be set'
  exit 1 
fi
 if [ -z $DEFAULT_GW_IP ]; then
  echo 'Configuration error: DEFAULT_GW_IP must be set'
  exit 1
fi

if [ -z $INTERFACE ]; then
  echo 'Configuration error: INTERFACE must be set'
  exit 1
fi

if [ -z $POOL_PATH ]; then
  echo 'Configuration error: POOL_PATH must be set'
  exit 1
fi

if [ -z $PORTS_PATH ]; then
  PORTS_PATH="${POOL_PATH}/portsnap"
fi


#echo '{"pkgs":["nano","mono","mediainfo","sqlite3","ca_root_nss","curl"]}' > /tmp/pkg.json
#iocage create --name "${JAIL_NAME}" -p /tmp/pkg.json -r 11.1-RELEASE ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${DEFAULT_GW_IP}" boot="on" host_hostname="${JAIL_NAME}" vnet="${VNET}"

#rm /tmp/pkg.json

#if [ -z ${POOL_PATH}/apps ]; then
   mkdir -p ${POOL_PATH}/apps/${SONARR_DATA}
   mkdir -p ${POOL_PATH}/apps/${RADARR_DATA}
   mkdir -p ${POOL_PATH}/apps/${LIDARR_DATA}
   mkdir -p ${POOL_PATH}/apps/${SABNZBD_DATA}
#fi
sonarr_config=${POOL_PATH}/apps/${SONARR_DATA}
radarr_config=${POOL_PATH}/apps/${RADARR_DATA}
lidarr_config=${POOL_PATH}/apps/${LIDARR_DATA}
sabnzbd_config=${POOL_PATH}/apps/${SABNZBD_DATA}

iocage fstab -a ${JAIL_NAME} ${POOL_PATH}/apps /config nullfs rw 0 0
iocage fstab -a ${JAIL_NAME} ${POOL_PATH}/torrents /mnt/torrents nullfs rw 0 0
#if [ ! -d "/mnt/iocage/jails/${JAIL_NAME}/root/mnt/configs" ]; then
   iocage fstab -a ${JAIL_NAME} ${CONFIGS_PATH} /mnt/configs nullfs rw 0 0
#fi

chown media:media $sonarr_config/
chown media:media $radarr_config/
chown media:media $lidarr_config/
chown media:media $sabnzbd_config/

#iocage exec ${JAIL_NAME} chown media:media /config/sonarr
#iocage exec ${JAIL_NAME} chown media:media /config/radarr
#iocage exec ${JAIL_NAME} chown media:media /config/lidarr
#iocage exec ${JAIL_NAME} chown media:media /config/sabnzbd

iocage exec ${JAIL_NAME} mkdir -p /mnt/torrents/sabnzbd/incomplete
iocage exec ${JAIL_NAME} mkdir -p /mnt/torrents/sabnzbd/complete
iocage exec ${JAIL_NAME} ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec ${JAIL_NAME} "fetch https://github.com/Radarr/Radarr/releases/download/v0.2.0.995/Radarr.develop.0.2.0.995.linux.tar.gz -o /usr/local/share"
iocage exec ${JAIL_NAME} "tar -xzvf /usr/local/share/Radarr.*.linux.tar.gz -C /usr/local/share"
iocage exec ${JAIL_NAME} rm /usr/local/share/Radarr.develop.0.2.0.995.linux.tar.gz
iocage exec ${JAIL_NAME} "pw user add media -c media -u 8675309  -d /nonexistent -s /usr/bin/nologin"

pw groupadd -n media -g 8675309
pw groupmod media -m media


iocage exec ${JAIL_NAME} chown -R media:media /usr/local/share/Radarr /config/radarr
iocage exec ${JAIL_NAME} -- mkdir /usr/local/etc/rc.d
iocage exec ${JAIL_NAME} cp -f /mnt/configs/radarr /usr/local/etc/rc.d/radarr
iocage exec ${JAIL_NAME} chmod u+x /usr/local/etc/rc.d/radarr
iocage exec ${JAIL_NAME} sed -i '' "s/radarrgit/${RADARR_DATA}/" /usr/local/etc/rc.d/radarr
iocage exec ${JAIL_NAME} sysrc "radarr_enable=YES"
iocage exec ${JAIL_NAME} service radarr start
echo "Radarr should be available at http://${JAIL_IP}:7878"


#iocage exec ${JAIL_NAME} ln -s /usr/local/bin/mono /usr/bin/mono
iocage exec ${JAIL_NAME} "fetch http://download.sonarr.tv/v2/master/mono/NzbDrone.master.tar.gz -o /usr/local/share"
iocage exec ${JAIL_NAME} "tar -xzvf /usr/local/share/NzbDrone.master.tar.gz -C /usr/local/share"
iocage exec ${JAIL_NAME} -- rm /usr/local/share/NzbDrone.master.tar.gz
#iocage exec ${JAIL_NAME} "pw user add media -c media -u 8675309  -d /nonexistent -s /usr/bin/nologin"
  
#pw groupadd -n GROUP -g GID
#pw groupmod GROUP -m USER


iocage exec ${JAIL_NAME} chown -R media:media /usr/local/share/NzbDrone /config/sonarr
#iocage exec ${JAIL_NAME} -- mkdir /usr/local/etc/rc.d
iocage exec ${JAIL_NAME} cp -f /mnt/configs/sonarr /usr/local/etc/rc.d/sonarr
iocage exec ${JAIL_NAME} chmod u+x /usr/local/etc/rc.d/sonarr
iocage exec ${JAIL_NAME} sed -i '' "s/sonarrgit/${SONARR_DATA}/" /usr/local/etc/rc.d/sonarr
iocage exec ${JAIL_NAME} sysrc "sonarr_enable=YES"
iocage exec ${JAIL_NAME} service sonarr start
echo "Sonarr should be available at http://${JAIL_IP}:8989"

iocage exec ${JAIL_NAME} "fetch https://github.com/lidarr/Lidarr/releases/download/v0.2.0.371/Lidarr.develop.0.2.0.371.linux.tar.gz -o /usr/local/share"
iocage exec ${JAIL_NAME} "tar -xzvf /usr/local/share/Lidarr.develop.*.linux.tar.gz -C /usr/local/share"
iocage exec ${JAIL_NAME} rm /usr/local/share/Lidarr.develop.0.2.0.371.linux.tar.gz
#iocage exec ${JAIL_NAME} "pw user add lidarr -c lidarr -u 353 -d /nonexistent -s /usr/bin/nologin"
iocage exec ${JAIL_NAME} chown -R media:media /usr/local/share/Lidarr /config/lidarr
iocage exec ${JAIL_NAME} mkdir /usr/local/etc/rc.d

iocage exec ${JAIL_NAME} cp -f /mnt/configs/lidarr /usr/local/etc/rc.d/lidarr

iocage exec ${JAIL_NAME} chmod u+x /usr/local/etc/rc.d/lidarr
iocage exec ${JAIL_NAME} sed -i '' "s/lidarrgit/${LIDARR_DATA}/" /usr/local/etc/rc.d/lidarr
iocage exec ${JAIL_NAME} sysrc "lidarr_enable=YES"
iocage exec ${JAIL_NAME} service lidarr start

echo "lidarr should be available at http://${JAIL_IP}:8686"
iocage exec ${JAIL_NAME} mkdir -p /usr/local/etc/pkg/repos/
iocage exec ${JAIL_NAME} cp -f /mnt/configs/FreeBSD.conf /usr/local/etc/pkg/repos/FreeBSD.conf
iocage exec ${JAIL_NAME} update
iocage exec ${JAIL_NAME} upgrade
iocage restart ${JAIL_NAME}
iocage exec ${JAIL_NAME} pkg install sabnzbdplus
iocage exec ${JAIL_NAME} ln -s /usr/local/bin/python2.7 /usr/bin/python
iocage exec ${JAIL_NAME} ln -s /usr/local/bin/python2.7 /usr/bin/python2

iocage exec ${JAIL_NAME} "pw groupmod media -m _sabnzbd"
iocage exec ${JAIL_NAME} chown -R media:media /mnt/torrents/sabnzbd /config/${SABNZBD_DATA}
iocage exec ${JAIL_NAME} sysrc "sabnzbd_user=media"
iocage exec ${JAIL_NAME} sysrc sabnzbd_enable=YES
iocage exec ${JAIL_NAME} sysrc sabnzbd_conf_dir="/config/${SABNZBD_DATA}"
iocage exec ${JAIL_NAME} cp -f /mnt/configs/sabnzbd /usr/local/etc/rc.d/sabnzbd
iocage exec ${JAIL_NAME} sed -i '' "s/sabnzbdgit/${SABNZBD_DATA}/" /usr/local/etc/rc.d/sabnzbd
iocage restart ${JAIL_NAME}
iocage exec ${JAIL_NAME} service sabnzbd start
iocage exec ${JAIL_NAME} service sabnzbd stop
iocage exec ${JAIL_NAME} sed -i '' -e 's?host = 127.0.0.1?host = 0.0.0.0?g' /config/${SABNZBD_DATA}/sabnzbd.ini
iocage exec ${JAIL_NAME} sed -i '' -e 's?download_dir = Downloads/incomplete?download_dir = /mnt/torrents/sabnzbd/incomplete?g' /config/${SABNZBD_DATA}/sabnzbd.ini
iocage exec ${JAIL_NAME} sed -i '' -e 's?complete_dir = Downloads/complete?complete_dir = /mnt/torrents/sabnzbd/complete?g' /config/${SABNZBD_DATA}/sabnzbd.ini
iocage exec ${JAIL_NAME} service sabnzbd start
echo "sabnzbd should be available at http://${JAIL_IP}:8080/sabnzbd"
