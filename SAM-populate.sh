#!/bin/bash

# Add some strictness to Bash to make it better suited for programming:
# - exit immediately on failures
# - exit immediately if an undefined variable is referenced
# - make errors visible in pipelines
set -euo pipefail

# variables declaration-------------------------
#SAMcredentials="_SYSTEM:aaa"
source ./env-config.sh
#-----------------------------------------------

deleteOldClusters()
{
# loop through all clusters
# DELETE /api/sam/admin/cluster/{id}
for clusterId in $(curl -s GET -H "Content-type: application/json" -u $SAMcredentials -out=json 'http://localhost:8080/api/sam/admin/cluster/' | jq -r '.[] | .id')
do
  printf "\nDeleting cluster id=%s;  " $clusterId
  curl -X DELETE -u $SAMcredentials -H "Content-type: application/json" "http://localhost:8080/api/sam/admin/cluster/$clusterId"
  printf "Done."
done
}

# checking the returned rtnJSON from the curl call in createClusters()
#
checkStatus()
{
# typical errors:
# [ { "error": "ERROR #26112: Cluster 'test-2' already exists.", "code": 26112, "domain": "%ObjectErrors", "id": "SAMClusterAlreadyExists", "params": [ "test-2" ] } ] ERROR #26112: Cluster 'test-2' already exists.
# rtnStatus or return_Status is set in createClusters()
# 
#printf "\n\nin checkStatus()..."
# ~ means pattern-matching
if [[ ! "$rtnJSON" =~ ^[0-9]+$ ]]
then
	#printf "\nit's NOT an integer; we must have an error \nError=%s\n" $rtnJSON
  	echo "ERROR = $rtnJSON"
  	exit
fi
}

createClusters()
{
#printf "\nIn directory for cluster %s\n" $(basename $(pwd))

if [ ! -s instances.json ]
then
	printf "\n\nIn directory [%s]; the file 'instances.json' does not exist or is empty." $clusterDir
	printf "\nThe programm cannot continue. The file 'instances.json' should exist after the ICM provisioning. Exiting.\n"
	#break;
	exit 1
else
	# create clusters, one per directory
	# we need to know which one we are talking about here and below so that we can tune the descriptions strings IOW it can't be automated further without more hassle...
	#
	# directory names:
	# AWS2-QA
	# AWS3-UAT
	# AWS4-PreProd
	# AWS5-Prod
	case $clusterDir in
		*2*)
			dirN=2
			printf "\n\nCreating SAM cluster for directory [%s]" $clusterDir

			# CURL params:
			# -s --silent = no download progressbar
			# -S --show-error
			# 
			# JQ params:
			# -r raw = no prettified JSON, no double quotes
			# -c --compact-output
			# 
			rtnJSON=$(curl -s -X POST -H 'Content-type: application/json' -u $SAMcredentials http://localhost:8080/api/sam/admin/cluster -d '{"name": "qa-us-west","description":"Quality Assurance cluster"}' | jq -r -c '.[]')
			#echo "rtnJSON="$rtnJSON
			checkStatus
			newClusterId=$rtnJSON
			printf "\nCluster created. Cluster-id=%s" $newClusterId
		;;
		*3*)
			dirN=3
			printf "\n\nCreating SAM cluster for directory [%s]" $clusterDir
			rtnJSON=$(curl -s -X POST -H 'Content-type: application/json' -u $SAMcredentials http://localhost:8080/api/sam/admin/cluster -d '{"name": "uat-us-east","description":"UAT cluster for User Acceptance Testing"}' | jq -r -c '.[]')
			#echo "rtnJSON="$rtnJSON
			checkStatus
			newClusterId=$rtnJSON
			printf "\nCluster created. Cluster-id=%s" $newClusterId
		;;
		*4*)
			dirN=4
			printf "\n\nCreating SAM cluster for directory [%s]" $clusterDir
			rtnJSON=$(curl -s -X POST -H 'Content-type: application/json' -u $SAMcredentials http://localhost:8080/api/sam/admin/cluster -d '{"name": "pre-prod-eu-cntr","description":"Pre-Production cluster"}' | jq -r -c '.[]')
			#echo "rtnJSON="$rtnJSON
			checkStatus
			newClusterId=$rtnJSON
			printf "\nCluster created. Cluster-id=%s" $newClusterId	
		;;
		*5*)
			dirN=5
			printf "\n\nCreating SAM cluster for directory [%s]" $clusterDir
			rtnJSON=$(curl -s -X POST -H 'Content-type: application/json' -u $SAMcredentials http://localhost:8080/api/sam/admin/cluster -d '{"name": "production-eu-west","description":"The PRODUCTION Cluster"}' | jq -r -c '.[]')
			#echo "rtnJSON="$rtnJSON
			checkStatus
			newClusterId=$rtnJSON
			printf "\nCluster created. Cluster-id=%s" $newClusterId
		;;
	esac
	
	numInstances=$(jq '. | length' instances.json)
	printf "\n-> [%s] instances to create: " $numInstances

	# get nodes DNS and prepare cluster description string
	# or jq -r '.[] .DNSName'
	cnt=0
	for dnsStr in $(cat instances.json | jq -r '.[] | .DNSName')
	do
		case $dirN in
			2)
				# QA
				cnt=$(expr $cnt + 1)
				instName="qa-instance-"$cnt
				createTargets
			;;
			3)
				# UAT
				cnt=$(expr $cnt + 1)
				instName="uat-instance-"$cnt
				createTargets	
			;;
			4)
				# Pre-PROD
				cnt=$(expr $cnt + 1)
				instName="pre-prod-inst-"$cnt
				createTargets
			;;
			5)
				# PRODUCTION
				cnt=$(expr $cnt + 1)
				instName="production-inst-"$cnt
				createTargets
			;;
		esac 
	done
fi
}

# POST the target within its cluster
createTargets()
{
	target=$dnsStr:52773
	printf "\nCreating SAM target=%s; %s; clusterId=%s;" $target $instName $newClusterId

	# { "name": "IRIS3", "description": "Local IRIS3", "cluster": 1, "instance": "iris:52773" }
	jsonPOSTstr="{ \"name\": \"${instName}\", \"description\": \"Instance ${instName}\", \"cluster\": ${newClusterId}, \"instance\": \"${target}\" }"
	
	rtnJSON=$(curl -s -X POST -H 'Content-type: application/json' -u $SAMcredentials http://localhost:8080/api/sam/admin/target -d "$jsonPOSTstr" | jq -r -c '.[]')
	# curl -s -X POST -H 'Content-type: application/json' -u _SYSTEM:aaa http://localhost:8080/api/sam/admin/target -d '{ "name": "test-1", "description": "Instance test-1", "cluster": 19, "instance": "bla.com:52773" }' | jq -r -c '.[]'
	checkStatus
}

# starting...
main()
{
# option to delete old clusters definitions
while true
do
    read -p "Do you want to delete all existing SAM clusters definitions? (y/n) " yn
    case $yn in
        [Yy]* ) deleteOldClusters; break
		;;
        [Nn]* ) break
		;;
        * ) echo "Please answer yes or no.";;
    esac
done

# for each AWSnn subdir define SAM clusters
for clusterDir in $(ls -d AWS*)
do
  #printf "\nDIR=%s" $clusterDir
  cd $clusterDir
  createClusters
  cd ..
done

printf "\n\n***SAM should be populated***\nAll done.\n"
}


## starting
main
#---