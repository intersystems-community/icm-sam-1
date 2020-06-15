#!/bin/bash
source ../env-config.sh
clear

# extract the basename of the full pwd path
DIR2MOUNT=$(basename $(pwd))

docker run --name icm-aws5 -it -v $PWD:/$DIR2MOUNT --cap-add SYS_TIME --workdir /$DIR2MOUNT $icmContainer

printf "\nExited icm-aws container\n"
printf "\nRemoving icm-aws5 container...\nContainer removed:  "
docker rm icm-aws5

