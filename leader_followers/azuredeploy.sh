#!/bin/sh

# This script can be found on https://github.com/manabuishii/azure-files/blob/master/leader_followers/azuredeploy.sh
# This script is part of azure deploy ARM template
# This script assumes the Linux distribution to be Ubuntu (or at least have apt-get support)

create_newuser_on_nfsserver() {
  SSHDIR=/home/${NEWUSER}/.ssh

  useradd -m ${NEWUSER}
  mkdir ${SSHDIR}
  chmod 700 ${SSHDIR}
  ssh-keygen -t rsa -N ""  -f ${SSHDIR}/id_rsa
  cat ${SSHDIR}/id_rsa.pub >> ${SSHDIR}/authorized_keys
  echo "${GENERAL_USER_SSH_KEY}" >> ${SSHDIR}/authorized_keys
  chmod 600 ${SSHDIR}/authorized_keys
  echo "StrictHostKeyChecking no" >> ${SSHDIR}/config
  chmod 600 ${SSHDIR}/config
  chown -R ${NEWUSER}. /home/${NEWUSER}
}

create_newuser_on_leader_and_follower() {
  useradd ${NEWUSER}
}

create_hostlist_for_default() {
  echo "group_name @default" > /tmp/hostlist
  echo -n "hostlist" >> /tmp/hostlist

  i=0
  while [ $i -lt ${NUMBER_OF_EXEC} ]
  do
    echo -n " exec-${i}" >> /tmp/hostlist
    i=$((i+1))
  done
  echo "" >> /tmp/hostlist
}

create_etc_hosts() {
  ##
  echo $MASTER_IP $MASTER_NAME > /etc/hosts
  echo $MASTER_IP $MASTER_NAME > /tmp/hosts.$$
  echo $NFS_SERVER_IP $NFS_SERVER_NAME >> /etc/hosts
  echo $NFS_SERVER_IP $NFS_SERVER_NAME >> /tmp/hosts.$$
  i=0
  while [ $i -lt $NUM_OF_VM ]
  do
    workerip=`expr $i + $WORKER_IP_START`
    echo $WORKER_IP_BASE$workerip $WORKER_NAME$i >> /etc/hosts
    echo $WORKER_IP_BASE$workerip $WORKER_NAME$i >> /tmp/hosts.$$
    i=`expr $i + 1`
  done
}
# Create /tmp/setting.txt.$$
# deployer information
id > /tmp/setting.txt.$$ 2>&1
set >> /tmp/setting.txt.$$ 2>&1
# Basic info
date > /tmp/azuredeploy.log.$$ 2>&1
whoami >> /tmp/azuredeploy.log.$$ 2>&1
echo $@ >> /tmp/azuredeploy.log.$$ 2>&1

ROLE=$1
echo "Hello [$ROLE] world" > /tmp/helloworld.txt.$$ 2>&1
#
# Usage
if [ "${ROLE}" = "standalone" ];
then
  if [ "$#" -ne 1 ]; then
    echo "Usage: $0 standalone" >> /tmp/azuredeploy.log.$$
    exit 1
  fi
else
  if [ "$#" -ne 11 ]; then
    echo "Usage: $0 master|exec MASTER_NAME MASTER_IP WORKER_NAME WORKER_IP_BASE WORKER_IP_START NFS_SERVER_NAME NFS_SERVER_IP NEWUSER NUMBER_OF_EXEC GENERAL_USER_SSH_KEY" >> /tmp/azuredeploy.log.$$
    exit 1
  fi
  ## Create /etc/hosts
  # MASTER_NAME MASTER_IP WORKER_NAME WORKER_IP_BASE WORKER_IP_START
  MASTER_NAME=$2
  MASTER_IP=$3
  WORKER_NAME=$4
  WORKER_IP_BASE=$5
  WORKER_IP_START=$6
  NFS_SERVER_NAME=$7
  NFS_SERVER_IP=$8
  NEWUSER=$9
  NUMBER_OF_EXEC=$10
  GENERAL_USER_SSH_KEY=$11
  NUM_OF_VM=100
  # Create /etc/hosts
  create_etc_hosts
fi

# Install ChefDK
curl -L https://www.opscode.com/chef/install.sh | sudo bash -s -- -P chefdk -v 1.2.20 > /tmp/chef.txt.$$ 2>&1

# Install some files for Chef environments
sudo apt-get update
sudo apt-get install -y git curl

chef gem install knife-solo -v 0.6.0

# Install NFS common
sudo apt-get install -y nfs-common

cd /tmp
mkdir gridengine
cd gridengine/
git clone https://github.com/manabuishii/azure-files.git .
cd leader_followers/chef


echo "HOME=[$HOME]" >> /tmp/setting.txt.$$ 2>&1
echo "HOSTNAME=[$HOSTNAME]" >> /tmp/setting.txt.$$ 2>&1
echo "ROLE=[$ROLE]" >> /tmp/setting.txt.$$ 2>&1

HOME=/root berks vendor cookbooks  > /tmp/berks.txt.$$ 2>&1
echo "ROLE=[$ROLE]" > /tmp/out 2>&1
echo "version 2 test with double quote" >> /tmp/out 2>&1
test  ${ROLE} == "master"
echo $? >> /tmp/out
# Check Ubuntu Version for chef
UBUNTUVERSION=$(lsb_release -cs)
SUFFIX=""
if [ "${UBUNTUVERSION}" = "xenial" ];
then
  SUFFIX="16.04."
fi
echo ${SUFFIX} >> /tmp/out
if [ "${ROLE}" = "master" ];
then
  # Setup maseter
  echo "MASTER ${ROLE} == \"master\" " >> /tmp/out
  chef-client -j environments/master.${SUFFIX}json -z   > /tmp/chef-master.txt.$$ 2>&1
  /etc/init.d/gridengine-master stop  >> /tmp/chef-master.txt.$$ 2>&1
  /etc/init.d/gridengine-master start >> /tmp/chef-master.txt.$$ 2>&1
  # create newuser
  create_newuser_on_leader_and_follower
  # mount home
  echo "${NFS_SERVER_IP}:/datadisks/disk1/home /home nfs rw 0 2" >> /etc/fstab
  mount /home
  # hostlist
  create_hostlist_for_default
  qconf -Mhgrp /tmp/hostlist
elif [ "${ROLE}" = "exec" ];
then
  # Setup exec
  echo "EXEC ${ROLE} == \"exec\" " >> /tmp/out
  chef-client -j environments/exec.${SUFFIX}json -z  > /tmp/chef-client.txt.$$ 2>&1
  /etc/init.d/gridengine-exec stop  >> /tmp/chef-client.txt.$$ 2>&1
  /etc/init.d/gridengine-exec start >> /tmp/chef-client.txt.$$ 2>&1
  # create newuser
  create_newuser_on_leader_and_follower
  # mount home
  echo "${NFS_SERVER_IP}:/datadisks/disk1/home /home nfs rw 0 2" >> /etc/fstab
  mount /home
elif [ "${ROLE}" = "standalone" ];
then
  # Setup standalone
  chef-client -j environments/standalone.json -z  > /tmp/chef-client.txt.$$ 2>&1
  echo "EXEC ${ROLE} == \"standalone\" " >> /tmp/out
elif  [ "${ROLE}" = "nfsserver" ];
then
  echo "EXEC ${ROLE} == \"nfsserver\" " >> /tmp/out
  # Setup RAID disk
  curl  -o /tmp/vm-disk-utils-0.1.sh https://raw.githubusercontent.com/manabuishii/azure-quickstart-templates/ubuntuscript1/shared_scripts/ubuntu/vm-disk-utils-0.1.sh
  chmod 755 /tmp/vm-disk-utils-0.1.sh
  bash /tmp/vm-disk-utils-0.1.sh -s -o defaults
  # 

　# do chef for NFS
  berks vendor cookbooks
  chef-client -j environments/nfsserver.${SUFFIX}json -z  > /tmp/chef-client.txt.$$ 2>&1
  # create newuser
  create_newuser_on_nfsserver > /tmp/create_newuser_on_nfsserver.txt.$$ 2>&1
  mv /home /datadisks/disk1
  ln -s /datadisks/disk1/home /home
else
  echo "EXEC ${ROLE} == \"other\" " >> /tmp/out
fi

exit 0
