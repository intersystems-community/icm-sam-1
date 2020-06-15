#!/bin/bash
#
# unprovision AWS clusters provisioned by aws-provision.sh

# variables declaration-------------------
source ./env-config.sh
#-----------------------------------------

unprovision()
{
for icmWorkDir in $(ls -d AWS*)
do
  cd $icmWorkDir
  printf "\n***Directory and cluster %s\n" $(basename $(pwd))
  containerName=icm-$icmWorkDir

  docker run --rm --name $containerName \
    -v $PWD:/$icmWorkDir \
    --cap-add SYS_TIME \
    --workdir /$icmWorkDir \
    $icmContainer \
    /bin/sh -c 'icm unprovision --stateDir state -cleanUp -force'  
  cd ..
done
}


# verify the intention
main()
{
while true
do
  read -p "Do you wish to unprovision all clusters (y/n) " yn
  case $yn in
    [Yy]* ) unprovision; break;;
    [Nn]* ) printf "OK, exiting\n"; break;;
    * ) printf "Please answer yes or no.\n";;
  esac
done
}

# starting 
main
#---


