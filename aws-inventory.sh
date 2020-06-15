#!/bin/bash

# variables declaration-------------------
#icmContainer=intersystems/icm:2020.3.0XDBC.132.0
#icmContainer=intersystems/icm:2020.3.0-dev
#2020.3.0-dev
source ./env-config.sh
#-----------------------------------------

main()
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
    /bin/sh -c 'icm inventory; icm ps -container iris'  
  cd ..
done
}


# starting 
main
#---