#!/bin/bash
rm -rf release
mkdir release
cp tld_sam_v4.bit release
cp ../README.txt release

zip ./release/firmware.zip ../../ctrl-module/CtrlModule/CtrlModule/CharROM/CharROM_ROM.vhd ../firmware/CtrlROM_ROM.vhd

wine ~/fpga-zxuno/generator/Bit2Bin.exe tld_sam_v4.bit ./release/COREn.ZX1

cd release
zip ../release.zip tld_sam_v4.bit COREn.ZX1 README.txt ./firmware.zip
cd ..

