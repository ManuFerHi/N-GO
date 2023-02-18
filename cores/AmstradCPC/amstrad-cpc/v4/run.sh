#!/bin/bash
file=./tld_cpc.bit
if [ "$1" != "" ]; then file=$1; fi
cat << EOF | jtag
cable usbblaster
detect
pld load ${file}
EOF

