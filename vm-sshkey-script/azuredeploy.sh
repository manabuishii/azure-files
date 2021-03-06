#!/bin/sh

# This script can be found on https://github.com/manabuishii/azure-files/blob/master/vm-sshkey-script/azuredeploy.sh
# This script is part of azure deploy ARM template
# This script assumes the Linux distribution to be Ubuntu (or at least have apt-get support)

# Basic info
date > /tmp/azuredeploy.log.$$ 2>&1
whoami >> /tmp/azuredeploy.log.$$ 2>&1
echo $@ >> /tmp/azuredeploy.log.$$ 2>&1

echo "Hello [$1] world" > /tmp/helloworld.txt.$$ 2>&1
exit 0