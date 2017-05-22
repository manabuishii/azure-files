#!/bin/bash
docker ps -a | grep galaxy_bitwf_1.3.0
RET=$?
if [ ${RET} -eq 0 ]; then
  docker start galaxy_bitwf_1.3.0
else
  GALAXY_USER_UID=$(id -u)
  #cd /usr/local/galaxy-bitwf/scripts
  /usr/bin/docker run -d \
   --net=host \
   -v $PWD/job_conf.xml.sge:/etc/galaxy/job_conf.xml \
   -p 29002:9002 -p 28080:80 \
   -e SGE_ROOT=/var/lib/gridengine \
   -e "NONUSE=nodejs,reports,proftp,slurmctld,slurmd,condor" \
   -e GALAXY_UID=${GALAXY_USER_UID} \
   -e GALAXY_POSTGRES_UID=${GALAXY_USER_UID} \
   -e GALAXY_CONFIG_FILE_PATH=$PWD/export/galaxy-central/database/files \
   -e GALAXY_CONFIG_JOB_WORKING_DIRECTORY=$PWD/export/galaxy-central/database/job_working_directory \
   -v $PWD:$PWD \
   -v $PWD/2790.diff:/galaxy-central/2790.diff \
   -v $PWD/export:/export \
   -v $PWD/data:/data:ro \
   -v $PWD/setup_inside_container.sh:/galaxy-central/setup_inside_container.sh \
   -v $PWD/act_qmaster:/var/lib/gridengine/default/common/act_qmaster \
   --name=galaxy_bitwf_1.3.0  \
   myoshimura080822/galaxy_in_docker_bitwf:160607 /galaxy-central/setup_inside_container.sh
fi