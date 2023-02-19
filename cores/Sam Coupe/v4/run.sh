#!/bin/bash
cat << EOF | jtag
cable usbblaster
detect
pld load ./tld_sam_v4.bit
EOF

