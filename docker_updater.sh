#!/bin/bash

TIMESTAMP=`date "+%Y.%d.%m"`

# Syslog message for start of container updates
logger -t backup "Beginning container updates for $TIMESTAMP"

DOCKER_STOP="docker stop"
DOCKER_RM="docker rm"
DOCKER_PULL="docker pull"


#uncomment the line with $1 to be able to run the updater with a single container: "./updater.sh containername"
#CONTAINERS=`docker ps --format "$1"`
CONTAINERS=`docker ps --format "{{.Names}}"`

for container in $CONTAINERS
	do :
		CMD=`$DOCKER_STOP $container`
		# Fail Check
			if [ $? != 0 ]; then
				logger -s "DOCKER STOP ERROR: Problem prevented $container stopping. Stop command aborted.";
				logger -s $CMD;
				exit 1;
			fi;
		logger -s "Docker stopped $container successfully";
		JSON=`docker container inspect $container`

		echo $JSON > $container + ".json"

#		BINDS=`echo $JSON | jq -j '.[] | .HostConfig | .Binds[] as $b | "-v \($b) "'`

		if [ `echo $JSON | jq -j '.[] | .Hostconfig | .Binds'` == "null" ]; then
			BINDS=""
		else
			BINDS=`echo $JSON | jq -j '.[] | .HostConfig | .Binds[] as $b | "-v \($b) "'`
		fi 

		PORTS=`echo $JSON | jq ' .[] | .HostConfig | .PortBindings | keys[] as $k | "\($k):\(.[$k][] | .HostPort )" ' | while read -r line; do python -c $"print('-p ' + $line.replace('/tcp','').split(':')[1] + ':' + $line.replace('/tcp','').split(':')[0])"; done | awk '{print}' ORS=' '`
		IMAGE=`echo $JSON | jq -r '.[] | .Config | .Image'`
		#ENV=`echo $JSON | jq -j '.[] | .Config | .Env[] as $e | "-e \($e) "'`
		ENV=`echo $JSON | jq -j '.[] | .Config | .Env[] | split("=") | " --env \(.[0])=\(.[1]|@sh)"'`
	
#uncomment the below 2 lines to display only the ENV information for the container(s). this should stop the containers and display the env info. comment them back up to run.
#		echo $ENV
#		continue

		CMD=`$DOCKER_RM $container`
		# Fail Check
			if [ $? != 0 ]; then
				logger -s "DOCKER REMOVE ERROR: Problem prevented $container from being removed. Remove command aborted.";
				logger -s $CMD;
				exit 1;
			fi;
		logger -s "Docker removed $container successfully";
		
		CMD=`$DOCKER_PULL $IMAGE`
		# Fail Check
			if [ $? != 0 ]; then
				logger -s "DOCKER PULL ERROR: Problem prevented $container from being pulled from website. Pull command aborted.";
				logger -s $CMD;
				exit 1;
			fi;
		logger -s "Docker pulled new container successfully";
		
		CMD=`docker run --restart always -d --name=$container $PORTS $BINDS $ENV $IMAGE`
		# Fail Check
			if [ $? != 0 ]; then
				logger -s "DOCKER RESTART ERROR: Problem prevented $container from being restarted. Restart command aborted.";
				logger -s $CMD;
				exit 1;
			fi;
		logger -s "Docker restarted $container successfully";
	done

CMD=`docker system prune -a -f`
# Fail Check
if [ $? != 0 ]; then
	logger -s "DOCKER PRUNE ERROR: Problem prevented clean up of unused containers. Prune command aborted.";
	logger -s $CMD;
	exit 1;
fi;		
logger -s "All unused information has been removed successfully";


# Syslog message for end of container updates
logger -t backup "Completed container updates for $TIMESTAMP"
