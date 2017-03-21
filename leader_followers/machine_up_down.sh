#!/bin/bash
LOCKFILE=$HOME/azuremanipulate.lock

if [ -f ${LOCKFILE} ]; then
  echo "LOCKED script already running"
  exit 0
fi


if ! ln $0 $LOCKFILE; then
    echo "LOCKED script already running"
    exit 0
fi



WAITJOB=$(qstat -u '*' |tail -n +3 | awk '{print $5}' | grep qw |wc -l)
STOPPEDMACHINE=$(docker exec manabucli azure vm list TESTCREATEMANABU20  | grep exec | grep stopped |wc -l)

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
    MACHINES=$(docker exec manabucli azure vm list TESTCREATEMANABU20  | grep exec | grep stopped | head -n ${NUMBEROFWAKE} | awk '{print $3;}')
    for MACHINE in ${MACHINES}
    do
      echo "TODO check MACHINE is not empty"
      echo "TRY TO WAKE [${MACHINE}]"
      docker exec manabucli azure vm start TESTCREATEMANABU20 ${MACHINE}
    done
  else
    echo  "NO Machine available"
  fi
else
  # This block enter no job or some job running or other state
  echo  "NO JOBs wait"
  SOMEJOB=$(qstat -u '*' |tail -n +3 | wc -l)
  if [ ${SOMEJOB} -eq 0 ]; then
    STOPMACHINES=$(docker exec manabucli azure vm list TESTCREATEMANABU20 | grep running | grep exec\- | awk '{print $3;}')
    for STOPMACHINE in ${STOPMACHINES}
    do
      echo "TODO check STOPMACHINE is not empty"
      echo "TRY TO STOP [${STOPMACHINE}]"
      docker exec manabucli azure vm stop TESTCREATEMANABU20 ${STOPMACHINE}
    done
  else
    echo "There are some jobs TODO IMPLEMENT THIS"
  fi
fi

rm -f ${LOCKFILE}

