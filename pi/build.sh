#!/bin/bash

rm -f htplay201501
rm -rf ./snapshot
GOARM=6
goxc -arch=arm -os=linux -d=./
tar zxvf ./snapshot/*.gz
rm -rf ./snapshot
rm -rf debian

mv ./htplay201501_linux_arm/* .

rm -rf htplay201501_linux_arm
