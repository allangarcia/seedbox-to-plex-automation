#!/bin/bash
echo ""
echo "=========================================================================================="
echo "Atualizando..."
echo "=========================================================================================="
echo ""

apt update
apt -y upgrade
apt dist-upgrade

echo ""
echo "=========================================================================================="
echo "Added a PMS repository and installed with those commands"
echo "=========================================================================================="
echo ""

wget -O - https://dev2day.de/pms/dev2day-pms.gpg.key | apt-key add -
echo "deb https://dev2day.de/pms/ jessie main" | tee /etc/apt/sources.list.d/pms.list
apt update
apt install plexmediaserver

echo ""
echo "=========================================================================================="
echo "Then I installed my seedbox packages"
echo "=========================================================================================="
echo ""

apt install -y deluged deluge-console deluge-web
sed -i "s/ENABLE_DELUGED=0/ENABLE_DELUGED=1/" /etc/default/deluged
service deluged restart

echo "deluged:deluged:10" >> /var/lib/deluged/config/auth

echo ""
echo "=========================================================================================="
echo "No init script is provided for deluge-web package unfortunately, so install mine. ;-D"
echo "=========================================================================================="
echo ""

cd /etc/systemd/system/
wget https://gist.github.com/allangarcia/146e8db29e5d45766aee16043e7fb347/raw/fce670ac72db3957029d4e1c02ae8603c4156abc/deluge-web.service
systemctl enable deluge-web
systemctl start deluge-web
systemctl status deluge-web

echo ""
echo "=========================================================================================="
echo "Then I installed additional packages"
echo "=========================================================================================="
echo ""

apt install -y --no-install-recommends oracle-java8-jdk git rsync vim htop mediainfo youtube-dl

echo ""
echo "=========================================================================================="
echo "Add some users to sudo 'cause some scripts require root access"
echo "=========================================================================================="
echo ""

sed -i "s/^%sudo.*/%sudo\tALL=(ALL) NOPASSWD: ALL/" /etc/sudoers
adduser debian-deluged sudo

cd /opt

echo ""
echo "=========================================================================================="
echo "Installing Filebot"
echo "=========================================================================================="
echo ""

mkdir -p /opt/filebot
cd /opt/filebot
sh -xu <<< "$(curl -fsSL https://raw.githubusercontent.com/filebot/plugins/master/installer/portable.sh)"
/opt/filebot/filebot.sh

echo ""
echo "=========================================================================================="
echo "Installing Sickrage"
echo "=========================================================================================="
echo ""

cd /opt
addgroup --system sickrage
adduser --disabled-password --system --home /var/lib/sickrage --gecos "SickRage" --ingroup sickrage sickrage
git clone https://github.com/SickRage/SickRage.git sickrage
chown -R sickrage.sickrage /opt/sickrage
cp /opt/sickrage/runscripts/init.debian /etc/init.d/sickrage
chown root.root /etc/init.d/sickrage
chmod 755 /etc/init.d/sickrage
update-rc.d sickrage defaults
mkdir -p /var/run/sickrage
chown sickrage.sickrage /var/run/sickrage
service sickrage start


echo ""
echo "=========================================================================================="
echo "Installing Couchpotato"
echo "=========================================================================================="
echo ""

cd /opt
addgroup --system couchpotato
adduser --disabled-password --system --home /var/lib/couchpotato --gecos "CouchPotato" --ingroup couchpotato couchpotato
git clone https://github.com/CouchPotato/CouchPotatoServer.git couchpotato
chown -R couchpotato.couchpotato /opt/couchpotato
cp couchpotato/init/ubuntu /etc/init.d/couchpotato
chown root.root /etc/init.d/couchpotato
chmod 755 /etc/init.d/couchpotato
update-rc.d couchpotato defaults
mkdir -p /var/run/couchpotato
chown couchpotato.couchpotato /var/run/couchpotato
service couchpotato start

echo ""
echo "=========================================================================================="
echo "Clone this project! This will do so much for you..."
echo "=========================================================================================="
echo ""

cd /opt
git clone https://github.com/allangarcia/seedbox-to-plex-automation.git scripts


echo ""
echo "=========================================================================================="
echo "DONE! Now Mount your external media"
echo "=========================================================================================="
echo ""
