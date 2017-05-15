#!/bin/bash
CONTROLDIRECTORY=/usr/local/periodicscript
MACHINECONTROLDIRECTORY=/usr/local/periodicscript/machine
LOCKFILE=$CONTROLDIRECTORY/azuremanipulate.lock

# Do nothing 30 minutes after create leader instance
# TIMECHECKFILE=$CONTROLDIRECTORY/timecheck.txt
# if [ -e ${TIMECHECKFILE} ]; then
#   find ${TIMECHECKFILE} -mmin +30 |grep timecheck.txt > /dev/null
#   TIMECHECK=$?
#   if [ ${TIMECHECK} -ne 0 ]; then
#     # Do not anything
#     exit 0
#   fi
# fi
#
OLDMACHINELOCKFILES=$( find ${MACHINECONTROLDIRECTORY} -mmin +3 -type f )
for OLDMACHINELOCKFILE in ${OLDMACHINELOCKFILES}
do
  rm ${OLDMACHINELOCKFILE}
done


VMCONTROLCONTAINER=manabuishii/docker-azure-virtualmachine-management:0.5.0
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
    STOPMACHINES=$(docker run --rm -v $SCRIPTDIRECTORY:/work ${VMCONTROLCONTAINER} python /vmcontrol.py vmlist ${RESOURCEGROUP} | grep "Provisioning succeeded" | grep running | grep exec\- | awk '{print $1;}')
    for STOPMACHINE in ${STOPMACHINES}
    do
      echo "TODO check STOPMACHINE is not empty"
      echo "TRY TO STOP [${STOPMACHINE}]"
      # Deallocate (This is not stop or power-off.)
      if [ -e ${MACHINECONTROLDIRECTORY}/${STOPMACHINE} ];then
        docker run --rm -v $SCRIPTDIRECTORY:/work ${VMCONTROLCONTAINER} python /vmcontrol.py deallocate ${RESOURCEGROUP} ${STOPMACHINE}
        rm ${MACHINECONTROLDIRECTORY}/${STOPMACHINE} 
      else
        touch ${MACHINECONTROLDIRECTORY}/${STOPMACHINE} 
      fi
    done
  else
    STOPMACHINES=$(docker run --rm -v $SCRIPTDIRECTORY:/work ${VMCONTROLCONTAINER} python /vmcontrol.py vmlist ${RESOURCEGROUP} | grep "Provisioning succeeded" | grep running | grep exec\- | awk '{print $1;}')
    RUNNINGMACHINES=$(qstat -u '*' | tail -n +3 | awk '{ if ($5 != qw) if ($8 ~ /exec/) print $8 }' | awk -F@ '{print $2}')
    echo "${STOPMACHINES}" > /tmp/list
    echo "${RUNNINGMACHINES}" >> /tmp/list
    MACHINES=$(cat /tmp/list | sort | uniq -u)
    echo "end"
    for STOPMACHINE in ${MACHINES}
    do
      echo "TRY TO STOP [${STOPMACHINE}]"
      # Deallocate (This is not stop or power-off.)
      if [ -e ${MACHINECONTROLDIRECTORY}/${STOPMACHINE} ];then
        docker run --rm -v $SCRIPTDIRECTORY:/work ${VMCONTROLCONTAINER} python /vmcontrol.py deallocate ${RESOURCEGROUP} ${STOPMACHINE}
        rm ${MACHINECONTROLDIRECTORY}/${STOPMACHINE} 
      else
        touch ${MACHINECONTROLDIRECTORY}/${STOPMACHINE} 
      fi
    done

  fi
fi

rm -f ${LOCKFILE}
