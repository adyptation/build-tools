#!/bin/bash

#
# Quad9 is a free recursive DNS provider that blocks malware automatically
#
QUAD9="2620:fe::fe 2620:fe::9 9.9.9.9 149.112.112.112"
OPENDNS="208.67.222.222 208.67.220.220"
CURRENT=$QUAD9

OSTYPE=$(uname -s)

macos() {
  #
  # Find our default interface by checking our default route
  #
  ActiveNetwork=$(route get default | grep interface | awk '{print $2}')
  ActiveNetworkName=$(networksetup -listallhardwareports | grep -B 1 "$ActiveNetwork" | awk '/Hardware Port/{ print }'|cut -d " " -f3-)
  echo "Active network interface: $ActiveNetwork"
  echo "Active network name: $ActiveNetworkName"

  # Set our DNS servers
  networksetup -setdnsservers $ActiveNetworkName $CURRENT

  # Print some diagnostic info to ensure things were set properly for logging.
  scutil --dns
}

if [ $OSTYPE = "Darwin" ]
then
  macos
else
  echo "Unsupported OS"
fi
