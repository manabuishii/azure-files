#!/bin/bash
CONTROLDIRECTORY=/usr/local/periodicscript
LOCKFILE=$CONTROLDIRECTORY/azuremanipulate.lock

# Do nothing 30 minutes after create leader instance 
find $CONTROLDIRECTORY/timecheck.txt -mmin +30 |grep timecheck.txt > /dev/null
TIMECHECK=$?
if [ ${TIMECHECK} -ne 0 ]; then
  # Do not anything
  exit 0
fi

VMCONTROLCONTAINER=manabuishii/docker-azure-virtualmachine-management:0.4.0
RESOURCEGROUP=$(cat $CONTROLDIRECTORY/RESOURCEGROUP.txt)
SCRIPTDIRECTORY=$CONTROLDIRECTORY

if [ -f ${LOCKFILE} ]; then
  echo "LOCKED script already running"
  exit 0
fi


if ! ln $0 $LOCKFILE; then
    echo "LOCKED script already running"
    exit 0
fi



WAITJOB=$(qstat -u '*' |tail -n +3 | awk '{print $5}' | grep qw |wc -l)
STOPPEDMACHINE=$(docker run --rm -v $SCRIPTDIRECTORY:/work ${VMCONTROLCONTAINER} python /vmcontrol.py vmlist ${RESOURCEGROUP}  | grep exec | grep -E 'stopped|deallocated' |wc -l)

echo "WAIT=${WAITJOB}"
echo "STOPPED=${STOPPEDMACHINE}"
test ${WAITJOB} -gt ${STOPPEDMACHINE}

if [ ${WAITJOB} -gt 0 ];
then
  echo  "SOME JOBs wait"
  if [ ${STOPPEDMACHINE} -gt 0 ];
  then
    echo "SOME MACHINEs are stopped and ready to EXECUTE"
    NUMBEROFWAKE=0
    if [ ${WAITJOB} -gt ${STOPPEDMACHINE} ];
    then
      echo "ALL MACHINEs are needed"
      NUMBEROFWAKE=${STOPPEDMACHINE}
    else
      echo "SOME MACHINEs are needed"
      NUMBEROFWAKE=${WAITJOB}
    fi
    #
    echo "TRY TO WAKE [${NUMBEROFWAKE}]"
    MACHINES=$(docker run --rm -v $SCRIPTDIRECTORY:/work ${VMCONTROLCONTAINER} python /vmcontrol.py vmlist ${RESOURCEGROUP}  | grep exec | grep -E 'stopped|deallocated' | head -n ${NUMBEROFWAKE} | awk '{print $1;}')
    for MACHINE in ${MACHINES}
    do
      echo "TODO check MACHINE is not empty"
      echo "TRY TO WAKE [${MACHINE}]"
      docker run --rm -v $SCRIPTDIRECTORY:/work ${VMCONTROLCONTAINER} python /vmcontrol.py start ${RESOURCEGROUP} ${MACHINE}
    done
  else
    echo  "NO Machine available"
  fi
else
  # This block enter no job or some job running or other state
  echo  "NO JOBs wait"
  SOMEJOB=$(qstat -u '*' |tail -n +3 | wc -l)
  if [ ${SOMEJOB} -eq 0 ]; then
    STOPMACHINES=$(docker run --rm -v $SCRIPTDIRECTORY:/work ${VMCONTROLCONTAINER} python /vmcontrol.py vmlist ${RESOURCEGROUP} | grep running | grep exec\- | awk '{print $1;}')
    for STOPMACHINE in ${STOPMACHINES}
    do
      echo "TODO check STOPMACHINE is not empty"
      echo "TRY TO STOP [${STOPMACHINE}]"
      # Deallocate (This is not stop or power-off.)
      docker run --rm -v $SCRIPTDIRECTORY:/work ${VMCONTROLCONTAINER} python /vmcontrol.py deallocate ${RESOURCEGROUP} ${STOPMACHINE}
    done
  else
    echo "There are some jobs TODO IMPLEMENT THIS"
  fi
fi

rm -f ${LOCKFILE}
