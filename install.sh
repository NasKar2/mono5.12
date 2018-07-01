#!/bin/sh
# Build an iocage jail under FreeNAS 11.1 with  mono 5.12
# https://github.com/NasKar/mono5.12

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


echo '{"pkgs":["nano","mono","mediainfo","sqlite3","ca_root_nss","curl"]}' > /tmp/pkg.json
iocage create --name "${JAIL_NAME}" -p /tmp/pkg.json -r 11.1-RELEASE ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${DEFAULT_GW_IP}" boot="on" host_hostname="${JAIL_NAME}" vnet="${VNET}"

rm /tmp/pkg.json

mkdir -p ${PORTS_PATH}/ports
mkdir -p ${PORTS_PATH}/db
mkdir -p ${POOL_PATH}/media

iocage exec ${JAIL_NAME} mkdir -p ${PORTS_PATH}/ports
iocage exec ${JAIL_NAME} mkdir -p ${PORTS_PATH}/db
iocage exec ${JAIL_NAME} mkdir -p ${POOL_PATH}/media
iocage exec ${JAIL_NAME} mkdir -p /mnt/configs
iocage fstab -a ${JAIL_NAME} ${PORTS_PATH}/ports /usr/ports nullfs rw 0 0
iocage fstab -a ${JAIL_NAME} ${PORTS_PATH}/db /var/db/portsnap nullfs rw 0 0

iocage fstab -a ${JAIL_NAME} ${CONFIGS_PATH} /mnt/configs nullfs rw 0 0
iocage fstab -a ${JAIL_NAME} ${POOL_PATH}/media /mnt/media nullfs rw 0 0

iocage exec ${JAIL_NAME} "if [ -z /usr/ports ]; then portsnap fetch extract; else portsnap auto; fi"
iocage exec ${JAIL_NAME} -- mkdir -p /tmp/bkup
mv -v /mnt/iocage/jails/${JAIL_NAME}/root/usr/ports/lang/mono/* /mnt/iocage/jails/${JAIL_NAME}/root/tmp/bkup/
iocage exec ${JAIL_NAME} tar zxvf /mnt/configs/mono-5.12.tgz -C /

iocage exec ${JAIL_NAME} make -C /usr/ports/lang/mono deinstall BATCH=yes
iocage exec ${JAIL_NAME} make -C /usr/ports/lang/mono reinstall BATCH=yes
iocage exec ${JAIL_NAME} make -C /usr/ports/lang/mono clean BATCH=yes


iocage restart ${JAIL_NAME}

  
# add media group to media user
#iocage exec ${JAIL_NAME} pw groupadd -n media -g 8675309
#iocage exec ${JAIL_NAME} pw groupmod media -m media
#iocage restart ${JAIL_NAME} 

#remove /mnt/configs
iocage fstab -r ${JAIL_NAME} ${CONFIGS_PATH} /mnt/configs nullfs rw 0 0

# Done!
echo "Installation complete!"
