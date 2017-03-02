#!/bin/sh

# This script can be found on https://github.com/manabuishii/azure-files/blob/master/leader_followers/azuredeploy.sh
# This script is part of azure deploy ARM template
# This script assumes the Linux distribution to be Ubuntu (or at least have apt-get support)

# Basic info
date > /tmp/azuredeploy.log.$$ 2>&1
whoami >> /tmp/azuredeploy.log.$$ 2>&1
echo $@ >> /tmp/azuredeploy.log.$$ 2>&1

ROLE=$1
echo "Hello [$ROLE] world" > /tmp/helloworld.txt.$$ 2>&1
curl -L https://www.opscode.com/chef/install.sh | sudo bash -s -- -P chefdk -v 1.2.20 > /tmp/chef.txt.$$ 2>&1

sudo apt-get update
sudo apt-get install -y git

chef gem install knife-solo -v 0.6.0


cd /tmp
mkdir gridengine
cd gridengine/
git clone https://github.com/manabuishii/azure-files.git .
cd leader_followers/chef

id > /tmp/setting.txt.$$ 2>&1
set >> /tmp/setting.txt.$$ 2>&1
echo "HOME=[$HOME]" >> /tmp/setting.txt.$$ 2>&1
echo "HOSTNAME=[$HOSTNAME]" >> /tmp/setting.txt.$$ 2>&1
echo "ROLE=[$ROLE]" >> /tmp/setting.txt.$$ 2>&1

HOME=/root berks vendor cookbooks  > /tmp/berks.txt.$$ 2>&1
echo "ROLE=[$ROLE]" > /tmp/out 2>&1
echo "version 2 test with double quote" >> /tmp/out 2>&1
test  ${ROLE} == "master"
echo $? >> /tmp/out
if [ "${ROLE}" = "master" ];
then
  echo "MASTER ${ROLE} == \"master\" " >> /tmp/out
  chef-client -j environments/master.json -z   > /tmp/chef-master.txt.$$ 2>&1
  /etc/init.d/gridengine-master stop  >> /tmp/chef-master.txt.$$ 2>&1
  /etc/init.d/gridengine-master start >> /tmp/chef-master.txt.$$ 2>&1
  ## Create /etc/hosts
  # MASTER_NAME MASTER_IP WORKER_NAME WORKER_IP_BASE WORKER_IP_START
  MASTER_NAME=$2
  MASTER_IP=$3
  WORKER_NAME=$4
  WORKER_IP_BASE=$5
  WORKER_IP_START=$6
  NUM_OF_VM=100
  ##
  echo $MASTER_IP $MASTER_NAME > /tmp/hosts.$$
  i=0
  while [ $i -lt $NUM_OF_VM ]
  do
    workerip=`expr $i + $WORKER_IP_START`
    echo $WORKER_IP_BASE$workerip $WORKER_NAME$i >> /tmp/hosts.$$
    i=`expr $i + 1`
  done
elif [ "${ROLE}" = "exec" ];
then
  echo "EXEC ${ROLE} == \"exec\" " >> /tmp/out
  chef-client -j environments/exec.json -z  > /tmp/chef-client.txt.$$ 2>&1
  /etc/init.d/gridengine-exec stop  >> /tmp/chef-client.txt.$$ 2>&1
  /etc/init.d/gridengine-exec start >> /tmp/chef-client.txt.$$ 2>&1
elif [ "${ROLE}" = "standalone" ];
then
  chef-client -j environments/standalone.json -z  > /tmp/chef-client.txt.$$ 2>&1
  echo "EXEC ${ROLE} == \"standalone\" " >> /tmp/out
else
  echo "EXEC ${ROLE} == \"other\" " >> /tmp/out
fi

exit 0