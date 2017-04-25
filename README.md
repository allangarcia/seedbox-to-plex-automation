# seedbox-to-plex-automation
Collection of bash scripts to automate my Plex + Deluge + CouchPotato + SickRage

# The FLOW works like this

```
[ CouchPotato (Movies) ] - \
                            \                                          
                             \                              / - > [ FileBot ] - \
                              \                            /                     \
[ Manually ] - - - - - - > [ Deluged ] - > [ Scripts! ] - |                       | - > [ Plex ]
                              /                            \                     /
                             /                              \ - > [ Trailer ] - /
                            /
 [ SickRage (TV Shows) ] - /
```

# How did I installed my Plex on Raspberry Pi 3?

## This is my hardware

- I'm using a Raspberry Pi 3 Model B (https://www.raspberrypi.org/products/raspberry-pi-3-model-b/)
- You'll probably want an attached storage or a network one to store your media files

## I choose the easy one for the Operational System

- I'm using a NOOBs Lite version installer (https://www.raspberrypi.org/downloads/noobs/) and doing a Raspbian Lite (minimal) install
- Default user "pi", default password "raspberry"

PS: No SSH access this first time

- Using the console start raspbian configuration tool

```
$ sudo raspi-config
```

- Things to consider to configure

  - Change default passwords
  - Change hostname
  - Enable SSH in "Interfacing Options"
  - Update
  - Maybe you want to create your own user after reboot

## Beginning the installation

- After Raspbian Lite install I did a full update as always

```
# apt update
# apt upgrade
# apt dist-upgrade
```

- Added a PMS repository and installed with those commands

```
# wget -O - https://dev2day.de/pms/dev2day-pms.gpg.key | apt-key add -
# echo "deb https://dev2day.de/pms/ jessie main" | tee /etc/apt/sources.list.d/pms.list
# apt update
# apt install plexmediaserver
```

- Then I installed my seedbox packages

```
# apt install deluged deluge-console deluge-web
# sed -i "s/ENABLE_DELUGED=0/ENABLE_DELUGED=1/" /etc/default/deluged
# service deluged restart
```
PS: Make sure the service is started before next command
```
# echo "deluged:deluged:10" >> /var/lib/deluged/config/auth
```

PS: No init script is provided for __deluge-web__ package unfortunately, so install mine. ;-D

```
# cd /etc/systemd/system/
# wget https://gist.github.com/allangarcia/146e8db29e5d45766aee16043e7fb347/raw/fce670ac72db3957029d4e1c02ae8603c4156abc/deluge-web.service
# systemctl enable deluge-web
# systemctl start deluge-web
# systemctl status deluge-web
```

- Then I installed additional packages

```
# apt install --no-install-recommends oracle-java8-jdk git rsync vim htop mediainfo youtube-dl
```

- Add some users to sudo 'cause some scripts require root access

```
# sed -i "s/^%sudo.*/%sudo\tALL=(ALL) NOPASSWD: ALL/" /etc/sudoers
# adduser debian-deluged sudo
```

## Download the raw stuff

- I install all my non distro things on /opt

```
# cd /opt
```

- Filebot! This is the best renaming tool (don't fool yourself by enabling rename on other tools)

```
# mkdir -p /opt/filebot
# cd /opt/filebot
# sh -xu <<< "$(curl -fsSL https://raw.githubusercontent.com/filebot/plugins/master/installer/portable.sh)"
# /opt/filebot/filebot.sh
```

- Sickrage! I use this only to get .torrent file into deluge Inbox folder

```
# cd /opt
# addgroup --system sickrage
# adduser --disabled-password --system --home /var/lib/sickrage --gecos "SickRage" --ingroup sickrage sickrage
# git clone https://github.com/SickRage/SickRage.git sickrage
# chown -R sickrage.sickrage /opt/sickrage
# cp /opt/sickrage/runscripts/init.debian /etc/init.d/sickrage
# chown root.root /etc/init.d/sickrage
# chmod 755 /etc/init.d/sickrage
# update-rc.d sickrage defaults
# mkdir -p /var/run/sickrage
# chown sickrage.sickrage /var/run/sickrage
# service sickrage start
```

PS: The first start takes a little longer

- Couchpotato! Same thing as Sickrage for movies

```
# cd /opt
# addgroup --system couchpotato
# adduser --disabled-password --system --home /var/lib/couchpotato --gecos "CouchPotato" --ingroup couchpotato couchpotato
# git clone https://github.com/CouchPotato/CouchPotatoServer.git couchpotato
# chown -R couchpotato.couchpotato /opt/couchpotato
# cp couchpotato/init/ubuntu /etc/init.d/couchpotato
# chown root.root /etc/init.d/couchpotato
# chmod 755 /etc/init.d/couchpotato
# update-rc.d couchpotato defaults
# mkdir -p /var/run/couchpotato
# chown couchpotato.couchpotato /var/run/couchpotato
# service couchpotato start
```

- Clone this project! This will do so much for you...

```
# cd /opt
# git clone https://github.com/allangarcia/seedbox-to-plex-automation.git scripts
```

## Mount your external media

- Make your mountpoint

```
# mkdir -p /mnt/media
```

- Plug your device, wipe the partition table, make a new partition and filesystem

**PS: DON'T DO THIS IF YOU ALREADY HAVE MEDIA FILES, DON'T BE STUPID!!!**

```
# fdisk /dev/sda
# mkfs.ext4 /dev/sda1
```

- Get the UUID of your new partition, and write down (CTRL+C!) the UUID= part

```
# blkid /dev/sda1
```

```
/dev/sda1: UUID="a01e4f27-1f10-42dc-bf94-a4e48d7b9bfe" TYPE="ext4" PARTUUID="5850a332-01"
```

- Download the mount file for systemd

```
# cd /etc/systemd/system
# wget https://gist.github.com/allangarcia/203e7d57e5e213b54f73509c24e089df/raw/6fff42aca4c1e88478f1f52ec34d8660178d5a21/mnt-media.mount
```

- Edit this file and change the UUID part for your UUID copied previously

```
# sed -i "s/by-uuid\/.*/by-uuid\/YOUR-UUID-GOES-HERE/" mnt-media.mount
```

- Reload systemd daemon, enable the service and start it

```
# systemctl daemon-reload
# systemctl enable mnt-media.mount
# systemctl start mnt-media.mount
# systemctl status mnt-media.mount
```

- Make directories to hold your downloads

```
# cd /mnt/media
# mkdir Torrents
# cd Torrents
# mkdir Completed Downloading Inbox
# chmod 777 Inbox
# cd /mnt/media
# chown -R debian-deluged.debian-deluged Torrents
```

- Make directories to hold your media

```
# cd /mnt/media
# mkdir Movies TV\ Shows
# chown -R plex: Movies
# chown -R plex: TV\ Shows
```

- Export to env the place of your media

```
# echo MEDIA_PATH=/mnt/media >> /etc/environment
```

## Configuration

- Configure filebot to autenticate into opensubtitles

```
# /opt/filebot/filebot.sh -script fn:configure
Enter OpenSubtitles username: YOUR USERNAME
Enter OpenSubtitles password: YOUR PASSWORD
Testing OpenSubtitles... OK
Done ヾ(＠⌒ー⌒＠)ノ
```

- Configure your TMDB API key to autenticate into the site

PS: This is a required for trailers to work

```
# echo TMDB_KEY="PUT_YOUR_THEMOVIEDB_API_KEY_HERE" >> /etc/environment
```

- Configure plex to index your media on previouly created media directories

This article may be helpful: https://support.plex.tv/hc/en-us/articles/200264746-Quick-Start-Step-by-Step-Guides

- Enable cron-process script

```
# echo -e "00 10\t* * *\troot\t/opt/scripts/cron-process.sh" >> /etc/crontab
```

- Configuring Deluge

Point your browser to http://<YOUR_RPI3_IP>:8112/

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20A1.png)

You have to login with the default password "deluge"

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20A2.png)

Change your password on first login

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20A3.png)

Choose a better password or NONE, if you don't care about security

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20A4.png)

The connection should work fine, but if not, configure the connection

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20B1.png)

Use deluged, deluged as user and password on localhost

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20B2.png)

Then the conection should work

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20B3.png)

Configure the directories as shown

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20C1.png)

Enable the plugin "execute"

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20D1.png)

Configure plugin "execute"

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20D2.png)

Add a new event

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20D3.png)

Choose "On Complete" and configure the script "auto-process.sh"

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20D4.png)

Should look like this

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20D5.png)

Configure bandwith accordinly to your connection speed, mine works fine like this.

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20E1.png)

Configure stop seeding after certain ratio, for me 1 (one) is ok, mark remove after ratio

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20F1.png)

- Configure CouchPotato

Point your browser to http://<YOUR_RPI3_IP>:5050/

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20G1.png)

Enable only Black Hole downloader

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20G2.png)

Enable you preffered search provider, I preffer YTS

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20G3.png)

Go to settings

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20G4.png)

Searcher

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20G5.png)

Quality Profiles

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20G6.png)

Enable "Show advanced", and go to sizes

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20G7.png)

Change 1080p to min 800 and 720p to min 500, this is only if you use YTS provider

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20G8.png)

- Configuring sickrage

Point your browser to http://<YOUR_RPI3_IP>:8081/

Go to Configuration -> General Configuration -> Misc

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20H1.png)

On "Show root directories" put your configured media directory for shows

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20H2.png)

On Search Settings disable NZB Search (I'm using only torrent)

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20I1.png)

Enable Torrent and send files to Black Hole like image bellow

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20I2.png)

Enable your preffered provider, mine is RARBG for TV Shows, move to top.

![](https://github.com/allangarcia/seedbox-to-plex-automation/raw/master/docs/Tela%20I3.png)

- After all this configuration your seedbox should work perfectly, any suggestion is appreciated. If your maded 'til here leave a comment on this project.

```
Still in development.
```
