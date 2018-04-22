#!/usr/bin/env bash

cd /tmp
teamspeak_version="teamspeak3-server_linux_amd64-3.1.1.tar.bz2"
wget "http://dl.4players.de/ts/releases/3.1.1/${teamspeak_version}"
tar -xf ${teamspeak_version} -C /data
if [ $? -ne 0 ]; then exit 1; fi
rm ${teamspeak_version}
cd ~
./ts3server createinifile=1
touch query_ip_blacklist.txt query_ip_whitelist.txt
touch .ts3server_license_accepted
