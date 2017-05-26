#!/bin/bash
# setupuser
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 NEWUSER MASTER_NAME" >> /tmp/azuredeploy.log.$$
  exit 1
fi
NEWUSER=$1
MASTER_NAME=$2
# Pull Docker image
docker pull myoshimura080822/galaxy_in_docker_bitwf:160607
# Galaxy Singleuser
mkdir -p /home/${NEWUSER}/work/github/
cd /home/${NEWUSER}/work/github/
git clone https://github.com/manabuishii/docker-galaxy-singleuser.git
cd docker-galaxy-singleuser
# download sample job_conf.xml
curl -s -o ./job_conf.xml.sge.docker https://raw.githubusercontent.com/manabuishii/azure-files/master/scripts_for_setup/galaxy_SGE/job_conf.sge.docker
curl -s -o ./job_conf.local.sge.docker https://raw.githubusercontent.com/manabuishii/azure-files/master/scripts_for_setup/galaxy_SGE/job_conf.local.sge.docker
cp job_conf.local.sge.docker job_conf.xml.sge
#
curl -s -o ./setup_inside_container.sh https://raw.githubusercontent.com/BioDevOps/basicsetup/499d0aafcf62f2a8db998fca35a97445cf9bd1ce/templates/setup_inside_container.sh.erb
sed -i -e "2 s/<%= @single_user %>/${NEWUSER}/g" ./setup_inside_container.sh
chmod 755 ./setup_inside_container.sh
# start script
curl -s -o ./start_bitwf.sh https://raw.githubusercontent.com/manabuishii/azure-files/master/scripts_for_setup/galaxy_SGE/start_bitwf.sh
chmod 755 ./start_bitwf.sh
# start script
curl -s -o ./stop_bitwf.sh https://raw.githubusercontent.com/BioDevOps/basicsetup/master/templates/stop_bitwf.sh.erb
chmod 755 ./stop_bitwf.sh
# /etc/init.d/docker-galaxy
apt-get install -y sysv-rc-conf
curl -s -o /etc/init.d/docker-galaxy https://raw.githubusercontent.com/BioDevOps/basicsetup/master/templates/ubuntu1404.docker-galaxy.erb
sed -e "s@/usr/local/galaxy-bitwf/scripts@/home/${NEWUSER}/work/github/docker-galaxy-singleuser ; .@" /etc/init.d/docker-galaxy
chmod 755 /etc/init.d/docker-galaxy
sysv-rc-conf docker-galaxy on
#
echo "${MASTER_NAME}" > act_qmaster
# Pull Request 2790
curl -s -o ./2790.diff https://patch-diff.githubusercontent.com/raw/galaxyproject/galaxy/pull/2790.diff
# data directory
#
# mkdir -p data/transcriptome_ref_fasta
# mkdir -p data/adapter_primer
# mkdir -p data/Homo_sapiens_genome
# mkdir -p data/Mus_musculus_genome
mkdir data
cd data
curl -s -o ./dl.sh https://raw.githubusercontent.com/manabuishii/azure-files/master/scripts_for_setup/galaxy_SGE/dl.sh
chmod 755 dl.sh
./dl.sh
cd ..
# export directory
mkdir -p export/postgresql/
chmod 777 -R export
# chown
chown ${NEWUSER}. -R /home/${NEWUSER}/work

