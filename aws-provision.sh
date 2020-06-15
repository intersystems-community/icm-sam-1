#!/bin/bash
#
# This shell utility makes assumption; it expects
# - The ICM container available (tune accordingly the *icmContainer* variable)
# - AWS* subdirectories
#   - the subdirectories names describe the purpose of each cloud cluster
#   - AWS2-QA
#   - AWS3-UAT
#   - AWS4-PreProd
#   - AWS5-Prod
# - each subdir has the ICM *defaults.js* and *definitions.json* for each AWS cluster and region
# - each ICM subdirectory has 3 further needed and hardcoded subdirs for the corresponding secrets:
#   - ./ssh 
#   - ./tls
#   - ./ikey (IRIS key)
# - an ICM container will be run in each AWSn subdirectory; the directory will be mounted in the container so to find all the configurations information needed
# - valid AWS credentials must be provided in a file. See the  *aws.credentials* file. The user will be prompted to specify the file.

# Default behaviour
# - ssh keys and tls certificates will be deleted and generated with every run
# - IRIS keys can be retained (one less creation step and avoids having to be within the VPN)
# -

# variables declaration-------------------------
# see env-config.sh
source ./env-config.sh
#-----------------------------------------------

# grabbing the file with the AWS credentials
awsCredentials() {

while [ -z $awsCredFile ] ||  [ ! -s $awsCredFile ]
do
  read -p "Please provide the filename with the AWS credentials: " awsCredFile
done

printf "\nCredential provided in file: \n-- \n"
cat $awsCredFile
printf "\n--\n"

for icmDir in $(ls -d AWS*)
do
  cp -i $awsCredFile ./$icmDir/aws.credentials
done
}

# preparing ICM environment before starting the ICM container:
# deleting: tls, ssh and iris.keys
#
function cleanEnv 
{
printf "\n====> cleaning sub-directory %s \n\n" $(basename $(pwd))

# removing log files
rm -f *.log
#if [ $? -eq 0 ]
#  then
#    printf "."
#  else
#    printf "There are issues in removing log files in %s\n" $(pwd)
#    exit 1
#fi

#removing ssh kyes
rm -f ./ssh/*

#removing tls certificates
rm -f ./tls/*

# just in case the -cleanUp and -force did not work or we messed up in testing...
rm -f instances.json

# and the state directory
rm -f -r ./state/*
rmdir state

# removing IRIS keys if we had the consent
if [[ "$rmIkey" -eq 1 ]]
then
  rm -f ./ikey/*
fi

}

# implementation options
# check if we are within ISC VPN
# ping iscinternalXX.com ; echo $?
# 68
# ping -c iscinternal.com ; echo $?
# 0
# ping -c 1 111.111.111.1 ; echo $?
# 2
# --
# 0 means host reachable
# 2 means unreachable
#
function checkISCinternal
{
#printf "\npingTimeout=%s" $pingTimeout

if ping -c 1 -t $pingTimeout iscinternal.com &> /dev/null
then
  iscVPN=1
else
  iscVPN=0
fi
}

# check if user wants to keep older keys or obtain new ones; in general they are reusable
# it's worth keeping them around if there is no VPN connection available
# 
# rmKey=1 --> remove keys
# rmKey=0 --> keep them
function keepIRISkey
{
if [ "$iscVPN" -eq 1 ]
  then
    printf "\nYou appear to be on the ISC VPN. ICM can obtain new IRIS keys"
  else
    printf "\nYou are NOT on the ISC VPN. \nYou cannot obtain new IRIS keys."
    printf "\n(a) Make sure you keep those you have (say YES below) or"
    printf "\n(c) Make sure to connectect to ISC VPN to get them or"
    printf "\n(b) Make sure they are available in the ./AWSn*/ikey/ subdirectories one way or another"   
fi

# there is usually no needs to recreate IRIS key anew
printf "\nKeep existing IRIS keys? (Y/N)\n"
read -p "(YES: keep what's available / NO: retrieve new ones) " ansK
  case $ansK in
    [Nn]* ) rmIkey=1
    ;;
    * ) rmIkey=0
    ;;
  esac

}

# Starting out____________________________________________________
#
function main
{
numOfClusters=$(ls -d AWS* | wc -w)
printf "\nThis utility provisions %s AWS clusters\n\n" $numOfClusters

# provide AWS credentials
awsCredentials

# check if we are in the VPN
checkISCinternal

# check if user wants to keep older keys or obtain new ones 
keepIRISkey

# cleaning & preapring env_______________________________________
for clusterDir in $(ls -d AWS*)
do
  cd $clusterDir
  cleanEnv   
  
  # run an ICM container per directory and prepare the environment
  containerName=icm-$clusterDir

  #printf "\nrmIkey=%s\n" $rmIkey
  
  # creating req keys___________________
  docker run --rm --name $containerName \
    -v $PWD:/$clusterDir \
    --cap-add SYS_TIME \
    --workdir /$clusterDir \
    -e getIRISkey=$rmIkey \
    $icmContainer \
    /bin/sh -c 'ntpd -dp pool.ntp.org; if [[ "$getIRISkey" -eq 1 ]]; then ./keygenAll.sh; else ./keygen-ssh-tls.sh; fi;'
  
  # interactive for testing...
  #docker run --rm --name $containerName -v $PWD:/$clusterDir --cap-add SYS_TIME --workdir /$clusterDir -it $icmContainer

  cd ..
done

printf "\nEnvironment cleaned up & prepared\n"

# Serial implementation for now; slow but screen-verifiable/debuggale
# ( ( command & ) )

# Cloud provisioning_________________________________
printf "\n***Cloud infrastruture provisioning...\n\n"
for icmProvDir in $(ls -d AWS*)
do
  cd $icmProvDir
  printf "\n\n***Directory and cluster %s\n" $(basename $(pwd))
  containerName=icm-$icmProvDir

  docker run --rm --name $containerName \
    -v $PWD:/$icmProvDir \
    --cap-add SYS_TIME \
    --workdir /$icmProvDir \
    $icmContainer \
    /bin/sh -c 'ntpd -dp pool.ntp.org; icm provision'  
  cd ..
done

printf "\n\n***Cloud infrastructure provisioning done***\n\n"

# Running instances______________________
printf "\n\n***Running instances...\n\n"
for icmRunDir in $(ls -d AWS*)
do
  cd $icmRunDir
  printf "\n***Directory and cluster %s\n" $(basename $(pwd))
  containerName=icm-$icmRunDir

  docker run --rm --name $containerName \
    -v $PWD:/$icmRunDir \
    --cap-add SYS_TIME \
    --workdir /$icmRunDir \
    $icmContainer \
    /bin/sh -c 'ntpd -dp pool.ntp.org; icm run'  
  cd ..
done

printf "\n\n***IRIS clusters should be running***"
printf "\nAll done.\n"
}

# start
main
#---