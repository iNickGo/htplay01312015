#!/bin/bash

rm -f htplay201501
rm -rf ./snapshot
GOARM=6
goxc -arch=arm -os=linux -d=./ -goroot=$GOROOT -tasks-=go-test,go-install
tar zxvf ./snapshot/*.gz
rm -rf ./snapshot
rm -rf debian

mv ./pi_linux_arm/* .

rm -rf pi_linux_arm
