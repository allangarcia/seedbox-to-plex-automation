## CURRENTLY IN CHANGE ##

# seedbox-to-plex-automation
Collection of bash scripts to automate my Plex + Deluge + CouchPotato + SickRage (NO FILEBOT VERSION)

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

- I'm using a RASPBIAN STRETCH LITE version (https://www.raspberrypi.org/downloads/raspbian/)
- Flash your SDCARD with Etcher (https://www.raspberrypi.org/documentation/installation/installing-images/README.md)
- Mount your just flashed SDCARD and add an empty "ssh" file to "boot" mount point

```
$ cd /Volumes/boot
$ touch ssh
```

- Put your SDCARD to your Raspberry hardware and turn it on
- Using your terminal ssh to your raspberry ip address
- Default user "pi", default password "raspberry"
- Configure

```
$ sudo raspi-config
```

- Things to consider to configure

  - Change default passwords
  - Change hostname
  - Enable Wifi (if applicable)
  - Expand your filesystem if not already
  - Enable SSH in "Interfacing Options" (if not already enabled)
  - Adjust your locale settings
  - Update
  - Maybe you want to create your own user after reboot

## Beginning the installation

- After configuration did a full update as always

```
# apt update
# apt upgrade
# apt dist-upgrade
```

- Added a PMS repository and installed with those commands

```
# wget -O - https://dev2day.de/pms/dev2day-pms.gpg.key | apt-key add -
# echo "deb https://dev2day.de/pms/ stretch main" | tee /etc/apt/sources.list.d/pms.list
# apt update
# apt install plexmediaserver-installer
```

- Then I installed my seedbox packages

```
# apt install deluged deluge-console deluge-web
# sed -i "s/ENABLE_DELUGED=0/ENABLE_DELUGED=1/" /etc/default/deluged
# service deluged restart
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
# apt install git vim htop mediainfo youtube-dl
```

## Download the raw stuff

- I install all my non distro things on /opt

```
# cd /opt
```

- Sickrage! Manager for your TV Series contents

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

- Couchpotato! Manager for your Movies contents

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

## Mount your external media

- Install support for exfat

```
# apt install exfat-fuse exfat-utils
```

- Make your mountpoint

```
# mkdir -p /mnt/STORAGE
```

- Plug your device, wipe the partition table, make a new partition and filesystem

**PS: DON'T DO THIS IF YOU ALREADY HAVE MEDIA FILES, DON'T BE STUPID!!!**

```
# fdisk /dev/sda
# mkfs.exfat -n STORAGE /dev/sda1
```

- Get the UUID of your new partition, and write down (CTRL+C!) the UUID= part

```
# blkid /dev/sda1
/dev/sda1: LABEL="STORAGE" UUID="D7AE-8A04" TYPE="exfat" PTTYPE="dos" PARTUUID="eb42e7ee-d18a-4652-90eb-6e61673b1323"
```

- Make your entry on /etc/fstab

```
Append to /etc/fstab

UUID=D7AE-8A04		/mnt/STORAGE	exfat	defaults		0	2
```

- Make directories to hold your downloads

```
# cd /mnt/STORAGE
# mkdir Torrents
# cd Torrents
# mkdir Completed Downloading
```

- Make directories to hold your media

```
# cd /mnt/STORAGE
# mkdir Movies
# mkdir TV\ Shows
```

## Configuration

- Configure plex to index your media on previouly created media directories

This article may be helpful: https://support.plex.tv/hc/en-us/articles/200264746-Quick-Start-Step-by-Step-Guides

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
