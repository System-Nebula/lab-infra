#!/bin/sh
LINK=enp8s0
ID=secretcon
sudo ip l add link $LINK name $ID type macvtap mode bridge
IFINDEX=$(sudo cat /sys/class/net/$ID/ifindex)
sudo chown $USER /dev/tap$IFINDEX
